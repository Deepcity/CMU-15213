# ecf_signals

Small, self-contained demos that accompany the CMU 15-213 Exceptional Control Flow (ECF) lectures. They focus on writing correct signal handlers and on using `setjmp` / `longjmp` for non-local control transfer.

## Project layout

- `signals_demo.c`: demonstrates a SIGCHLD handler that reaps all exited children safely using `sigaction`, `sigprocmask`, and `sigsuspend`.
- `set_jmp/setjmp_demo.c`: shows how `setjmp` seeds a recovery point and how `longjmp` unwinds the stack with an error code.
- `Makefile`: builds both demos (`signals_demo` and `setjmp_demo`) and provides a `clean` target.

## Building

Requirements: POSIX-like environment with `gcc` (or any C11 compiler) and `make`.

```bash
make            # builds signals_demo and setjmp_demo
make clean      # removes binaries

make signals_demo   # only build the signal handler demo
make setjmp_demo    # only build the setjmp/longjmp demo
```

## Running the demos

### Reliable SIGCHLD handling (`signals_demo`)

This program forks a short-lived child, blocks `SIGCHLD` while touching a fake “job table”, and then waits for the handler to reap the child. The handler:

1. Loops with `waitpid(-1, …, WNOHANG)` to avoid zombie processes.
2. Uses `write(2, …)` via `safe_write` so that only async-signal-safe functions run inside the handler.
3. Sets a `sig_atomic_t` flag that the main loop polls after `sigsuspend` unblocks `SIGCHLD`.

Example run:

```text
$ ./signals_demo
[parent] critical section: tracking child 939835
[handler] SIGCHLD received, reaped a child.
[parent] child reaped inside handler, exiting cleanly.
```

Try editing the code to remove the signal blocking to see how race conditions surface (missed signals or zombies).

### Non-local jumps (`setjmp_demo`)

`setjmp_demo` accepts an optional integer argument:

- `0` (default): the deep call chain returns normally.
- Non-zero: `deep_layer3` triggers `longjmp(env, 100)` to simulate an exception bubbling back to `main`.

Example runs:

```text
$ ./setjmp_demo          # same as ./setjmp_demo 0
[main] setjmp returns 0 (first time), run deep call chain...
[main] deep call chain finished normally.

$ ./setjmp_demo 1
[main] setjmp returns 0 (first time), run deep call chain...
[main] recovered from error via longjmp, code=100
```

Use these as starting points for experiments: change the child workflow, replace `sigsuspend` with `pselect`, or extend the setjmp demo to carry richer error payloads.

## Partial Explain

### signals.c

### 顶部宏与类型

### `#define _POSIX_C_SOURCE 200809L`

- **作用**：打开/解锁一组 POSIX 标准接口的声明（“特性测试宏”），确保头文件里暴露出 `sigaction/sigprocmask/sigsuspend` 等原型，避免非标准/历史接口（如旧版 `signal()`）被误用。
- **为什么要这样**：

  - 让编译期有更严格的原型检查与可移植性；
  - 鼓励使用 `sigaction` 等“新式”接口，而非不推荐的旧接口。

### `volatile sig_atomic_t chld_flag`

- **类型**：`sig_atomic_t` 是实现保证**可原子读写**的整数类型；`volatile` 防止编译器把它缓存到寄存器、导致在信号处理器与主线程之间**不可见**。

> 主要指可见性（visibility）问题：处理器里对某个变量做了写入，但主线程看不到最新值（读到的是旧值）。这通常不是“CPU没写进去”，而是编译器优化 + 寄存器缓存导致主线程不去重新读内存。
>
> - **信号处理器是异步打断**：它会在主线程的任意指令之间插进来执行（同一个线程的上下文被中断）。
>
> - **编译器为了提速会优化**：如果它“认为”某变量不会被其他地方改，它可能把这个变量装进**寄存器**，或把对它的多次读取**合并**成一次，从而**不再每次从内存取值**。
>
> - **结果**：handler 改了内存里的变量，但主线程一直用寄存器里的旧拷贝——于是就“不可见”。

