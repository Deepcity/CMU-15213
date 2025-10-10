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

​  在 misc/ 目录下，它和 yis.c 配合使用。

  yis.c 是模拟器的框架，isa.c 提供了指令级别的具体实现。

  比如 isa.c 里会有类似：

 ```c
case I_ADDQ:
  val = get_reg(ra) + get_reg(rb);
  set_reg(rb, val);
  break;
 ```

**Y86指令集**: 为csapp自定义的一套指令集，具体在CS:APP（第三版）第四章 S4.1 - S4.2部分有阐述。包括

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
sum_list: irmovq $0,%rax   # val=0
 jmp test          # Goto test
loop:  mrmovq (%rdi), %rsi  # Get ls->val
  addq %rsi, %rax      # val += ls->val
  mrmovq 8(%rdi), %rdi   # ls = ls->next
test: 
 andq %rdi, %rdi      # Set CC
 jne  loop        # Stop when next=0
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
rsum_list: andq %rdi,%rdi # Set CC if(ls)
 je end         # End recursion
 mrmovq (%rdi),%rsi      # rest=ls->val
 pushq %rsi       # Storage rest
 mrmovq 8(%rdi),%rdi   # ls = ls->next
 call rsum_list     # call rsum_list
 popq %rsi       # Get rest
 addq %rsi,%rax     # return val + rest
 ret
end: xorq %rax,%rax    # return 0
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
rsum_list: andq %rdi,%rdi # Set CC if(ls)
 je end         # End recursion
 # mrmovq (%rdi),%rsi      # rest=ls->val
 # pushq %rsi       # Storage rest
 pushq %rdi
 mrmovq 8(%rdi),%rdi   # ls = ls->next
 call rsum_list     # call rsum_list
 # popq %rsi       # Get rest
 popq %rdi
 # addq %rsi,%rax     # return val + rest
 mrmovq (%rdi),%rsi
 addq %rsi,%rax
 ret
end: xorq %rax,%rax    # return 0
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
copy_block: irmovq $0,%rax # result = 0
 andq %rdx,%rdx      # Set CC
 irmovq $1,%rcx       # Constant 1
 irmovq $8,%rbp      # Constant 8
 jmp  test
loop: mrmovq (%rdi),%r8   # val = *src 
 addq %rbp,%rdi   # src++
 rmmovq %r8,(%rsi)     # dest = val
 addq %rbp,%rsi   # dest++
 xorq %r8,%rax       # result ^= val
 subq %rcx,%rdx       # len--. Set CC
test: jne loop       # Stop when len == 0
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

这里需要我们在SEQ处理器上完成`iaddq`指令，主要修改hcl文件中的控制逻辑，涉及“CS:APP”中的部分内容。在国内常规学校开设的课程中，多多少少会涉及到PC等寄存器和处理器框架，这里还是建议读一下“CS:APP”，如果只想了解lab如何完成，请往下看。

下面是逐级复杂的三张相互关联的图

SEQ的抽象视图如下所示

