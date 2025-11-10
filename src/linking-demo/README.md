# CSAPP Linking Demo

Small self-contained project that mirrors the CMU 15-213 “Linking” lecture demos:

- `libhello.a` — static archive linked into `main`
- `libmylib.so` — shared library resolved both at link time and via `dlopen`
- `libmymalloc.so` — LD_PRELOAD interposer that prints every malloc/free

## Dependencies

- GCC (or Clang), GNU Make, binutils
- Linux with glibc (tested on Ubuntu 20.04+)

## Layout

| Path | Description |
| --- | --- |
| `src/hello.c` | Static library implementation (`libhello.a`) |
| `src/mylib.c` | Shared library implementation (`libmylib.so`) |
| `src/main.c` | Links against both libraries and performs sample work |
| `src/dlopen_demo.c` | Dynamically loads `libmylib.so` with `dlopen` |
| `interpose/mymalloc.c` | malloc/free interposer used via `LD_PRELOAD` |
| `include/*.h` | Public headers for the libraries |

## Build

```bash
make            # builds libs + main + dlopen_demo
make clean      # removes objects/binaries
```

The default build adds `-Wl,-rpath,'$ORIGIN'` so `main` can locate `libmylib.so`
in the current directory without setting `LD_LIBRARY_PATH`.

## Demo Targets

```bash
make run        # ./main (static + shared linking)
make dlopen     # ./dlopen_demo (runtime loading via dlopen/dlsym)
make preload    # LD_PRELOAD=./libmymalloc.so ./main
```

Use `make preload` to see every malloc/free intercepted by the interposer.

## Partial Explain

### 1) LD_PRELOAD 在做什么？

- 运行一个可执行程序时，**动态链接器**（通常是 `/lib64/ld-linux-x86-64.so.2` 一类）会把程序依赖的 `.so` 加载进进程，并做**符号解析**（把对函数/变量的引用绑定到一个“定义”上）。

- 设置环境变量

  ```bash
  LD_PRELOAD=/path/to/your.so ./your_prog
  ```

  的效果是：在装载依赖库之前，**“额外先”加载** `your.so`，并把它排在**搜索顺序的最前面**。

- 结果：如果 `your.so` 里实现了和系统库**同名**的函数（比如 `malloc`、`free`），**未绑定的引用会优先解析到你的实现**，这就叫**符号 interposition（拦截/插桩）**。

- 注意：对 **setuid 程序** 或某些安全场景，系统会**忽略** LD_PRELOAD；另外只对**动态链接**的程序有效（静态链接的 `-static` 无效）。

### 2) dlsym 是什么？

- `dlsym` 是 `<dlfcn.h>` 里的函数，用来**在运行时**按名字查找一个符号的地址。签名大致是：

  ```c
  void *dlsym(void *handle, const char *symbol);
  ```

- 参数 `handle` 决定“从哪儿开始找”：

  - `dlopen` 返回的句柄：只在那个模块（及其依赖）里找；
  - `RTLD_DEFAULT`：按全局默认顺序找；
  - **`RTLD_NEXT`（GNU 扩展）**：从**“当前模块之后”**继续找下一个同名定义（这就是“绕过我自己，找到被我拦截的真实实现”）。

- 返回值是 `void*`，你需要**强制转换**成正确的函数指针类型；如果失败，用 `dlerror()` 看错误信息。

- 链接时别忘了 `-ldl`。

### 3) 为什么要 `#define _GNU_SOURCE`？

- 这是一个“启用 GNU 扩展”的宏。对本例最重要的是：**启用 `RTLD_NEXT` 宏**（glibc 的扩展）。
- 没有它，`RTLD_NEXT` 可能不可用或编译告警。

## 4) 这两行“奇怪”的全局变量到底是什么？

```c
static void *(*real_malloc)(size_t) = NULL;
static void (*real_free)(void*) = NULL;
```

它们是**函数指针的全局变量**，分别指向“真实的 `malloc` / `free`”。

逐词解析第一行：