- **用途**：在 `SIGCHLD` 处理器里只**设置标志位**，主循环里**轮询并处理**。这是“安全 handler”的常见写法（尽量短小、无复杂逻辑）。

---

### 核心结构体与常量

#### `struct sigaction`

```c
struct sigaction {
    void     (*sa_handler)(int);  // 或者使用 sa_sigaction
    sigset_t  sa_mask;            // 运行 handler 期间内核帮你“顺便阻塞”的信号集合
    int       sa_flags;           // 行为标志，如 SA_RESTART
    // ...
};
```

- **`sa_handler`**：你要安装的处理函数指针，签名固定为 `void handler(int sig)`。
- **`sa_mask`**：进入该 handler 时，内核会把这里列出的信号**临时阻塞**（除了当前信号还会**隐式阻塞**），防止重入。
- **`sa_flags`**：行为开关。示例里用了 `SA_RESTART`，让部分可重启的“慢系统调用”在被信号中断后自动重启，减少 `EINTR` 错误处理压力。

#### `SA_RESTART`

- **含义**：被信号打断的系统调用（如 `read`/`write`/`wait` 等）会尽量自动重启，而不是返回 `-1, errno=EINTR`。
- **为什么要用**：让程序对信号更鲁棒，不用在很多调用点手写 `if (errno==EINTR) retry;`。

### `sigset_t`

- **含义**：一个“信号集合”的抽象类型。
- **配套函数**：

  - `sigemptyset(&set)`：清空集合；
  - `sigaddset(&set, SIGCHLD)`：把 `SIGCHLD` 加入集合。
- **用途**：构造“要阻塞”的集合，配合 `sigprocmask` 调整当前线程的**信号屏蔽字**。

---

### 与“屏蔽/解除屏蔽/等待”相关的函数

#### `sigprocmask(int how, const sigset_t *set, sigset_t *oldset)`

- **作用**：设置/替换当前线程的**信号屏蔽字（blocked mask）**。
- **示例用法**：

  - `sigprocmask(SIG_BLOCK, &block, &prev)`：把 `block`（包含 `SIGCHLD`）加入屏蔽字，并把旧值保存到 `prev`；
  - `sigprocmask(SIG_SETMASK, &prev, NULL)`：恢复旧的屏蔽字。
- **为什么要先阻塞 `SIGCHLD`**：避免**竞态**
  在 fork 后、把子进程登记到“作业表”（或者任何你自己的数据结构）之前，若子进程已退出并触发 `SIGCHLD`，而你还没登记它，就可能“丢事件”。先阻塞它，等关键区做完，再按计划等待/处理。

#### `sigsuspend(const sigset_t *mask)`

- **作用**：原子地做两件事：
  1）把当前线程的屏蔽字**临时替换为 `mask`**（通常是空集，意味着**解除阻塞**）；
  2）**挂起**，直到有一个未被屏蔽的信号到达并处理完为止，然后函数返回 `-1, errno=EINTR`，且**自动恢复原来的屏蔽字**。
- **为什么要用它**：这是经典的**避免竞态**的原子步骤：

  - 如果你先 `unblock` 再 `pause()`，就可能在这两步之间**错过**信号（lost wakeup）；
  - `sigsuspend` 把“解除阻塞 + 睡眠”合成一步，保证不会错过。

---

### 信号处理器（Handler）中的注意点与函数

#### `static void sigchld_handler(int sig)`

- **签名**：必须是 `void (*)(int)`。
- **做的事**：

  1. 先保存 `errno`（`int saved = errno;`），因为某些系统调用会修改它；
  2. 用 `waitpid(-1, &status, WNOHANG)` **循环回收**所有已退出的子进程，防止僵尸；
  3. 设置 `chld_flag = 1` 告诉主循环“有子进程结束了”；
  4. 恢复 `errno`。
