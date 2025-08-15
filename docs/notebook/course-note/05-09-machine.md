# Machine­‐Level Programming

***声明：***[bomblog](../lab-note/bomblog.md) 写于本文档之前。因此，一些实用技巧可能记录在 [bomblog](../lab-note/bomblog.md) 中，但未记录在本文档中。但我保证本文档是 bomblog 的知识超集。

***Notify:*** [bomblog](../lab-note/bomblog.md) writed before this document. So some practical tips may be recorded in [bomblog](../lab-note/bomblog.md) but not in this document. but I guarantee this document is knowledges' super-set of bomblog.

In CMU schedule [15-213：计算机系统概论/2015年秋季课程 --- 15-213: Introduction to Computer Systems / Schedule Fall 2015](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/schedule.html), this field is divided into five courses. There are:
1. Basics
2. Program Control
3. Procedures
4. Data
5. Advanced

它们的时间跨度横越两个实验，共计15天的时间。不过在这个文档里，他们都被融合在一起。

Their time span extends across two experiments "Bomb Lab and Attack Lab", covering a total of 15 days. However, within this document, they have been integrated into a unified framework.

## Basic

### History

Basicly, it's a history of love and hate between "AMD yes!!!" and "Fuck you Intel".

Simplify some architecture of compute, such as IA32, x86-64(amd64) and so on.

### C, assembly, machine code

***MOSTLY LREANED***

Let's see some beautiful illustraction.