![SEQ](https://s2.loli.net/2025/09/27/1sYpTiumqnoDZF8.png)

SEQ的顺序硬件实现如下所示

![SEQ的顺序硬件实现](https://s2.loli.net/2025/09/27/A8PWBUQwTgtk95J.png)

这里的简化CPU架构图如下图所示

![CPU Architecture](https://s2.loli.net/2025/09/27/jbWuU4BYyg8LTvh.png)

通常一个指令的执行分为以下**五个阶段**。

1. 取址（Fetch）：根据PC的值读入指令字节。每一条指令长短不一，但都规范化为几个结构（在Y86中 RISA架构处理器）

2. 译码（Decode）：在这个阶段，处理器解码指令以确定其操作类型以及操作数的来源。译码的目的是解析指令的各个字段，比如操作码、寄存器操作数等，确保处理器能够理解并准备好执行指令。

3. 执行（Execute）：在这个阶段，处理器执行指令的运算部分。对于算术运算，执行阶段会使用算术逻辑单元（ALU）进行计算；对于跳转指令，计算新的程序计数器值。

4. 访存（Memory Access）：如果指令需要访问内存（如加载或存储指令），则在这个阶段处理内存操作。对于 load 指令，数据从内存加载到寄存器；对于 store 指令，数据从寄存器写入内存。

5. 写回（Writeback）：在写回阶段，执行结果被写回到寄存器或内存。比如，在计算完成后，将计算结果写回寄存器。

这里的五个阶段与MIPS（Microprocessor without Interlocked Pipeline Stages） 是一种基于 RISC（精简指令集计算机） 设计的处理器架构的五个流程保持一致，但在一些地方，会省略掉`Memory Access`的过程，将其并入Execute。

如果你对**现代微处理器**的机制并不熟悉，例如不理解ILP，分支预测等，建议阅读<https://www.lighterra.com/papers/modernmicroprocessors/>

> 这里插叙一下`clock`与`pipeline parallel`的机制
>
> ![img](https://s2.loli.net/2025/09/27/AJy8am4MXcRHKDE.png)
>
> ![img](https://s2.loli.net/2025/09/27/JkTI6NgZG7USVWY.png)
>
> Now the processor is completing 1 instruction every cycle (CPI = 1). This is a four-fold speedup without changing the clock speed at all.
>
> From the hardware point of view, each pipeline stage consists of some combinatorial logic and possibly access to a register set and/or some form of high-speed cache memory. The pipeline stages are separated by latches. A common clock signal synchronizes the latches between each stage, so that all the latches capture the results produced by the pipeline stages at the same time. In effect, the clock "pumps" instructions down the pipeline.\
>
> 实际上，时钟将指令“泵入”管道。
>
> 通过更加细化不同执行阶段
>
> ![img](https://s2.loli.net/2025/09/27/gIJ3HwzkFBrf1qD.png)
>
> 实际上可以构建更高的`clock speeds`但是这样降低对数据、控制依赖指令的兼容程度并会增大指令延迟
>
> 在superscalar处理器上，instruction flow belike
>
> ![img](https://s2.loli.net/2025/09/27/gkwimpjxCAobKXQ.png)
>
> 今天的所有处理器几乎都集成了上面两种技术，得到的instruction flow belike,现在简单的将`superpipeline`和`superscalar`称为`superscalar`
>
> ![img](https://s2.loli.net/2025/09/27/tk2QfYmZyzeA4p9.png)

对于一条指令而言，通用执行数据流图如下所示：

![opt](https://s2.loli.net/2025/09/27/dZfxvXYDnCJuS7B.png)

可以推测出iaddq的指令流程应该如下所示

``` text
#  iaddq V,rB
#phaseFetch
# icode:ifun <-- M1[PC]
# rB <-- M1[PC+1]
# valC <-- M8[PC+2]
# valP <-- PC+10
#phaseDecode
# valB <-- R[rB]
#phaseExecute
# valE <-- valC+valB
# set CC
#phaseMemory
# 
#phaseWriteBack
# R[rB] <-- valE
#phaseUpdatePC
# PC <-- valP
```

接下来所有工具文件以及修改的源代码文件都在**lab文件`Architecture-Lab/sim/seq`**文件夹中。

在修改完`seq-full.hcl`文件后，我们需要在目录`Architecture-Lab/sim/seq`下使用其中的makefile文件编译该新的处理器模拟程序，其中模拟程序可以选择tty模式和gui模式，gui模式为makefile文件设置的默认模式，gui模式可以进行单步调试，但需要先安装tty等依赖包，所以我选的是tty模式，可以直接编译该程序而不需要安装依赖包。
改为tty模式的操作就是打开makefile文件并注释掉其中的GUIMODE、TKLIBS和TKINC变量。
在终端程序的`Architecture-Lab/sim/seq`目录下输入指令make VERSION=full来编译新的处理器模拟程序。

编译出了新的处理器模拟程序后，我们需要两轮的漏洞测试（不会测试新加的指令），测试新加的指令会不会使其处理器模拟程序产生漏洞，在终端程序的`Architecture-Lab/sim/seq`目录下先后输入指令`./ssim -t ../y86-code/asumi.yo`和`cd ../y86-code; make testssim`来进行小型和大型漏洞测试。
漏洞测试都通过后就可以测试新加指令的逻辑问题了，在终端程序的`Architecture-Lab/sim/seq`目录下先后输入指令`cd ../ptest; make SIM=../seq/ssim TFLAGS=-i`来进行。
只有这三个测试全部通过才算完成该关。

接下来修改`seq-full.hcl`文件，初见这个文件好像很复杂，实际上理解了程序在处理器中执行的四个基本过程、寄存器与内存之间的交互根据注释还是能够理解整个文件的。

```hcl
## Your task is to implement the iaddq instruction
## The file contains a declaration of the icodes
## for iaddq (IIADDQ)
## Your job is to add the rest of the logic to make it work
```

从这个文件开头的注释中我们可以发现，所有的命令例如`addq`,`mrmovq`...在hcl都有一个由全大写字母组成的类宏定义名称，通过该名称指代我们涉及的命令。

跳过一些不允许我们更改的hcl代码。然后会注意到这样的一个开头

```hcl
####################################################################
#    Control Signal Definitions.                                   #
####################################################################

################ Fetch Stage     ###################################
```

可以发现`Control Signal Definitions`正是定义命令的区域，其中`Fetch Stage`正是命令定义的第一个阶段。然后转移注意力到第一个定义。

```hcl
# Determine instruction code
word icode = [
	imem_error: INOP;
	1: imem_icode;		# Default: get from instruction memory
];

# Determine instruction function
word ifun = [
	imem_error: FNONE;
	1: imem_ifun;		# Default: get from instruction memory
];
```

一个列表一样的结构分割了一些命令，典型的是icode中的INOP，在书中有提到1在hcl中是默认值。可以注意到imem_code, imem_ifun应是直接从指令内存中提取的变量，INOP由于是空指令不执行任何命令被放在了imem_error位置，而ifun则是FNONE类似一个空指令的表达。


```hcl
bool instr_valid = icode in 
	{ INOP, IHALT, IRRMOVQ, IIRMOVQ, IRMMOVQ, IMRMOVQ,
	       IOPQ, IJXX, ICALL, IRET, IPUSHQ, IPOPQ, IIADDQ };

# Does fetched instruction require a regid byte?
bool need_regids =
	icode in { IRRMOVQ, IOPQ, IPUSHQ, IPOPQ, 
		     IIRMOVQ, IRMMOVQ, IMRMOVQ, IIADDQ };

# Does fetched instruction require a constant word?
bool need_valC =
	icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX, ICALL, IIADDQ };

```

这里通过类似python中集合的操作在指定bool值，此时可以加上IIADDQ。

...

---

在照猫画虎的根据`iaddq`的指令流程设计完所有阶段后即可开始测试，这里贴一段原文

![test](https://s2.loli.net/2025/10/10/iVRMwxhl7O9Kvjg.png)

在这里有两条指令可能由于年代原因出现错误，分别关于`tk`\\`tcl`, `gui forwarding`
```sh
make VERSION=full
./sim -g ../y86-code/asumi.yo
```

其中，根据[GUI问题部分](#gui-forwarding-problem)，解决一些问题后，应该在`./sim -g ../y86-code/asumi.yo`命令下可见如下界面

![gui](https://s2.loli.net/2025/10/10/MUbyQrIG3jCs9za.png)

网络上很多blog都没有给出这个界面，感觉可能是因为他们一遍就过了，没有用到调试或者懒得讲图形化界面。

根据这里的可视化样例重新理解一下整个`sequence`流程。

首先回顾一下这里的asumi.yo，整个程序非常简单就是使用iaddq重构了数组求和的算法。

然后看一下另外一个比较复杂的模型界面

![seq-gui](https://s2.loli.net/2025/10/10/c61dSMzalIEVhtw.png)

在这个界面中模拟了程序在五个阶段中的运行过程。几个控制按钮基本对应gdb的控制风格，主要用step单步运行就好了。

![asumi](https://s2.loli.net/2025/10/10/rWKGO7g1FbRSdoB.png)

一般不会有什么问题。这里简单看一下，如果有错误，进行修改。

然后通过`(cd ../y86-code/; make testssim)`命令进行一个简单正确性测试测试。
出现下面的终端输出就是正常运行了。

```sh
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/seq$ (cd ../y86-code/; make testssim)
Makefile:42: warning: ignoring prerequisites on suffix rule definition
Makefile:45: warning: ignoring prerequisites on suffix rule definition
Makefile:48: warning: ignoring prerequisites on suffix rule definition
Makefile:51: warning: ignoring prerequisites on suffix rule definition
../seq/ssim -t asum.yo > asum.seq
../seq/ssim -t asumr.yo > asumr.seq
../seq/ssim -t cjr.yo > cjr.seq
../seq/ssim -t j-cc.yo > j-cc.seq
../seq/ssim -t poptest.yo > poptest.seq
../seq/ssim -t pushquestion.yo > pushquestion.seq
../seq/ssim -t pushtest.yo > pushtest.seq
../seq/ssim -t prog1.yo > prog1.seq
../seq/ssim -t prog2.yo > prog2.seq
../seq/ssim -t prog3.yo > prog3.seq
../seq/ssim -t prog4.yo > prog4.seq
../seq/ssim -t prog5.yo > prog5.seq
../seq/ssim -t prog6.yo > prog6.seq
../seq/ssim -t prog7.yo > prog7.seq
../seq/ssim -t prog8.yo > prog8.seq
../seq/ssim -t ret-hazard.yo > ret-hazard.seq
grep "ISA Check" *.seq
asum.seq:ISA Check Succeeds
asumr.seq:ISA Check Succeeds
cjr.seq:ISA Check Succeeds
j-cc.seq:ISA Check Succeeds
poptest.seq:ISA Check Succeeds
prog1.seq:ISA Check Succeeds
prog2.seq:ISA Check Succeeds
prog3.seq:ISA Check Succeeds
prog4.seq:ISA Check Succeeds
prog5.seq:ISA Check Succeeds
prog6.seq:ISA Check Succeeds
prog7.seq:ISA Check Succeeds
prog8.seq:ISA Check Succeeds
pushquestion.seq:ISA Check Succeeds
pushtest.seq:ISA Check Succeeds
ret-hazard.seq:ISA Check Succeeds
rm asum.seq asumr.seq cjr.seq j-cc.seq poptest.seq pushquestion.seq pushtest.seq prog1.seq prog2.seq prog3.seq prog4.seq prog5.seq prog6.seq prog7.seq prog8.seq ret-hazard.seq
```

再通过`(cd ../ptest; make SIM=../seq/ssim)`进行回归测试，测试在添加`iaddq`时，其他指令是否会受它的影响。

```sh
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/seq$ (cd ../ptest; make SIM=../seq/ssim)
./optest.pl -s ../seq/ssim 
Simulating with ../seq/ssim
  All 49 ISA Checks Succeed
./jtest.pl -s ../seq/ssim 
Simulating with ../seq/ssim
  All 64 ISA Checks Succeed
./ctest.pl -s ../seq/ssim 
Simulating with ../seq/ssim
  All 22 ISA Checks Succeed
./htest.pl -s ../seq/ssim 
Simulating with ../seq/ssim
  All 600 ISA Checks Succeed
```


做到这里PartB也就结束了，接下来是比较困难的PartC

### Part B 一些附图

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

### GUI Forwarding Problem

linux中GUI对可视化系统（如windows）的转发通常涉及一些库（如tk,tcl)，以及一些协议（如X11)。
这里以MobaXterm终端转发Ubuntu24.04为例。

由于tcl，tk在Ubuntu18中进行过一次更新，从8.5升级到了8.6，因此，原本的Makefile是无法直接被使用的

```sh
# 在/sim/seq中执行下面这一条指令时会出现报错
make VERSION=full
```

这时需要修改Makefile文件对应位置，并修改部分被弃用的函数代码
```makefile
# Modify the following line so that gcc can find the tcl.h and tk.h
# header files on your system. Comment this out if you don't have
# Tcl/Tk.

TKINC=-isystem /usr/include/tcl8.6

# Modify these two lines to choose your compiler and compile time
# flags.

CC=gcc
CFLAGS=-Wall -O2 -DUSE_INTERP_RESULT
```
在这段位置修改`sim/seq/Makefile`文件

```c
// 因为tcl8.6,tk8.6在sunos上编译时会定义这个函数，而matherr在math.h中被声明为weak符号
// 但在C17标准中，matherr已被弃用且不再推荐使用，因此这里注释掉相关代码以避免冲突
// extern int matherr();
// int *tclDummyMathPtr = (int *) matherr;
```
并在源代码中注释掉所有用到matherr这个函数定义的地方,涉及两个源代码`psim.c`以及`ssim.c`。

通过这两种方式，`make VERSION=full`应该可以正常编译了，但是当尝试使用mobaXterm进行转发GUI时可能还是会出现一些问题，有关安全性验证。这里给出我用的命令以及chat的记录

```sh
# 注意在MobaXterm中手动启用X11转发

# 查看当前设置
grep -i 'X11Forwarding\|X11UseLocalhost' /etc/ssh/sshd_config || true

# 如需启用（会覆盖注释/多个条目），运行：
sudo sed -i 's/^#\?\s*X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?\s*X11UseLocalhost.*/X11UseLocalhost yes/' /etc/ssh/sshd_config

# 重启 sshd（注意：会断开当前 SSH 会话）
sudo systemctl restart sshd
# 手动强制重启终端
```

[chat回复](https://chatgpt.com/share/68e900b9-341c-8010-83c7-723566e9c8c5)

## REF

1. <https://csapp.cs.cmu.edu/3e/archlab.pdf>
2. <https://zhuanlan.zhihu.com/p/480380496>
3. <https://bobokick.github.io/showPage/CSAPP_Labs/4_ArchitectureLab/readme.html>
4. <https://jarenl.com/index.php/2025/02/24/csapp_chp4/>
5. <https://www.lighterra.com/papers/modernmicroprocessors/>