- **为什么**“只做标志位、尽量短小”：

  - Handler 运行在**异步**上下文，能用的函数非常有限（要“异步信号安全”）；
  - 逻辑越多越容易死锁、重入、破坏库状态（比如 `malloc` 在 handler 里调用就很危险）。

#### `waitpid(pid_t pid, int *status, int options)`

- **这里的用法**：`waitpid(-1, &status, WNOHANG)`

  - `-1`：表示等待任意子进程；
  - `WNOHANG`：非阻塞，若没有可回收的子进程立即返回 0；
  - > 0：回收了一个子进程；==0：没有；==-1：出错（比如没有子进程）。
- **为什么要循环**：多个子进程可能同时退出，一次信号到达应该把**所有**已退出的子进程都回收干净。

#### “异步信号安全”与 `write/printf`

- **`write`**：被 POSIX 标记为**异步信号安全**，可在 handler 使用；
- **`printf`**：**不安全**（内部用到缓冲、锁、`malloc` 等），不应该在 handler 中使用。
- 所以代码里用 `safe_write()` 包装 `write`，而把 `fprintf/printf` 放在主逻辑中使用。

#### 保存/恢复 `errno`

- **为什么**：Handler 里调用了系统调用，可能修改 `errno`，会影响主逻辑后续错误判断。保存/恢复可以保证主线 `errno` 不被“污染”。

#### `_exit(int status)` vs `exit(int status)`

- **在子进程里用 `_exit`**：

  - `_exit` 直接让内核结束进程，不做用户态清理（不刷新缓冲、不调用 `atexit` 钩子等）；
  - 避免与父进程共享的 stdio 缓冲被重复刷写、或在 `fork` 后处于“半初始化”状态的锁/资源引发未定义行为；
  - `exit` 适合“正常的进程结束”，不建议在 `fork` 后的**子进程**里使用（除非紧接着 `exec`，或者你明确知道影响）。

---

### 其它辅助函数

#### `sigemptyset/sigaddset`

- 前面已讲。`sigemptyset(&empty)` 常用于构造一个“完全不阻塞任何信号”的集合，以便 `sigsuspend(&empty)` 真正解除阻塞并睡眠。

#### `perror`

- 打印最近一个系统调用错误（基于 `errno`），只在**普通上下文**使用（不是 handler 里）。

---

### 这段程序的“整体设计意图”

1. **安装安全的 SIGCHLD 处理器**（`sigaction` + `SA_RESTART`）：
   让“子进程退出 → 触发 SIGCHLD → 统一回收”成为**可靠机制**。

2. **在关键区前阻塞 SIGCHLD**（`sigprocmask(SIG_BLOCK)`）：
   避免“子进程很快退出但我们还没把它登记/处理”的竞态。

3. **fork 子进程**：
   子进程用 `_exit(42)` 模拟“快速退出”的场景，帮我们验证竞态消除是否可靠。

4. **关键区后用 `sigsuspend(empty)` 等待**：
   原子地“解除阻塞并睡眠”，确保**不会错过**信号。

5. **handler 中批量回收**：
   在 `SIGCHLD` handler 里 `while (waitpid(-1, …, WNOHANG) > 0)`，把所有已退出子进程回收干净，并仅**设置标志**。

6. **恢复原先屏蔽字**（`sigprocmask(SIG_SETMASK, &prev, NULL)`）：
   不影响后续程序的信号屏蔽状态。

7. **主逻辑做最终确认**（一次 `waitpid(..., WNOHANG)`）：
   仅作为健壮性检查：如果 handler 已经回收，结果应为 0（没有遗留僵尸）。

---

### 调用顺序（简版时序）

