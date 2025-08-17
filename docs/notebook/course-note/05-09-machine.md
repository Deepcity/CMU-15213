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

### Memory Layout

![x86 linux memory layout](https://s2.loli.net/2025/08/17/LoAWNzSugmFwsEr.png)
![memory allocation example](https://s2.loli.net/2025/08/17/JwDTNuXptZPWbGL.png)
![x86 example address](https://s2.loli.net/2025/08/17/v8gbmptXBiHWesJ.png)

### Buffer Overflow

![referencing bug example](https://s2.loli.net/2025/08/17/G3bONpCZ98cUEfu.png)
![referencing bug example explanation](https://s2.loli.net/2025/08/17/R8z7iy9VxYBUhLt.png)

随后CMU给出了一个buffer error的例子，基本原理是调用的函数不会检查buffer的大小，在使用的过程中，对buffe的调用过于arbitrary。
以至于出现了segment fault。同时展示了segment fault可能导致的三种情况，正常运行，报错，以及非预期行为。

![string lib bug](https://s2.loli.net/2025/08/17/uPGb5LRFceJrqsZ.png)
![vulnerable buffer code](https://s2.loli.net/2025/08/17/ZdITbDeNLnjyp2v.png)
注意到这里的buf为4个字节，也就是24bit位，但下面的输入字符却有足足24个字符，并且观察disassemble,栈也减少了足足24个字节的stack frame。
可见程序多给出了20个字节的空间。原因可能是:
- 局部变量 buf[4] (4B)
- padding (4B, 补齐到8字节)
- 额外 padding (8B 或更多) 

注意这里的红色标记，标志着返回时跳转的地址值。理论上可以通过输入不同大小以及值的字符串修改这里的值到任意地方。
在看似运行的程序中可能调用了未知的函数，导致不在预期中的行为发生。

![buffer overflow disassembly](https://s2.loli.net/2025/08/17/7pZGIJkriKLDtNu.png)
![before call to gets](https://s2.loli.net/2025/08/17/x83v4VG52DJrqHC.png)
![example1](https://s2.loli.net/2025/08/17/aJQqSVxhpCXlR1m.png)
![example2](https://s2.loli.net/2025/08/17/UKDTlpG2vQ1nBFr.png)
![example4](https://s2.loli.net/2025/08/17/ozdYZ3P2FUf7Blg.png)

利用这种方式可以执行代码注入攻击，如下图

![code injection attacks](https://s2.loli.net/2025/08/17/U9OzpwntFfKGdN2.png)

通过gets函数的漏洞修改返回值以达到执行泄露代码的目的。

![buffer overflows summary](https://s2.loli.net/2025/08/17/41rdVewaKLHqsOx.png)
下面是一些真实的例子：
1. morris swarm

	开发者是MIT S6.824的分布式系统课程老师，利用finger调用的gets()函数去调用泄露代码，构建root shell与攻击者电脑的直接TCP链接。
![internet worm](https://s2.loli.net/2025/08/17/yxLiapKZkNfJWPn.png)

2. IM War

	如果说 上一个是因为著名，那么这一个就是因为有趣。

	基本上是AOL与Microsoft的战争。微软通过逆向AOL的聊天协议，帮助自家通信软件MSN Message登录到AIM（AOL的通讯服务），也就是说local code是微软，but remote server是AOL。使得MSN Message具有与AIM Client沟通的能力。 同时降低了巨额成本。

	然后AOL通过自己代码中的漏洞，buffer overflow attack检查Client代码是AOL还是Microsoft。拒绝MS的链接。

	最终被自称 Phil Bucking 的人披露，这封邮件经确认是在微软内部发出的。

![IM War](https://s2.loli.net/2025/08/17/JGBqixA4ZvSU9LO.png)

difference between worms and viruses.

![aside](https://s2.loli.net/2025/08/17/liI1T2pnqkPFm67.png)

最后聊一下如何Protect code from `buffer overflow attack`。

1. 通过随机化缓冲区地址，避免`buffer overflow  attack`
![protect1](https://s2.loli.net/2025/08/17/DoRWupA7CH8OXUm.png)
2. 通过添加执行权限，注入代码直接不能被执行
![protect2](https://s2.loli.net/2025/08/17/Q4eHv5MOigYRSt9.png)
![protect2](https://s2.loli.net/2025/08/17/fzPg6qXU2Y3hNye.png)
3. Stack Canaries： 金丝雀

	这是最终的想法，被称为“金丝雀”（canary）。这个名字来源于以前的矿井工人下井时会带一个装有金丝雀的鸟笼，金丝雀对毒性非常敏感，如果井下有甲烷，工人看到金丝雀停止鸣叫或死亡，就会撤出。

	在 rsp+8 处存放了一个 8 字节的金丝雀值，这个值是从一个特殊的寄存器获取到的。fs 是一个为原始的 8086 设计的一个寄存器，总之金丝雀值就是某块内存中的值，而你不能通过其它办法访问它。**这块内存值就是金丝雀**

	**canary 值每次执行都不一样，且存放 canary 值的那段内存标记成只读**，黑客不能篡改。
![stack canaries](https://s2.loli.net/2025/08/17/OPx67qT3VBUvsbK.png)
![buffer disassembly](https://s2.loli.net/2025/08/17/TsRwonNPlrEGyOp.png)
![setting up canary](https://s2.loli.net/2025/08/17/vTCtB2VknNZhmSb.png)
![checking canary](https://s2.loli.net/2025/08/17/gHoE8CAtRh3lw6U.png)

除了 canary 机制，其它两种方法（随机栈的位置，将栈标记为不可执行）都可以通过面向返回编程破解。策略就是即使我不知道栈在哪里，但我知道代码存在哪里，如果我知道代码存在哪里，我就可以把它组合成我的代码。

面向返回编程的思想就是找到 Gadgets，Gadgets 代表部分可执行程序的字节序列，最后一个字节为 c3（针对 x86），代表 IA32 和 x64 的返回指令。

理解这部分的实现方式，首先要深刻了解`call`，`ret`的具体实现方式，通过构造一个栈序列，利用原有代码的执行顺序执行，将注入代码分散到原有代码中。

定义原有代码中的注入顺序地址为Gadget

![return-oriented programming](https://s2.loli.net/2025/08/17/cPwCDHirBLpayMg.png)

以下是两个gatget examples
分别执行功能
rax <- rdi+rdx
rax <- rdi
![gadget example#1](https://s2.loli.net/2025/08/17/rtZaOCX7pJb5m3z.png)
![gadget example#2](https://s2.loli.net/2025/08/17/21elZOqjgH45iVP.png)
以下是构造的gadgets序列，通过ret函数实现在不同note中的跳转
![ROP Execution](https://s2.loli.net/2025/08/17/LeIcoKz6NwG35Jy.png)

### Union

Union and Struct 这两者有很多相似之处，也存在不同

- 分配内存遵循最大的一个元素
- 所有field共享同一片空间，即任何时刻只有一个值是有效的。

> 如果你存了 v=10.00，再存 c, v的值就被覆盖了。

> field是什么?
> 
> field在c中指一个结构体或联合体中的成员变量
> 
> field 即字段，成员字段。

struct
- 所有 field 各占独立空间
- struct 的总大小 ≥ 所有 field 大小之和（还要考虑对齐 padding）。
- 每个成员都能同时存在。

![Union and Struct](https://s2.loli.net/2025/08/17/c3LvgrQ8C9fNoK6.png)

将union作为bit pattern使用
![access bit patterns](https://s2.loli.net/2025/08/17/VPUFsa5myQHrKJx.png)
但这样的使用方式可能会造成字典序的问题
![byte ordering](https://s2.loli.net/2025/08/17/3vcQkrnR8zHAOKV.png)

c中的数据结构总结如下

![compound type in C](https://s2.loli.net/2025/08/17/oMD5uQY3Brt2Zsm.png)

***ALL OVER!!!***

## REF
1. https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/05-machine-basics.pdf#page=2.00
2. https://zhuanlan.zhihu.com/p/659318987