![campile process of C](https://s2.loli.net/2025/08/14/18Z3wAXDMhlVjT5.png)

![assembly](https://s2.loli.net/2025/08/14/UxdT29wFLHkRs3W.png)

![machine instruction](https://s2.loli.net/2025/08/14/EOMBib3yeslqcfZ.png)

一种简单的反汇编方式`objdump -d $file_name`
![disassembling](https://s2.loli.net/2025/08/14/FTgjNQ7WHzyB6D4.png)

这个过程也可以用一个更好的工具`cgdb`
![disassemble with gdb](https://s2.loli.net/2025/08/14/NGize89gwkYFbUM.png)

Certainly, some processes are forbidden from disassemble, but technically, "Anything that can be interpreted as executable code".

### Registers

仙之人兮列如麻
![registers](https://s2.loli.net/2025/08/14/vekCGRgQj7ApcYF.png)
![IA32 Reg](https://s2.loli.net/2025/08/14/AJa7pfsBPwRE53U.png)
一些实用的使用技巧参见[BombLab regs-ref](../lab-note/bomblog.md#regs-ref)

使用数据的方式
![using data](https://s2.loli.net/2025/08/14/6YZOPFVHl1bwye2.png)
![movq](https://s2.loli.net/2025/08/14/FC1GM34QB7qTmyR.png)
这里基本涉及了寄存器，立即数的取值和取地址，解释地址等操作。
在gdb相关操作中还涉及一些实用的指令`x/`与`p/`用于查看值。详见一些实用的使用技巧参见[BombLab regs-ref](../lab-note/bomblog.md#gdb-ref)
![memory address mode](https://s2.loli.net/2025/08/15/x1kPjyobu3nNL6B.png)
这里很重要，形成本能得

随后举了一个经典得swap undestanding得example，jump over

然后是一个复杂使用逻辑`(, , )`与leaq
![complete addr](https://s2.loli.net/2025/08/15/KQVftmc8d7u2CZb.png)
![leaq](https://s2.loli.net/2025/08/15/wqG139B2QnlmdSb.png)

arithmetic expression example
![aee](https://s2.loli.net/2025/08/15/oHfdVvSZTQ3eira.png)

其实这里的所有commands,最后都融为一个leaq,只要弄懂这个的所有用法，其他都是显然的

## Control

### Control: Condition codes

一般汇编课程中会提到Flag Register,这个特殊的标志寄存器具有16位，每一位都是一个Flag。不过这里似乎没有提到，我觉得也是正常的，毕竟时代在发展。
可能一个16位的FLAG寄存器今天还存在，明天就会改变，但CF,ZF,SF,OF这些概念还是存在的。

![cmpq](https://s2.loli.net/2025/08/15/2MTjIfFsePKXBJd.png)
![testq](https://s2.loli.net/2025/08/15/gRNwXaFmVJZYGIO.png)
![setq](https://s2.loli.net/2025/08/15/RjDbtK5Cr9IXTqn.png)

### Control: Conditional branch

这里最好去找个程序objdump一下，特别是conditional branch多的，会在程序后面看到很多设置rax的类似语句和jmp语句。
这实际上是一种规范化的归一机制。

![jump](https://s2.loli.net/2025/08/15/IUQwFlxOjBTMSh7.png)

### Control: Loop

Easy! 稍微注意一下嵌套循环就可以，和c一样，最重要的是边界条件，即循环迭代器和设定的Condition，以及Step


jump over

### Control: Switch Statment

最复杂的一部分，但其实也很简单，难点在于可能用到了一些全局变量，注意查看对应立即数的位置的数组即可，最难的点是实践。
详情查看[bomblog phase4-5-stages](../lab-note/bomblog.md#phase_4-stage)

![switch](https://s2.loli.net/2025/08/15/kjKsU3GcMl6dhDo.png)

jump over

## Procedures

Control, Data, Memory Management and instructions implemention 
![procedures](https://s2.loli.net/2025/08/15/mzaq9W61TrIDZGX.png)

### Structure

The most important Structure **x86-­‐64 Stack**
![stack](https://s2.loli.net/2025/08/15/4lw8xhtLXp73AuJ.png)

### Calling Conventions

**Passing control**
![passing control](https://s2.loli.net/2025/08/15/k4PF1dVBpwTNmu9.png)

**Control flow example**
![cfe1](https://s2.loli.net/2025/08/15/7J6M1DZ3QfELXbN.png)
![cfe2](https://s2.loli.net/2025/08/15/gNHvRV7m5bwPE38.png)
![cfe3](https://s2.loli.net/2025/08/15/zwgNUlvXujrJbTO.png)
![cfe4](https://s2.loli.net/2025/08/15/QD4t92THR3ksMGh.png)

**Managing local data**

这里的6 arguments regs 是按照顺序排的，一般调用函数**整个过程**中是依次调用他们的，有些时候还会调用到r12,r13,14...
有些地方会说默认的argument regs不止这6个,这种说法一般认为不标准，超过6个应该使用栈上传参
![data flow](https://s2.loli.net/2025/08/15/gDYaksTIVuX5ztM.png)

![stack frames](https://s2.loli.net/2025/08/15/dVjKWhRIaQ8z1Ub.png)
![ex](https://s2.loli.net/2025/08/15/2dcnmBAZk9wsQEr.png)

这个有个印象即可
![linux stack frame](https://s2.loli.net/2025/08/15/ankgw86x4QiqMOr.png)

这里其实漏了两个caller-saved, `rbp`和 `rbx`,后面补上了
![register usage](https://s2.loli.net/2025/08/15/84TQMXcNrbJaVi3.png)
![register usage2](https://s2.loli.net/2025/08/15/EL29gXNbqjWnVCK.png)

### Illustration of Recursion

这里bomblab没有用上，还是比较好理解的
![recursive funcion](https://s2.loli.net/2025/08/15/MXYViUI7PnyEkZT.png)


### x86-64 Summary

![procedure summary](https://s2.loli.net/2025/08/15/wxUy5bR6CourLBE.png)

## Data

这一部分针对bomblab的特征很强，且部分内容专一与特定领域，例如matrix, linknode。
唯一需要注意的feature是系统的Aligement特征，涉及到空间和时间优化。稍微过一遍ppt

### Array

![array allocation](https://s2.loli.net/2025/08/15/6Tk7APmsMGZR2KC.png)
![array allocation use](https://s2.loli.net/2025/08/15/TlaAsfrjGYC7QeW.png)
![multidimensional array](https://s2.loli.net/2025/08/15/LtVuTK3hPcCQDym.png)
![multidimensional array use](https://s2.loli.net/2025/08/15/nEpzuwJCQymN21k.png)
![matric access](https://s2.loli.net/2025/08/15/NFzhiqUf2AVRjxt.png)

### Struct

![struct](https://s2.loli.net/2025/08/15/oi3ps9f5Pt2U8lb.png)
![node link loop](https://s2.loli.net/2025/08/15/SIftE1OdjVTv3Fg.png)
![Alignment](https://s2.loli.net/2025/08/15/t1iVue2r9pRN6CQ.png)


### Floating Point

FP，在国内教学中因为不能出很好的题通常被忽略。但还是肥肠重要（尤其对于目前的AI优化）。

![FP bacgroud](https://s2.loli.net/2025/08/15/oJushWjtlCAURb1.png)
![XMM Registers](https://s2.loli.net/2025/08/15/zvx6Ju4Q3Vos1OE.png)
喜欢CMU的超前教育吗？冲程！
scalar calcute and SIMD Opeartions，这TM是本科大一！
![scalar& SIMD Operations](https://s2.loli.net/2025/08/15/dg2CXUwo8lm3EOJ.png)
![FP basic](https://s2.loli.net/2025/08/15/hWOBaoYsge34ilp.png)
![FP memory](C:/Users/Deepcity/AppData/Roaming/Typora/typora-user-images/image-20250815123545406.png)
![Summary](https://s2.loli.net/2025/08/15/vSfEiYXthJBIZuw.png)

然后为了让学生懂得Aligement优化，CMU给出了一个Understanding pointers and array联系，OHHH, CMU!
冲程！

一把好看图，多少研究生
![pointer](https://s2.loli.net/2025/08/15/aJwU7HtdD3MeBAF.png)

## Advanced Topics


## REF
1. https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/05-machine-basics.pdf#page=2.00