```
main:
  sigaction(SIGCHLD, handler)
  block = {SIGCHLD}
  sigprocmask(SIG_BLOCK, &block, &prev)     // 进入关键区前阻塞 SIGCHLD
  pid = fork()
    child:
      sleep(1)
      _exit(42)
    parent:
      // 关键区：登记子进程/打印
      sigsuspend(empty)                     // 原子地解除阻塞并睡眠

handler(SIGCHLD):
  while (waitpid(-1, &st, WNOHANG) > 0) { ... }  // 回收所有已退出子进程
  chld_flag = 1

main(被信号唤醒):
  sigprocmask(SIG_SETMASK, &prev, NULL)     // 恢复屏蔽字
  // 可选：waitpid(pid, &st, WNOHANG) 检查，正常应返回 0
```

---

### 常见坑与这份代码如何避免

- **错过信号（lost wakeup）**：用 `sigsuspend` 原子地“解除阻塞+睡眠”，避免“先解阻塞、再睡眠”之间的竞态窗口。
- **僵尸进程**：handler 里循环 `waitpid(..., WNOHANG)` 回收**全部**；主线不再阻塞等待。
- **在 handler 里用 printf/malloc 等**：用 `write`，并把复杂逻辑放回主线程。
- **被信号打断的系统调用**：`SA_RESTART` 降低 `EINTR` 的处理负担。
- **`errno` 被污染**：进入/离开 handler 时保存/恢复。
- **`exit` 导致双重 flush/锁紊乱**：子进程用 `_exit`。

“竞态”的英文是 **race condition**（更具体的“数据竞争”叫 **data race**）。

### 概念（一句话版）

**竞态（race condition）**：当多个执行路径**并发/异步**地访问**同一份状态**，且**结果取决于它们的先后时序**时，就发生了竞态。时序不同→结果可能不同→出现偶发错误。

### 两个常见类型

- **data race（数据竞争）**：至少有一个写入、且没有同步（锁/原子/屏蔽等）保护，导致读到撕裂/旧值或未定义行为（多线程经典问题）。
- **higher-level race（高层竞态）**：即使每次读写本身是“原子”的，但**操作序列之间**没有正确的顺序保证，仍会出错。比如“先检查再睡眠”与“事件到达”的先后次序问题。

### 跟 signals 相关的经典例子：lost wakeup（丢信号）

错误写法（先解开屏蔽，再睡下去，中间可能错过信号）：

```c
sigprocmask(SIG_UNBLOCK, &set, NULL); // 解屏蔽 SIGCHLD
pause();                               // 准备睡眠等待……
/* 若 SIGCHLD 在这两行之间到达并处理完，pause 将无限睡下去 —— 丢信号 */
```

正确写法（**原子地**解屏蔽并睡眠）：

```c
sigset_t empty; sigemptyset(&empty);
sigsuspend(&empty); // 一步里完成：临时掩码=empty(解屏蔽) + 睡眠；返回即被信号唤醒
```

这里的“先后时序”若处理不当，就形成竞态；`sigsuspend` 把两步合成一步，消除竞态窗口。

### 其它直观例子

- **TOCTOU（检查-使用时间差）**：先 `stat(path)` 再 `open(path)`，两步之间文件可能被替换，安全性出错（高层竞态）。
   规避：用 `open(..., O_CREAT|O_EXCL)` 或基于 fd 的操作，减少“检查与使用”之间的窗口。
- **多线程计数器**：多个线程做 `counter = counter + 1`，若无原子/锁保护，是 data race。
   规避：用原子操作（C11 `atomic_int`）、互斥锁等。

### 判断是否有竞态的三要素

1. 有**共享状态**；
2. 有**并发/异步**访问；
3. **缺少顺序/互斥保证**（锁、原子、屏蔽字、条件变量、事件fd 等）。

### 常见规避手段（按场景）

- 多线程：互斥锁/读写锁、原子变量、条件变量、内存序。
- 信号：**屏蔽字**保护关键区；用 **`sigsuspend`** 实现“解屏蔽+等待”的原子性；在 handler 里只设 **`volatile sig_atomic_t`** 标志。
- I/O/文件：避免 TOCTOU，使用原子系统调用组合（如 `openat`、`linkat`、`rename` 等）。

