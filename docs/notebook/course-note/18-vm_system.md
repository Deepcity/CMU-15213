# 18. 内存系统深入：TLB + 多级页表 + 现代 CPU 案例分析 + Linux VM 管理

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

-----

这节讲的是 **虚拟内存（Virtual Memory）总体概念**，可以按“是什么—能做什么—怎么实现”来理解。

## 一、简单内存系统：TLB + 页表 + Cache 一条链路

1. **地址拆分和符号复习**

   * 虚拟空间大小：$N = 2^n$，物理空间：$M = 2^m$，页大小：$P = 2^p$。
   * 虚拟地址 VA 拆成：

     * VPN（virtual page number）
     * VPO（virtual page offset）
     * 再细分出：TLBI（TLB index），TLBT（TLB tag）
   * 物理地址 PA 拆成：

     * PPN（physical page number）
     * PPO（physical page offset，与 VPO 相同）
     * 再细分出：CI（cache index）、CO（cache byte offset）、CT（cache tag）。

2. **玩具系统参数**（14-bit VA / 12-bit PA / 页大小 64B）

   * 一个小 TLB：16 entries，4 路组相联；
   * 一个页表：VPN→(PPN, Valid) 的数组；
   * 一个物理地址的 L1 cache：16 行，块大小 4B，直接映射。

3. **从 VA 到 Cache Byte 的完整流程**（几张“Address Translation Example”就是练习题）：

   * 从 VA 提取 VPN / VPO，再从 VPN 提取 TLBI/TLBT；
   * 查 TLB：命中则拿到 PPN；未命中再查页表：

     * 页表有效→拿到 PPN，并可填回 TLB；
     * 页表无效→触发 page fault（这在前一份 PPT 已讲过）。
   * 用 PPN+PPO 得到 PA，再从中取出 CI/CO/CT 查 cache，得到最终字节。

> 这一块的核心：**让你真正能手算一个地址从 VA → TLB → Page Table → Cache 的全过程**，为后面更大规模的系统打基础。

---

## 二、Core i7 + Linux 内存系统 Case Study

### 1. Core i7 的 cache/TLB 层次结构

PPT 第 12 页给了一个比较完整的结构图：

* 每个核心：

  * L1 i-cache / d-cache：各 32KB，8-way；
  * L2 unified cache：256KB，8-way；
  * 三个级别的 TLB：

    * L1 d-TLB：64 entries，4-way；
    * L1 i-TLB：128 entries，4-way；
    * L2 unified TLB：512 entries，4-way。
* 所有核心共享：

  * L3 unified cache：8MB，16-way；
  * DDR3 控制器，约 32GB/s 带宽。

这说明真正的访存路径是：
**寄存器 ↔ L1 (i/d) ↔ L2 ↔ L3 ↔ 主存**，同时由 **TLB 层次** 做地址翻译。

### 2. x86-64 的 4 级页表

后面几页专门讲 Core i7 页表格式和四级翻译流程：

* 虚拟地址拆成：VPN1, VPN2, VPN3, VPN4, VPO（每级 9 bit，页大小 4KB）。

* CR3 寄存器保存顶级页表（L4 page table）的物理地址。

* 翻译路径：

  1. 用 VPN1 在 L4 页表中找 L4 PTE；
  2. 取出下一层页表物理地址，再用 VPN2 找 L3 PTE；
  3. 如此类推直到 L1 PTE 得到最终 PPN；
  4. 接上 VPO 得到 52-bit 物理地址（这里画图中为 40+12）。

* Level 1–3 PTE 主要字段：P（present）、R/W、U/S、A（accessed）、PS（大页标志）、缓存策略 WT/CD、XD（execute disable）等；

* Level 4（叶子）PTE 还多了 D（dirty）位，用于写回和换出策略。

这些位共同提供了**权限控制 + 引用/修改统计 + cache 策略**。

### 3. “可爱技巧”：L1 Cache 的虚拟索引、物理标记

Core i7 的 L1 d-cache 采用“**virtually indexed, physically tagged**” 技巧：

* 观察：VA 和 PA 的某些底层 bit（做 CI 的那几位）是一样的，因为它们都在页内偏移部分。
* 做法：

  * 在 TLB 翻译的同时，用 VA 中的 CI 位直接去索引 L1 cache；
  * 等 TLB 翻译出 PPN 后，再用完整的 PA 里 CT 做 tag 比较。
* 这样可以 **并行** 地址翻译和 cache index，大幅降低 L1 命中时的访存延迟，但是要求：

  * cache 大小、组数等参数设计得“刚好好”（否则 CI 会溢出到页号部分）。

### 4. Linux 进程虚拟地址空间 & 内核数据结构

