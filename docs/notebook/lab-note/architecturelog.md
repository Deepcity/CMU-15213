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
	call rsum_list
	ret

# long rsum_list(list_ptr ls)
# start in %rdi, end in $0
sum_list: irmovq $0,%rax 		# val=0
	jmp test 									# Goto test
loop:  mrmovq (%rdi), %rsi 	# Get ls->val
  addq %rsi, %rax						# val += ls->val
  mrmovq 8(%rdi), %rdi			# ls = ls->next
test: 
	andq %rdi, %rdi						# Set CC
	jne 	loop								# Stop when next=0
	ret
	
# Stack starts here and grows to lower addresses
	.pos 0x200
stack:

```
需要注意的是
- 这里的数据存储的order，可见地址位应该是存放在高32位的，这也就是说8(%rdi)才是next
- 这里的8(%rdi)也可以改成 0x8(%rdi)
 
当编译时可能会遇到报错，与gcc的编译报错类似，会提示在哪一行出现的错误和可能的原因
```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/misc$ ./yas ../y86-code/sum.ys 
Error on line 30: Missing Colon
Line 30, Byte 0x0085:   xor 1(%rdi) 1(rdi)                              # Set CC
Error on line 37: Missing end-of-line on final line

Line 37, Byte 0x0200:   .pos 0x200
```
### rsum.ys 反向遍历求和链表元素

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
	call rsum_list
	ret

# long rsum_list(list_ptr ls)
# start in %rdi, end in $0
rsum_list: andq %rdi,%rdi	# Set CC if(ls)
	je	end									# End recursion
	mrmovq (%rdi),%rsi      # rest=ls->val
	pushq	%rsi							# Storage rest
	mrmovq 8(%rdi),%rdi			# ls = ls->next
	call rsum_list					# call rsum_list
	popq	%rsi							# Get rest
	addq %rsi,%rax					# return val + rest
	ret
end: xorq %rax,%rax				# return 0
	ret
	
# Stack starts here and grows to lower addresses
	.pos 0x200
stack:

```

需要注意的点如下：
1. 这里的递归调用与c中的递归调用存在一些逻辑上的区别,在c中ls这个参数在一个rsum_list调用中式不会被改变的，而在这个程序中，则在每个rsum_list中都被改变了
2. y86的语法，如果希望使用`D(r)`的语法只能通过`mrmovX`或`rmmovX`。

更符合原著的方式如下
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
	call rsum_list
	ret

# long rsum_list(list_ptr ls)
# start in %rdi, end in $0
rsum_list: andq %rdi,%rdi	# Set CC if(ls)
	je	end									# End recursion
	# mrmovq (%rdi),%rsi      # rest=ls->val
	# pushq	%rsi							# Storage rest
	pushq	%rdi
	mrmovq 8(%rdi),%rdi			# ls = ls->next
	call rsum_list					# call rsum_list
	# popq	%rsi							# Get rest
	popq %rdi
	# addq %rsi,%rax					# return val + rest
	mrmovq	(%rdi),%rsi
	addq	%rsi,%rax
	ret
end: xorq %rax,%rax				# return 0
	ret
	
# Stack starts here and grows to lower addresses
	.pos 0x200
stack:

```

可以参考一下[REF](#ref) 2中的代码

看一下下面这一份的输出，正确的
```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/y86-code$ ../misc/yis ./rsum.yo
Stopped in 37 steps at PC = 0x13.  Status 'HLT', CC Z=0 S=0 O=0
Changes to registers:
%rax:   0x0000000000000000      0x0000000000000cba
%rsp:   0x0000000000000000      0x0000000000000200
%rsi:   0x0000000000000000      0x000000000000000a
%rdi:   0x0000000000000000      0x0000000000000018

Changes to memory:
0x01c0: 0x0000000000000000      0x000000000000007c
0x01c8: 0x0000000000000000      0x0000000000000038
0x01d0: 0x0000000000000000      0x000000000000007c
0x01d8: 0x0000000000000000      0x0000000000000028
0x01e0: 0x0000000000000000      0x000000000000007c
0x01e8: 0x0000000000000000      0x0000000000000018
0x01f0: 0x0000000000000000      0x000000000000005b
0x01f8: 0x0000000000000000      0x0000000000000013
```

### copy.ys 复制long数组，并返回所有数值的异或和


直接给出正确的代码与输出
```assembly
# Execution begins at address 0
	.pos 0 
	irmovq stack,%rsp
	call main
	halt