简短总结：
 **竞态（race condition）\**就是\**结果受时序影响**的并发/异步错误；数据竞争（data race）是其底层形态之一。信号编程里用“屏蔽字 + `sigsuspend` 原子等待”就是在**缩小时序窗口**，从而消灭竞态。

下面把“信号屏蔽字（signal mask / blocked signals）”讲清楚：它是什么、作用、怎么改、和“待决信号(pending)”与“处理器(handler)”的关系，以及常见用法与坑。

### 它是什么

- **信号屏蔽字**是一份“**当前线程**临时不允许递送的信号集合”。
- 表示为一个 `sigset_t` 集合，操作它用 `sigemptyset/sigaddset/sigdelset/sigismember` 这类函数。
- **被屏蔽 ≠ 忽略**：屏蔽是“先不递送，先挂起”；忽略是“来了就当没来”。

> 现代 POSIX 里信号屏蔽字是**线程级**的（每个线程各有一份）。早期 Unix 是进程级，但在多线程实现里你要理解为每个线程都有自己的 mask。

### 它的作用

1. **推迟递送**：当某个信号在屏蔽字里时，这个信号即使到达也不会立刻跑 handler；它会进入**待决(pending)** 状态。
2. **解除屏蔽时补递送**：一旦把这个信号从屏蔽字里移除，如果该信号“待决”，内核会立刻把它递送给线程，触发默认动作或调用你注册的 handler。
3. **临界区保护**：在修改共享状态的临界区里临时屏蔽相关信号，避免在“改到一半”时 handler 抢进来破坏不变式。
4. **避免竞态/丢信号**：配合 `sigsuspend` 实现“原子地**解除屏蔽并睡眠**”，防止“先解开—还没睡下去就错过信号”的 lost wakeup。

### 它跟“待决信号”的关系

- **待决(pending)**：信号已经到达了，但由于被屏蔽（或同类正在处理被隐式屏蔽），暂时不能递送，于是记在“待决集合”里。
- 对于**非实时（标准）信号**，同一种信号只会在待决里保留**1 个**（不排队，来再多次也只记一次）。
- 对于**实时信号**，是**可排队**的，可以积累多个。
- 只要解除屏蔽，待决里对应的信号马上递送。

### 它和 handler 的关系

- 当某个信号的 handler 正在运行时，内核会**隐式地**把“正在处理的这个信号本身”加入屏蔽（防重入）。
- 此外你还可以在安装 handler 时通过 `sigaction.sa_mask` 指定“**在这个 handler 运行期间**还要顺便屏蔽的其他信号”，进一步避免交叉重入。

### 如何修改“信号屏蔽字”

最常用的三种方式：

1. **永久修改（直到你再改回去）**
   - `sigprocmask(how, &set, &oldset)`（单线程程序常用）
   - `pthread_sigmask(how, &set, &oldset)`（多线程程序应优先用它）
   - `how` 取值：
     - `SIG_BLOCK`：把 `set` 里的信号加入屏蔽字
     - `SIG_UNBLOCK`：把 `set` 从屏蔽字移除
     - `SIG_SETMASK`：直接把屏蔽字替换为 `set`
2. **“原子地解除屏蔽并睡眠”**
   - `sigsuspend(&temp_mask)`：临时把屏蔽字换成 `temp_mask`（通常是空集，表示不屏蔽任何信号），然后**睡眠**直到收到一个未屏蔽信号；返回时自动恢复原屏蔽字。
   - 这就是经典的**避免丢信号**的做法：先在关键区**屏蔽**，关键区结束后用 `sigsuspend` 一次性**解屏蔽+等待**。
