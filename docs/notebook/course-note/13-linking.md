# Linking

***MOSTLY LREANED***

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

下面这份提要基于你上传的 CSAPP/15-213 “Linking（链接）”章节课件，按“概念→机制→格式→库→动态装载→案例（拦截/插桩）→实践建议”整理，便于期末复习和做实验时快速查阅。

## 1. 章节主线（你要记住什么）

- 链接（Linking）把**多个目标文件**组合成一个可执行文件；它既能在**编译期**完成，也能在**装载时**或**运行时**完成（动态链接）。
- 链接器两大核心工作：**符号解析**（把每个符号引用绑定到且只绑定到一个定义）与**重定位**（把节/符号从相对地址搬到最终虚拟地址，并修正所有引用）。

## 2. 静态链接做了什么

- 典型流程：分别编译得到 `.o`，再由 `ld` 合并为可执行文件（`gcc -Og -o prog main.c sum.c`）。
- **符号解析**：全局/外部/本地符号的概念；解析时将引用绑定到定义（诸如 `sum`、全局变量等）。
- **重定位**：把 `.text/.data` 等节合并并放到最终地址，修补指令/数据中的地址引用（示例中 `sum` 的 PC-relative 调用与全局数组地址被修正）。

## 3. ELF 基本结构（会读目标文件/可执行文件）

- ELF 是 Linux 统一的二进制格式，适用于 `.o`、可执行、`.so`。
- 关键节：`.text`（代码）、`.rodata`（只读表等）、`.data`（已初始化全局）、`.bss`（未初始化全局，不占文件空间）、`.symtab`（符号表）、`.rel.text/.rel.data`（重定位信息）、`.debug`（调试）。
- 进程装载布局：代码段（只读）、数据段（可写）、堆/共享库映射/栈等（图示要点）。

## 4. “强/弱符号”与常见陷阱

- **强符号**：函数、已初始化的全局变量；**弱符号**：未初始化全局变量。规则：
  1. 不允许多个强符号重名；
  2. 强覆盖弱；
  3. 多个弱符号任选其一（有时会产生“同名不同类型/布局”的坑）——编译器选项可影响行为。
      （规则与示例在课上“Linker Puzzles/Rules”部分）。

## 5. 静态库（.a）与链接顺序

- 静态库把一组 `.o` 打包，链接时**按命令行顺序**扫描，用到才抽取需要的成员；**库通常放在命令行末尾**，否则会出现“未定义引用”。
- 典型结构与流程示意（`libvector.a` / `libc.a` 与 `printf.o`）。

## 6. 共享库与动态链接（.so）

- 共享库在**装载时**由动态链接器 `ld-linux.so` 解析，也可在**运行时**通过 `dlopen/dlsym/dlclose` 手动装入/解析符号（懒绑定）。
- 运行时示例：打开 `libvector.so`、查询 `addvec`、调用并卸载。

## 7. 案例：库函数拦截/插桩（interposition）

- 目标：不改源代码，拦截 `malloc/free` 统计/追踪分配。
- **编译期**：用宏把 `malloc/free` 展开为自定义封装（`mymalloc/myfree`）。
- **链接期**：利用链接器 `--wrap,malloc/--wrap,free` 规则，把对 `malloc` 的引用解析到 `__wrap_malloc`，而在封装内部再通过 `__real_malloc` 调用真实实现。
- **装载/运行期**：在自定义 `.so` 中实现与 `malloc/free` 同名的函数，通过 `dlsym(RTLD_NEXT, "...")` 调到下一层真实实现；用 **`LD_PRELOAD`** 规定“先在我的 `.so` 里解析未决符号”。

## 8. 实操小抄（能直接用）

- 观察 ELF 结构与重定位：`objdump -dx a.out`（看符号与指令中被修补的地址）。
- 构建共享库：`gcc -shared -fPIC -o libxxx.so *.c`；运行时加载示例见 `dlopen/dlsym/dlclose` 代码片段。
- 运行期拦截：
  1. `gcc -shared -fpic -o mymalloc.so mymalloc.c -ldl`
  2. `LD_PRELOAD=./mymalloc.so ./your_prog`（先解析到你的封装）。
- 链接顺序坑：把静态库参数**放到命令行最后**，否则可能出现“undefined reference”。

## 9. 一句话总结

- **链接=符号解析+重定位**；ELF 统一了承载；静态库讲究顺序与按需抽取；共享库把链接时间推迟到装载/运行期；**拦截/插桩**可在编译期、链接期、运行期三处入手（`LD_PRELOAD` 最灵活）。

如果看不懂，在本仓库[CMU-15213/src at main · Deepcity/CMU-15213](https://github.com/Deepcity/CMU-15213/tree/main/src)中有一个linkingdemo，由chatgpt编写，可以看看

## References

1. [CMU 15-213: Linking (CS:APP3e)](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f09/www/)