1. **地址空间布局图**（第 19 页）：

   * 用户态从低到高大致是：

     * 程序 text (.text)
     * 初始化数据 (.data)
     * 未初始化数据 (.bss)
     * 运行时堆（malloc，对应 `brk` 向上长）
     * 共享库 mmap 区（向上长）
     * 用户栈（从高往低长）
   * 顶部是内核的虚拟地址空间，对所有进程相同。

2. **vm_area_struct：Linux 用“区域”来组织 VM**（第 20 页）：

   * 每个进程一个 `task_struct`，其中有指针指向 `mm_struct`。
   * `mm_struct` 中：

     * `pgd`：顶级页表（page global directory）的物理地址；
     * `mmap`：指向一条链表，每个节点是一个 `vm_area_struct`。
   * `vm_area_struct` 描述一个连续虚拟区间：

     * `vm_start` / `vm_end`：地址范围；
     * `vm_prot`：读写执行权限；
     * `vm_flags`：是否 shared / private，是否 COW 等；
     * `vm_next`：指向下一个区域。
   * 所以 Linux 内核其实不直接“存整张虚拟空间”，而是存一堆 area 区间，再配上页表实现细粒度映射。

3. **Linux Page Fault 处理**（第 21 页）：

   * 发生 page fault 时，内核根据 fault 地址去遍历 `vm_area_struct`：

     * 若找不到任何覆盖该地址的 area → 这是访问“根本不存在的虚拟区域”，报 **Segmentation fault**；
     * 若找到了 area，但访问方式不符合 `vm_prot`（比如写只读页）→ **protection exception**，Linux 同样报 segfault；
     * 若找到且权限匹配 → “正常 page fault”，分配物理页或从文件/交换分区读入，再修正 PTE。

---

## 三、Memory Mapping：文件、共享库、COW、fork/execve 和 mmap

### 1. VM area 和磁盘对象的绑定（memory mapping）

* 每个 VM area 的内容来自某个“后端对象”：

  * **普通文件**：比如可执行文件、共享库，对应 file-backed 区域；
  * **匿名对象**：没有真实文件的区域（stack, .bss, heap 等），第一次访问时分配全 0 页（demand-zero page）。
* 脏页在内存和 swap file 之间来回换，这就是传统的交换空间（swap）。

### 2. 共享对象（Shared Objects）

* 两个进程都 `mmap` 同一个共享库或共享文件区域，可以让它们的虚拟页都指向同一个物理页：

  * 虚拟地址可以不同；
  * 只读区域（如 .text）常用这种方式在多进程间共享，节省内存。

### 3. 私有写时复制（Copy-on-Write, COW）

* Private + COW 的区域（如 fork 后的地址空间）初始也是共享同一个物理页，但 PTE 标记为只读；
* 当进程试图写该页时：

  1. 触发 protection fault；
  2. 内核分配一个新的可写物理页，把原内容复制过去；
  3. 更新当前进程的 PTE 指向新页，恢复执行。
* 这样就能 **延迟真正复制**，直到某个进程真的写这块内存。

### 4. fork 再访：为什么 fork 很“便宜”

* `fork()` 时，内核不会立刻复制整片物理内存，而是：

  * 只复制 mm_struct、vm_area_struct、页表 *结构*；
  * 把所有相关的 vm_area 标记为 private COW；
  * 把对应 PTE 都改成只读。
* 父子进程起始时共享同一物理页，直到某一方写入，才通过 COW 分裂出自己的页。

这就解释了：**为什么可以在 Linux 中频繁 fork 而不会真的把所有物理内存复制一遍。**

### 5. execve 再访：加载一个新程序

* `execve("a.out", ...)` 时，内核对当前进程做：

  * 释放旧的 vm_area_struct 和页表；
  * 为新程序创建一套 vm_area：

    * `.text`、`.data` 这些 file-backed 区，从 a.out 文件中按需加载；
    * `.bss` 和 stack 等是匿名 demand-zero 区域。
  * 把 PC 设置为新程序入口（`_start`），后面缺页时再慢慢 fault in 代码和数据。

### 6. 用户态的 mmap 接口

最后三页讲的是 C 语言中的 `mmap`：

```c
void *mmap(void *start, int len,
           int prot, int flags,
           int fd, int offset);
```

* 作用：把文件 `fd` 中从 `offset` 开始的 `len` 字节映射到当前进程的虚拟地址空间；
* `start` 可以为 0，表示让内核自己挑地址；
* `prot` 指定权限（PROT_READ/WRITE/EXEC），`flags` 指定是 MAP_PRIVATE（私有 COW）还是 MAP_SHARED（共享）。

示例代码 `mmapcopy.c`：用 `mmap` 把整个输入文件映射到内存，然后直接 `write(1, bufp, size)` 输出到 stdout ——
好处是**在内核态实现“文件 → 页缓存 → 用户进程地址空间”的零拷贝路径**，而不是在用户态手动 `read` 到 buffer 再 `write`。

## REF

1.[18-vm-systems.pdf](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/18-vm-systems.pdf) 