3. **进入 handler 时的临时屏蔽**
   - `struct sigaction.sa_mask`：指定“handler 运行期间额外屏蔽哪些信号”。
   - 结束 handler 后，内核会恢复进入前的屏蔽字。

### 一个迷你例子（关键区保护 + 不丢信号）

```c
sigset_t block, prev, empty;
sigemptyset(&block);
sigaddset(&block, SIGCHLD);

// 关键区前：阻塞 SIGCHLD，避免竞态
pthread_sigmask(SIG_BLOCK, &block, &prev);

// 关键区：更新共享结构（例如作业表）
update_job_table(...);

// 原子：临时把屏蔽字设为空集并睡眠，直到来一个未屏蔽信号
sigemptyset(&empty);
while (!chld_flag) {               // chld_flag 在 SIGCHLD handler 中置 1
    sigsuspend(&empty);
}

// 恢复屏蔽字
pthread_sigmask(SIG_SETMASK, &prev, NULL);
```

### 它与“信号处置（disposition）”的区别

- **处置**（`SIG_DFL` 默认、`SIG_IGN` 忽略、或某个 handler 函数）回答“**来了要做什么**”。
- **屏蔽字**回答“**现在可不可以递送**”。
- 二者互不相同且可以组合：例如“默认处置 + 暂时屏蔽”，“自定义 handler + 暂时屏蔽”。

### 不能屏蔽的信号

- `SIGKILL` 和 `SIGSTOP` **无法被捕获、忽略、屏蔽**。内核保留，用于保证系统能强制终止/暂停进程。

### 继承与生存期

- **fork**：子进程**继承**父进程的信号屏蔽字。
- **exec**：新的程序映像**保留**旧的屏蔽字（处置会重置为默认，但被设置为 `SIG_IGN` 的有特殊规则会保持忽略；handler 指针会被清空）。
- 因此：如果在 exec 前屏蔽了一些信号，exec 之后仍然是被屏蔽的——别忘了按需恢复。

### 常见坑

- 把“屏蔽”当成“忽略”。屏蔽只是**延后**，不是不要。
- 在多线程程序里用 `sigprocmask` 改全局，以为会影响所有线程。实际上屏蔽字是**线程级**的；你需要在**目标线程**上调用 `pthread_sigmask`。
- 屏蔽后没有用 `sigsuspend` 这种原子方式等待，导致解屏蔽与睡眠之间**竞态**，错过信号。
- 以为屏蔽能挡住 `SIGKILL/SIGSTOP`——做不到。

------

一句话总结：
 **信号屏蔽字 = “这会儿先别打扰我”的线程本地信号过滤器。**它让你能在关键区里把信号“挂起不递送”，并在安全的时间点用 `sigsuspend` 原子地解开与等待，从而写出既正确又不丢事件的信号驱动程序。

 ### setjmp.c

没问题！我用**两条执行路径**把这份 `setjmp_demo.c` 讲清楚，并指出 `deep_layer*` 在哪儿被调用、`setjmp/longjmp` 各自做了什么。

------

# 代码在干嘛（一句话）

- `setjmp(env)`：把当前**执行环境**（栈指针、寄存器、返回地址等）存到 `env`，并**返回 0**。
- `longjmp(env, code)`：把环境**恢复**回 `setjmp` 的位置，好像“倒带”，并让那次 `setjmp` **返回 `code`（非 0）**。

------

### 谁调谁？（调用关系）

```
main -> deep_layer1 -> deep_layer2 -> deep_layer3
```

- `deep_layer1(which)` 在 **main 的 if 分支里**被调用；
- `deep_layer1` 再调 `deep_layer2`，`deep_layer2` 再调 `deep_layer3`；
- `deep_layer3` 决定是否出错：
  - `which != 1`：正常返回，一路返回到 `main`；
  - `which == 1`：调用 `longjmp(env, 100)`，**立刻**跳回 `main` 里 `setjmp(env)` 的位置。

------

### 两条完整执行路径（逐行走一遍）