.align 8
# Source block
src:
	.quad 0x00a
	.quad 0x0b0
	.quad 0xc00
# Destination block
dest:
	.quad 0x111
	.quad 0x222
	.quad 0x333

main: irmovq src,%rdi
	irmovq dest,%rsi
	irmovq $3,%rdx
	call copy_block
	ret

# long copy_block(long* src, long dest, long len)
# start in rdi with length rdx
copy_block: irmovq $0,%rax	# result = 0
	andq %rdx,%rdx						# Set CC
	irmovq $1,%rcx 						# Constant 1
	irmovq $8,%rbp						# Constant 8
	jmp 	test
loop:	mrmovq (%rdi),%r8 		# val = *src 
	addq %rbp,%rdi 		# src++
	rmmovq %r8,(%rsi) 				# dest = val
	addq %rbp,%rsi 		# dest++
	xorq %r8,%rax 						# result ^= val
	subq %rcx,%rdx 						# len--. Set CC
test: jne	loop							# Stop when len == 0
	ret

# Stack starts here and grows to lower addresses
.pos 0x200
stack:

```

```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/y86-code$ ../misc/yis ./copy.yo
Stopped in 36 steps at PC = 0x13.  Status 'HLT', CC Z=1 S=0 O=0
Changes to registers:
%rax:   0x0000000000000000      0x0000000000000cba
%rcx:   0x0000000000000000      0x0000000000000001
%rsp:   0x0000000000000000      0x0000000000000200
%rbp:   0x0000000000000000      0x0000000000000008
%rsi:   0x0000000000000000      0x0000000000000048
%rdi:   0x0000000000000000      0x0000000000000030
%r8:    0x0000000000000000      0x0000000000000c00

Changes to memory:
0x0030: 0x0000000000000111      0x000000000000000a
0x0038: 0x0000000000000222      0x00000000000000b0
0x0040: 0x0000000000000333      0x0000000000000c00
0x01f0: 0x0000000000000000      0x000000000000006f
0x01f8: 0x0000000000000000      0x0000000000000013
```

当我编写汇编代码时犯了一个错误，使用mrmovq 0x8(%rdi), %rdi代替了addq %rbp,%rdi（irmovq $8,%rbp）。但前者时取出0x8(%rdi)地址处的值将其放在rdi中，而后者则是正确的。

如果用c来表述`ptr = ptr->next`是前者，而`ptr++`是后者

## Part B

> You will be working in directory sim/seq in this part.
> Your task in Part B is to extend the SEQ processor to support the iaddq, described in Homework problems 4.51 and 4.52. To add this instructions, you will modify the file seq-full.hcl, which implements the version of SEQ described in the CS:APP3e textbook. In addition, it contains declarations of some constants that you will need for your solution.

这里需要我们完成`iaddq`指令，涉及“CS:APP”中的部分内容。在国内常规学校开设的课程中，多多少少会涉及到PC等寄存器和处理器框架，这里还是建议读一下“CS:APP”，如果只想了解lab如何完成，请往下看。

1. 取址：根据PC的值读入指令字节。每一条指令长短不一，但都规范化为几个结构（在Y86中 RISA架构处理器）
    - `icode`，`ifunction` 分别占1个字节，共两个字节，例如 0x30，code的含义是分类指令，例如`jmp`, `je`等。ifunction则是区分同一分类中的不同指令
	- `rA`, `rB` 指明寄存器。寄存器的编号如下图所示
	- 8字节常数数字`valC`。~~（这里是由于Y86,在CIRS（x86-64）中不是这样）~~
	- 下一条指令的地址是`valP`

![寄存器编码](https://s2.loli.net/2025/09/05/CQciPtuRYyqwxb4.png)
![指令类别](https://s2.loli.net/2025/09/05/4oZQvaKGPj3RA6m.png)
![指令字节码](https://s2.loli.net/2025/09/05/WUGHaL32rOwBeV5.png)

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