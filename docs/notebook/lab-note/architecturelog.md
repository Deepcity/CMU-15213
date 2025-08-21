# ArchitectureLab

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

按照惯例看write-up和Lab handout当中的文件。

## Target

- 通过实现一个简化版的 x86-64（叫 Y86-64）的处理器，理解 流水线处理器设计 的基本原理。
- 在实验中，你会从 顺序执行 → 流水线执行 → 优化流水线（转发、stall、bubble 等） 一步步实现。

- Part A：编写和理解 Y86-64 程序（类似汇编），在仿真器 yas 和 yis 中运行。

- Part B：修改硬件实现（顺序 CPU → 流水线 CPU），主要修改 Verilog 或 HCL（硬件控制语言）代码。

- Part C：实现转发逻辑和 hazard 处理，让流水线正确执行各种指令。

- Bonus（可选）：增加新指令或优化执行。

## Keys

- 流水线五级结构：Fetch → Decode → Execute → Memory → Writeback。

- 数据冒险 (Data Hazard)：需要使用 数据转发 (Forwarding) 或 stall/bubble 来解决。

- 控制冒险 (Control Hazard)：分支预测失败时需要 flush 流水线。

- HCL（Hardware Control Language）：这是 lab 的核心工具，用来写 CPU 的电路行为。

## The Obscure Topic

**yas**: `Y86 assmbler` 编译器,把 `.ys` 汇编程序转成 `.yo` 机器码

**yis**: `Y86 instruction set simulator` 命令执行模拟器,执行 `.yo` 文件，模拟 CPU 执行过程

**misc**: `miscellaneous` 意味杂七杂八的，通常作为辅助工具，额外的脚本和小程序，非核心代码

**hcl**: `Hardware Control Language` 转换器，把你写的 .hcl 电路描述翻译成 C 程序，便于编译和仿真

**.hcl**: 它是一种简化的硬件描述语言，用来描述 Y86-64 CPU 的数据通路和控制逻辑。

```perl
pipe-full.hcl  --hcl2c-->  pipe-full.c  --gcc-->  pipe-full (可执行模拟器)
```