- `void *(*real_malloc)(size_t)`：
  - 最外层是 `(*real_malloc)(size_t)`，说明 `real_malloc` 是**指向函数**的**指针**；
  - 该函数的**参数**是 `size_t`；
  - 该函数的**返回值**是 `void *`。
- 前面的 `static`：仅在当前源文件可见（**内部链接**）；
- 末尾 `= NULL`：初始化为空指针，稍后用 `dlsym` 填上真实地址。

第二行同理：`real_free` 是**指向**“入参为 `void*`、返回 `void` 的函数”的**指针**。

> 更易读的写法：
>
> ```c
> typedef void *(*malloc_fn_t)(size_t);
> typedef void  (*free_fn_t)(void *);
> static malloc_fn_t real_malloc = NULL;
> static free_fn_t   real_free   = NULL;
> ```

### 5) 为什么需要它们？

当我们自己实现了一个与系统同名的 `malloc`/`free`，在函数内部要“调用原版”的 `malloc`/`free` 去真正干活，否则会**无限递归**。

- 用 `dlsym(RTLD_NEXT, "malloc")` 找到“**下一个**同名定义”（也就是 glibc 的真正 `malloc`），把地址放进 `real_malloc`；
- 以后就调用 `real_malloc(size)`，既能打印日志，又能保证功能正确。

### 6) 最小可运行拦截示例（可直接粘贴）

```c
// file: mymalloc.c
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

typedef void *(*malloc_fn_t)(size_t);
typedef void  (*free_fn_t)(void *);

static malloc_fn_t real_malloc = NULL;
static free_fn_t   real_free   = NULL;

static void init_real(void) {
    if (!real_malloc) {
        real_malloc = (malloc_fn_t)dlsym(RTLD_NEXT, "malloc");
    }
    if (!real_free) {
        real_free = (free_fn_t)dlsym(RTLD_NEXT, "free");
    }
}

void *malloc(size_t size) {
    init_real();
    void *p = real_malloc(size);
    fprintf(stderr, "[interpose] malloc(%zu) -> %p\n", size, p);
    return p;
}

void free(void *ptr) {
    init_real();
    fprintf(stderr, "[interpose] free(%p)\n", ptr);
    real_free(ptr);
}
```

编译与运行：

```bash
gcc -fPIC -shared mymalloc.c -o libmymalloc.so -ldl
LD_PRELOAD=$PWD/libmymalloc.so your_program
```

### 7) 符号解析的“路径图”

```
your_program -> 调用 malloc
   |
   |  (LD_PRELOAD 把 your.so 插到最前)
   v
your.so: malloc(...)   <-- 先命中你
   |  (想要真正分配内存)
   |-- dlsym(RTLD_NEXT, "malloc") -> real_malloc
   `-- 调 real_malloc(...)       <-- 这才是 glibc 的 malloc
```

### 8) 常见坑 & 细节

- **递归/再入**：在拦截函数里尽量避免再次触发会调用 `malloc` 的操作（比如 `printf` 可能内部用到 `malloc`）。示例里打印到 `stderr` 通常更安全一些，但严格场景下可以加“**递归保护标志**”。

- **线程安全**：`init_real()` 里并发初始化可能竞态；简单场景问题不大，严谨做法可用 `pthread_once`。

- **ABI 匹配**：拦截函数的**签名必须与真实函数完全一致**，否则崩。

- **安全限制**：对 setuid 程序 LD_PRELOAD 可能无效；容器/守护进程环境可能清掉环境变量。

- **链接**：别忘 `-ldl`；某些发行版需要在 `LD_LIBRARY_PATH` 或 `rpath` 中能找到依赖。

- **初始化时机**：也可用

  ```c
  __attribute__((constructor))
  static void preload_init(void) { /* 先做 dlsym */ }
  ```

  但 `malloc` 很可能在构造期就被调用，**延迟初始化**（见上面的 `init_real()`）更稳妥。

## References

1. [CMU 15-213: Linking (CS:APP3e)](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f09/www/)
