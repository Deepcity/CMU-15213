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