**.lex**: `Lex specification`（词法分析器描述文件），由 Flex 工具(见[前置软件](#makefile-problem)处安装)处理。`.lex` 文件用来定义如何把输入文本（比如汇编源代码、HCL 代码）**分解成一个个词法单元（token）**，供语法分析器使用。

**isa**: `Instruction Set Architecture implementation`（指令集实现）

 	这是 Y86-64 的“指令集定义代码”，相当于解释器，规定了每条指令的含义和执行方式。

​	 在 misc/ 目录下，它和 yis.c 配合使用。

 	yis.c 是模拟器的框架，isa.c 提供了指令级别的具体实现。

 	比如 isa.c 里会有类似：

 ```c
case I_ADDQ:
  val = get_reg(ra) + get_reg(rb);
  set_reg(rb, val);
  break;
 ```

`Y86指令集`: 为csapp自定义的一套指令集，具体在CS:APP（第三版）第四章 S4.1 - S4.2部分有阐述。包括
- 数据传送指令（`rrmovq`, `irmovq`, `mrmovq`, `rmmovq`）
- 算术/逻辑指令（`addq`, `subq`, `andq`, `xorq`）
- 跳转指令（`jmp`, `jle`, `jl`, `je`, `jne`, `jge`, `jg`）
- 条件传送指令（`cmovXX`）
- 调用/返回指令（`call`, `ret`）
- 栈操作（`pushq`, `popq`）
- 停止指令（`halt`, `nop`）

| 类别   | 指令示例              | 说明                             |
| ---- | ----------------- | ------------------------------ |
| 数据传送 | `rrmovq rA,rB`    | rB ← rA                        |
|      | `irmovq V,rB`     | rB ← V                         |
|      | `mrmovq D(rB),rA` | rA ← M\[rB+D]                  |
|      | `rmmovq rA,D(rB)` | M\[rB+D] ← rA                  |
| 算术逻辑 | `addq rA,rB`      | rB ← rB + rA                   |
|      | `subq rA,rB`      | rB ← rB - rA                   |
|      | `andq rA,rB`      | rB ← rB & rA                   |
|      | `xorq rA,rB`      | rB ← rB ^ rA                   |
| 跳转   | `jmp Dest`        | 无条件跳转                          |
|      | `je Dest`         | ZF=1 时跳转                       |
|      | `jne Dest`        | ZF=0 时跳转                       |
| 栈操作  | `pushq rA`        | %rsp ← %rsp - 8; M\[%rsp] ← rA |
|      | `popq rA`         | rA ← M\[%rsp]; %rsp ← %rsp + 8 |
| 调用   | `call Dest`       | pushq %rip; jmp Dest           |
|      | `ret`             | popq %rip                      |
| 特殊   | `halt`            | 停止执行                           |
|      | `nop`             | 空操作                            |

详细指令集查看`isa.c`与`isa.h`也有定义。但是注意，复杂的调用语句例如 `0x0(%rbp, %rsi, 1)` 的调用方法仍需要查看具体实现或直接进行尝试。

不建议在这个部分（指令集）花太多时间，实在不行就换一种实现方式

## Pre Experiments

通过一个程序调度了解`yas`，`yis`的实际使用。

```shell
cd ./misc
./yas ../y86-code/asum.ys # 编译
./yis ../y86-code/asum.yo # 执行
```

该程序的功能是累加array的数值。

输出如下
```shell
Stopped in 34 steps at PC = 0x13.  Status 'HLT', CC Z=1 S=0 O=0
Changes to registers:
%rax:   0x0000000000000000      0x0000abcdabcdabcd
%rsp:   0x0000000000000000      0x0000000000000200
%rdi:   0x0000000000000000      0x0000000000000038
%r8:    0x0000000000000000      0x0000000000000008
%r9:    0x0000000000000000      0x0000000000000001
%r10:   0x0000000000000000      0x0000a000a000a000

Changes to memory:
0x01f0: 0x0000000000000000      0x0000000000000055
0x01f8: 0x0000000000000000      0x0000000000000013
```

可见rax中的返回值为array数组的四个数据累和`0x0000abcdabcdabcd`。
同时给出的信息还有被更改的寄存器以及更改的内存。

`PC`: 该数值指出模拟器执行了多少条指令
`Status 'HLT'`: 表明程序因找到halt指令而终止，如果出错（例如非法指令，地址越界），这里会显示ADR、INS等错误状态
`CC Z=1 S=0 O=0`: 表明标志寄存器的状态，`CC`即 Condition Codes
`Changs`: 依照`<addr>: <start_val> <end_val>`的方式列出`registers`与`memory`的更改

> 下面的Changs to memory是程序对栈的更改

下面的任务中，凡是`ys`相关代码，都存放在`./y86-code`目录中

## Part A

> Your task is to write and simulate the following three Y86-64 programs. The required behavior of these programs is defined by the example C functions in examples.c. Be sure to put your name and ID in a comment at the beginning of each program. You can test your programs by first assemblying them with the program YAS and then running them with the instruction set simulator YIS.
>
>In all of your Y86-64 functions, you should follow the x86-64 conventions for passing function arguments, using registers, and using the stack. This includes saving and restoring any callee-save registers that you use.

这一部分的内容主要在`./sim/misc`中进行，c语言逻辑存放在 `examples.c` 文件中。

- 编写 Y86-64 汇编程序，并使用 yas（Y86 assembler）和 yis（Y86 instruction set simulator）进行汇编和运行。

- 熟悉 Y86-64 指令集，理解它和 x86-64 的关系。

- 最终任务：写出几个小程序，完成给定的功能（比如算阶乘、数组操作、递归调用等）。

### sum.ys 迭代求和链表元素

简单编写一份汇编代码
```assembly
# Execution begins at address 0
	.pos 0 
	irmovq stack,%rsp
	call main
	halt

# Sample linked list
	.align 8
	ele1:
		.quad 0x00a
		.quad ele2
	ele2:
		.quad 0x0b0
		.quad ele3
	ele3:
		.quad 0xc00
		.quad 0

main: irmovq ele1,%rdi
	call sum_list
	ret

# long sum_list(list_ptr ls)
# start in %rdi, end in $0
sum_list: irmovq $0,%rax 		# val=0
	jmp test 									# Goto test
loop:  mrmovq (%rdi), %rsi
  addq %rsi, %rax
  mrmovq 8(%rdi), %rdi
test: 
	andq %rdi, %rdi
	jne 	loop						# Stop when next=0
	ret
	
# Stack starts here and grows to lower addresses
	.pos 0x200
stack:

```
 
当编译时可能会遇到报错，与gcc的编译报错类似，会提示在哪一行出现的错误和可能的原因
```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/misc$ ./yas ../y86-code/sum.ys 
Error on line 30: Missing Colon
Line 30, Byte 0x0085:   xor 1(%rdi) 1(rdi)                              # Set CC
Error on line 37: Missing end-of-line on final line

Line 37, Byte 0x0200:   .pos 0x200
```

## Part B

## Part C


## Appendix

### Makefile Problem

必要软件如下
```shell
sudo apt install tcl tcl-dev tk tk-dev
sudo apt install flex
sudo apt install bison
```

若仍然出现如下报错
```shell
(cd misc; make all)
make[1]: Entering directory '/home/ubuntu/learnning_project/CMU-15213/src/Architecture-Lab/sim/misc'
gcc -Wall -O1 -g -c yis.c
gcc -Wall -O1 -g -c isa.c
gcc -Wall -O1 -g yis.o isa.o -o yis
gcc -Wall -O1 -g -c yas.c
flex yas-grammar.lex
mv lex.yy.c yas-grammar.c
gcc -O1 -c yas-grammar.c
gcc -Wall -O1 -g yas-grammar.o yas.o isa.o -lfl -o yas
/usr/bin/ld: yas.o:/home/ubuntu/learnning_project/CMU-15213/src/Architecture-Lab/sim/misc/yas.h:13: multiple definition of `lineno'; yas-grammar.o:(.bss+0x0): first defined here
collect2: error: ld returned 1 exit status
make[1]: *** [Makefile:32: yas] Error 1
make[1]: Leaving directory '/home/ubuntu/learnning_project/CMU-15213/src/Architecture-Lab/sim/misc'
make: *** [Makefile:26: all] Error 2
```
lineno 这个符号被定义了两次：

一次在 yas-grammar.o（flex 自动生成的词法分析器代码）里

一次在你项目里的 yas.o（通过 yas.h 引入）

这时，在所有子文件夹的Makefile中加入一个FLAGS即可
```Makefile
CFLAGS=-Wall -O1 -g -fcommon
LCFLAGS=-O1 -fcommon # 没有这一项就不加
```
探索原因为：

CMU 15213 Architecture Lab 的源代码是十几年前写的（大概 GCC 4.x 时代）。

当时 GCC 默认是 -fcommon 模式 → 意味着如果你在多个 .c 文件里写了 int lineno;，它们会被放到 “common symbol” 里，链接时会自动合并为一个，不会报错。

但 从 GCC 10 开始默认改为 -fno-common，这就变成了现在报错的情况。

现代GCC更加严格

## REF
1. https://csapp.cs.cmu.edu/3e/archlab.pdf
2. https://zhuanlan.zhihu.com/p/480380496