## 路径 A：正常路径（不触发错误）

命令：`./setjmp_demo`（没有参数，`which=0`）

1. `int rc = setjmp(env);`
   - 保存环境到 `env`，这次返回值 `rc = 0`。
2. 进入 `if (rc == 0)` 分支：
    打印“first time…”。
3. 调 `deep_layer1(0)` → `deep_layer2(0)` → `deep_layer3(0)`；
    `which != 1`，**不**调用 `longjmp`，逐层**正常 return**。
4. 回到 `main`，打印 “finished normally.”
5. 程序结束。

**输出**

```
[main] setjmp returns 0 (first time), run deep call chain...
[main] deep call chain finished normally.
```

#### 路径 B：错误路径（触发 longjmp 回退）

命令：`./setjmp_demo 1`（`which=1`）

1. `int rc = setjmp(env);`

   - 保存环境，`rc = 0`。

2. 进入 `if (rc == 0)` 分支：打印“first time…”。

3. 调用链：`deep_layer1(1)` → `deep_layer2(1)` → `deep_layer3(1)`；

4. 在 `deep_layer3` 中命中：

   ```c
   longjmp(env, 100);
   ```

   效果是：

   - **不再返回到 deep_layer3 / 2 / 1**（这些帧被“弹掉”）；
   - 直接“回到” `setjmp(env)` 那一行，好像 `setjmp` **第二次返回**，但这次返回值变成 `100`。

5. 这时 `rc = 100`，走 `else` 分支：打印“recovered…, code=100”。

**输出**

```
[main] setjmp returns 0 (first time), run deep call chain...
[main] recovered from error via longjmp, code=100
```

------

### 关键点释疑

- **`jmp_buf env` 为什么是全局？**
   只是为了 demo 简洁。实务里常用**静态/全局**或把 `env` 通过参数传下去；前提是：**`longjmp` 只能跳回仍然“活着”的栈帧对应的 `setjmp`**（即它所在的调用环境还在栈上）。
- **`setjmp` 究竟保存了什么？**
   由实现决定，但语义上至少保存足以“回到当前位置继续执行”的寄存器/栈指针/程序计数器等。你可以把它当作轻量级“栈快照标记”。
- **`longjmp(env, 0)` 会怎样？**
   标准规定会把返回值当作 **1**；也就是说“第二次返回”永远是**非 0**，便于 `if (rc==0)` / `else` 这种分流。
- **为什么 `printf` 在 `deep_layer\*` 后面的那行不会执行（错误路径）？**
   因为 `longjmp` **不会**从 `deep_layer3 → deep_layer2 → deep_layer1 → main` 逐层返回；它**直接**把控制权转移回 `setjmp` 点。这条路径上 `deep_layer` 们的后续语句都被**跳过**了。
- **这是异常机制吗？**
   行为类似“抛异常 → 栈展开到捕获点”。但 `setjmp/longjmp` 是 C 级别的“非局部跳转”，没有 C++ 那样的构造/析构语义（不会自动调用局部对象析构）。
- **何时用？**
  - 深栈的**错误快速回退**；
  - 与**信号**结合做“超时/中断 → 回到安全点”（例如在 `SIGALRM` handler 里 `longjmp` 回来）。
     但要克制使用：代码可读性和资源清理更难，能用结构化错误处理就别滥用。

------

### 一张小图（错误路径时的“回跳”）

```
setjmp(env) → rc=0
   |
   v
 deep_layer1 → deep_layer2 → deep_layer3
                                   |
                                   v
                           longjmp(env,100)
                                   |
                                   v
          (回到)setjmp(env) → rc=100 → else 分支
```

如果你愿意，我可以把这个 demo 再扩展一版：在 `deep_layer3` 里触发一个 `alarm(1)` + `SIGALRM` 的场景，用 handler 里的 `longjmp` 做“超时回退”，更贴近 CSAPP 里“信号 + 非局部跳转”的组合用法。
