# System-Level I/O

***MOSTLY LEARNED***

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

## Content

- **Unix I/O 基本模型**

  一切皆文件：普通文件、目录、设备、终端等都抽象成“字节序列的文件”；通过统一的系统调用 `open/read/write/lseek/close` 访问。文件有“当前文件位置（偏移）”，读写会推进偏移。注意**短计数（short count）**并不一定是错误，尤其是交互式终端或网络场景要做好循环读写处理。 

- **RIO（Robust I/O）健壮 I/O 包**

  CMU 配套的 RIO 封装了解决短计数与缓冲问题：

  - **无缓冲**：`rio_readn` / `rio_writen`，接口与 `read/write` 一致；`rio_readn` 仅在 EOF 才返回短计数，`rio_writen` 不会短写；适合**已知长度的二进制传输**（比如套接字）。 
  - **有缓冲输入**：`rio_readlineb`（读一行，遇到换行/EOF/达到上限即止）、`rio_readnb`（读最多 n 字节）；两者可在同一描述符上交错使用，但**不要与 `rio_readn` 混用**。 

- **标准 I/O（stdio）与缓冲**

  C 标准库把“打开的文件”抽象为 **流（`FILE\*`）**，提供 `fopen/fread/fwrite/fgets/fprintf/fflush/fclose` 等，**通过用户态缓冲**减少系统调用开销；遇到换行、`fflush`、`exit/return main` 等时刷新缓冲。适合磁盘/终端文件，但**不推荐用于套接字**，且**不是异步信号安全**。  

- **何时选哪套 API？（决策表）**

  - **标准 I/O**：处理磁盘或终端文件的**文本/格式化 I/O**，想要省心就用它。
  - **原生 Unix I/O**：在**信号处理器**里（因为 async-signal-safe），或极致性能/零拷贝等需求。
  - **RIO**：**网络套接字**的行输入或定长二进制读写，更健壮。
     总结图也强调了这三者关系：标准 I/O 与 RIO 都是构建在底层 Unix I/O 之上。

- **元数据、共享与重定向**

  - **文件元数据**：用 `stat/fstat` 读取（类型、权限、大小、时间戳等）。
  - **打开文件的内核表示**：每进程“描述符表”引用“打开文件表”条目（含文件位置等），再指向“vnode/inode”信息（类型、大小等）。这解释了为何多个 fd 可共享同一偏移。
  - **进程间共享**：`fork` 后子进程继承父进程的打开文件（引用计数+1），因此**父子会共享文件偏移**。
  - **I/O 重定向**：shell 通过 `dup2(oldfd,newfd)` 把 `stdout` 等重定向到新文件/管道。 

-  **二进制文件处理的禁忌**

  不要用面向文本的函数（如 `fgets/scanf/rio_readlineb`）或字符串处理（`strlen/strcpy`）去读写原始二进制数据；二进制请用 `read`/`rio_readn`/`rio_readnb`/`fread` 等。

## 写代码要落地的实践清单

1. **循环读写**处理短计数（特别是网络）：优先 `rio_readn/rio_writen`；行文本用 `rio_readlineb`。 
2. **别混用** `rio_readn` 与缓冲 RIO，在同一描述符上会干扰缓冲状态。
3. **stdio 刷新规则**要清楚：换行、`fflush`、程序退出时写出；`strace` 能直接看到最终只发生一次 `write(1,"hello\n",6)`。
4. **进程继承 fd**：`fork` 后别忘了父子共享偏移；需要分离请 `dup` 新 fd 或在各自进程 `lseek`。
5. **重定向**：在 `exec` 之前 `open` 目标文件并 `dup2(目标fd, STDOUT_FILENO)`。

## 一张速记卡（Cheat Sheet）

- **系统调用**：`open/read/write/lseek/close/stat`（最通用、最低开销）。
- **标准 I/O**：`fopen/fread/fgets/fprintf/fflush/fclose`（带缓冲，适合磁盘/终端）。
- **RIO**：`rio_readn/rio_writen/rio_readlineb/rio_readnb/rio_readinitb`（健壮网络 I/O）。 
- **重定向**：`dup2(oldfd,newfd)`；**共享偏移**：进程/描述符表→打开文件表→vnode。 

## demo

如果看不懂，在本仓库[CMU-15213/src at main · Deepcity/CMU-15213](https://github.com/Deepcity/CMU-15213/tree/main/src)中有一个io_demo，由chatgpt编写，可以看看

## REF

1. [ChatGPT - CMU15213](https://chatgpt.com/g/g-p-68e7b4b594a48191a3896754ae062e4f-cmu15213/c/6912c5ac-3cdc-8320-9785-d7ccd5dc9698) 