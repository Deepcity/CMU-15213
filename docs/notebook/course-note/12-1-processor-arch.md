# 现代微处理器架构

## Motivation

因CS:APP第四章中部分未学习知识点以及[现代微处理器 - 90 分钟指南！ --- Modern Microprocessors - A 90-Minute Guide!](<https://www.lighterra.com/papers/modernmicroprocessors/)中的归纳总结构建的特殊章节>

## Key word

-

## Start with Super ... - ILP并行策略

> 以下来自[lab-note/architecturelog](../lab-note/architecturelog.md#part-b)
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

现代处理器中的并行ILP因为用上了`superpipeline`, `superscalar`等优化方式，构建了统称`superscalar`的并行策略，其instruction flow如下所示：

![img](https://s2.loli.net/2025/09/27/tk2QfYmZyzeA4p9.png)

而在GPU中，使用了VLIW（ very long instruction word）这样的简化调度逻辑的类`superscalar`处理逻辑，尤其是在编译器的角度下。

![img](https://s2.loli.net/2025/09/27/cIhK5XmtyexAQkf.png)

## Branch prediction

由于前面提到的Superscalar机制，当我们碰到如下分支时：

```c
if (a > 7) {
    b = c;
} else {
    b = d;
}
```

编译汇编代码如下

```assembly
    cmp a, 7    ; a > 7 ?
    ble L1
    mov c, b    ; b = c
    br L2
L1: mov d, b    ; b = d
L2: ...
```

当处理器执行到if时，它必须要开始加载（fetch\decode）接下来要执行的几条指令。此时需要展开预测操作，失败则损失几个时钟周期。

> 简单统计数据：现代处理器平均每六条指令就会碰到一条分支

有两种显然易见的方式：

- Static branch prediction: 通过编译器指定应该预测哪一条路径。这种方式对循环非常有效，对其他分支则相对无用。
- The guess at runtime: 使用片上分支预测表来完成的运行时进行猜测。该表包含最近分支的地址和指示每个分支是否上次被占用的位。实际上，大多数处理器实际上使用两位，因此单个未发生的事件不会逆转通常采用的预测（对于循环边缘很重要）。当然，这个动态分支预测表占用了处理器芯片上的宝贵空间，但分支预测非常重要，非常值得。

> 分支预测对于处理器而言嫉妒重要，例如在奔腾CPU中，即使预测成功率高达90%，**误预测惩罚**仍然会导致高达30%的性能损失
>
> btw，这与cache的未击中带来的大量性能开销是一个逻辑
>
> 现代处理器将越来越多的硬件用于分支预测，以试图进一步提高预测精度并降低成本。许多分支**不仅单独记录每个分支的方向**，而且**记录在导致它的几个分支的上下文中**，这称为**两级自适应预测变量(two-level adaptive predictor)**。有些**保留更全局的分支历史记录，而不是为每个单独的分支单独记录**，以尝试检测分支之间的任何相关性，即使它们在代码中相对较远。这称为 **gshare 或 gselect 预测器**。最先进的现代处理器通常**会实现多个分支预测器**，并根据哪个预测器似乎最适合每个单独的分支在它们之间进行选择！
>
> 简单统计学数据：现代处理器通常能达到约**95%的预测准确率**
>
> 尽管如此，提升预测准确率仍然十分重要，原因：The bottom line is simple – very deep pipelines naturally suffer from diminishing returns, because the deeper the pipeline, the further into the future you must try to predict, the more likely you'll be wrong, and the greater the mispredict penalty when you are. **性能损失与管道深度有关**

## Eliminating Branches with Predication 消除分支

即使提升预测准确率，我们仍然能通过消除分支来提升程序运行性能。

例如对于上面提到的例子,考虑以下汇编码

```assmebly
cmp a, 7       ; a > 7 ?
mov c, b       ; b = c
cmovle d, b    ; if le, then b = d
```

即通过`cmovle`消除了分支，此外，这里的排序也很有趣，通过始终执行`mov c, b`,这里可以并行执行第一、二条汇编代码，加速了50%。

然而，这里的分支块相对较小，当分支块较大时，需要增加许多predicated instruction，需要平衡这些命令的额外开销和误预测分支开销是相对困难的。

> 历史小知识：对于arm架构而言，它是第一个具有完全 predicated instruction set的架构。

## Instruction Scheduling, Register Renaming & OOO 指令调度、寄存器重命名和 OOO

这一节的motivation主要来自于，既然分支，长指令会带来大量`pipeline bubble`，那么为何不用这些气泡去做其他的工作。为此必须对程序中的指令进行重排列。

有两种方式可以做到这一点

- One approach is to do the reordering in hardware at runtime. Doing dynamic instruction scheduling (reordering) in the processor means the dispatch logic must be enhanced to look at groups of instructions and dispatch them out of order as best it can to use the processor's functional units. Not surprisingly, this is called out-of-order execution, or just OOO for short (sometimes written OoO or OOE). 通过运行时在硬件中重新排序。、
- Another approach to the whole problem is to have the compiler optimize the code by rearranging the instructions. This is called static, or compile-time, instruction scheduling. The rearranged instruction stream can then be fed to a processor with simpler in-order multiple-issue logic, relying on the compiler to "spoon feed" the processor with the best instruction stream. 通过编译器重新排列指令来优化代码，英文原文有个很有趣的比喻 "spoon feed" 勺子喂食的指令流。

这两种方式并不是互斥，且没有任意一种方式是完美的。接下俩分开讲一讲这两种方案。

对于第一种方式而言，这要求处理器“记住”不同指令之间的依赖关系。通过重新命名的寄存器可以简化这样的过程，其处理逻辑是：

- 寄存器重命名的解决方案：

    寄存器重命名的核心思想是将指令中使用的程序寄存器（例如 R1, R2）映射到一组物理寄存器上。这是通过使用一张寄存器重命名表来实现的。寄存器重命名的目的是消除指令间在寄存器上的依赖，避免因执行顺序的不同而造成错误。

- 如何工作：

    以一个存储指令（store）和加载指令（load）为例：

    假设程序中有这样两条指令：

    store R1, [mem]（将寄存器 R1 的值存储到内存）

    load R1, [mem]（将内存中的值加载到寄存器 R1）

    如果它们被顺序执行，那么第二条 load 指令会覆盖掉 store 指令的结果。但如果这两条指令的执行顺序被打乱，依赖关系就会发生错误，导致错误的结果。

    为了解决这个问题，处理器并不直接使用程序寄存器（例如 R1）进行存储和加载，而是通过物理寄存器来管理。例如，R1 在实际执行时会被映射到不同的物理寄存器 P1 和 P2。这意味着：

    store 操作将 R1 映射到物理寄存器 P1，并存储到内存。

    load 操作则将其加载到不同的物理寄存器 P2 中。

- 并行执行：

    通过将指令映射到不同的物理寄存器，处理器可以并行执行这些指令而不会产生依赖冲突。

    这样，即使指令的执行顺序被打乱，处理器依然可以保证每个指令的执行是正确的，因为每条指令有自己独立的物理寄存器。

- 优劣

    这种方式有些像线段树中的`lazy tag`。

    由于这些额外设计的模块通常一直处于工作状态，带来了设计、面积、功耗上的开销，但这些设计通常可以直接提升处理器的部分性能。

对于第二种方式而言

> The compiler approach also has some other advantages over OOO hardware – it can see further down the program than the hardware, and it can speculate down multiple paths rather than just one, which is a big issue if branches are unpredictable. On the other hand, a compiler can't be expected to be psychic, so it can't necessarily get everything perfect all the time. Without OOO hardware, the pipeline will stall when the compiler fails to predict something like a cache miss.

它通过编译器“spoon feed”，可以预见更多不同的分支。

> 大多数早期的超标量都是按顺序设计的（SuperSPARC、hyperSPARC、UltraSPARC、Alpha 21064 和 21164、原始 Pentium）。早期 OOO 设计的示例包括 MIPS R10000、Alpha 21264 以及在某种程度上整个 POWER/PowerPC 系列（及其预订站）。如今，几乎所有高性能处理器都是无序设计， 除了 UltraSPARC III/IV、POWER6 和 Denver 之外。大多数低功耗、低性能处理器（例如 Cortex-A7/A53 和 Atom）都是有序设计，因为 OOO 逻辑消耗大量功耗而性能增益相对较小。

一个必须要问的问题是，昂贵的乱序逻辑是否真的有必要，或者编译器在没有乱序逻辑的情况下是否也能很好地完成指令调度任务。

聪明机设计处于智能机器的范畴，其大量的乱序执行（OOO）硬件试图从代码中榨干每一点指令级并行性，即使为此耗费数百万个逻辑晶体管和多年的设计精力。从历史上看， 速度恶魔设计往往运行在更高的时钟速度下，正是因为它们更简单，因此得名“速度恶魔”。但如今情况已不再如此，因为时钟速度主要受功耗和散热问题的限制。

然而，不幸的是，乱序执行在动态提取额外指令级并行性方面的效率令人失望，仅取得了相对较小的提升，大概比同等的有序设计提升了 20% 到 40%左右。

> a pioneer of out-of-order execution and one of the chief architects of the Pentium Pro/II/III: "The dirty little secret of OOO is that we are often not very much OOO at all".

![image-20250927214956594](https://s2.loli.net/2025/09/27/WxwgtHrfmLa4hZi.png)

## The Power Wall & The ILP Wall

这一小节直接被上节的两个方式所驱动。

时钟速度存在极限。事实证明，功耗的增长速度甚至比时钟速度更快 ——对于任何给定的芯片技术水平，处理器的时钟速度提高 20%，通常会使其功耗增加更多。

那么，如果主要追求时钟速度是个问题，那么纯粹的脑力劳动是正确的方法吗？很遗憾，答案是否定的。追求更高的指令级并行性也有一定的局限性，因为不幸的是，由于加载延迟、缓存未命中、分支以及指令间依赖关系等因素的影响，普通程序中通常无法实现大量的细粒度并行性。这种可用指令级并行性的极限被称为 “指令级并行性墙”。

## What About x86?

x86作为CISC的代表，在这场ILP的竞赛中，CISC指令集存在天然的劣势，换而言之CISC指令集架构必须想办法绕过RISC。

该解决方案由 NexGen 和英特尔的工程师（大约在同一时间）独立发明，其原理是将 x86 指令动态解码为简单的、类似 RISC 的微指令，然后由快速、RISC 风格的寄存器重命名 OOO 超标量核心执行。这些微指令通常被称为 μops （读作 “micro-ops”）。 大多数 x86 指令解码为 1、2 或 3 个 μops， 而更复杂的指令则需要更多 μops。

![RISCy x86](https://s2.loli.net/2025/09/27/n7cgb83X2REGqDs.png)

一些较新的 x86 处理器甚至将翻译后的 μop 存储在一个小的缓冲区中，甚至是一个专用的 “L0” μop 指令缓存中，以避免在循环期间反复重新翻译相同的 x86 指令，从而节省时间和功耗。这就是为什么在前面关于超级流水线的部分中， Core i*2/i*3 Sandy/Ivy Bridge 的流水线深度被显示为 14/19 级 ——当处理器从其 L0 μop 缓存运行时（这是常见情况），它是 14 级； 但当从 L1 指令缓存运行时，需要解码 x86 指令并将其转换为 μop 时，它是 19 级 。

- x86指令获取与解码：

    现代 x86 处理器的工作方式已经不再是直接按照每条原始的 x86 指令执行，而是首先将 x86 指令转换为一系列更简单的 μop（微操作）。这些微操作类似于 RISC 处理器中的指令，因为它们是执行简单任务的小单位指令。

- μop和指令融合：

    在一些处理器中，多个 μop 可以组合或“融合”成一个单一的指令单元（例如，将“加载和加法”或“比较和分支”指令合并为一个）。这种融合方式减少了处理器需要处理的指令数量，并简化了跟踪依赖关系的复杂度。

- Haswell/Broadwell的例子：

    Haswell/Broadwell 处理器每周期最多可以解码 5 条 x86 指令，接着这些指令被转化成 μop。

    每周期最多可以生成 4 个融合的 μop，并存储在一个叫做 L0 μop 缓存 的缓存中。

    从 L0 缓存 中最多可以取出 4 个融合的 μop，然后执行寄存器重命名，并放入一个称为 重排序缓冲区（Reorder Buffer, ROB） 的地方。

    每周期最多可以从 ROB 中向功能单元发出 8 个未融合的 μop。这些 μop 会沿着处理器的多个流水线继续执行，直到完成。然后，每周期最多可以提交 4 个融合的 μop。

- 宽度的定义困境：

    由于 μop 的融合和拆分，Haswell/Broadwell 处理器的宽度定义并不简单。

    如果按 未融合的 μop 计算，处理器实际上可以在每周期发射并完成 8 个未融合的 μop，这相当于一个 8-issue（8 发射）的处理器。

    如果按 融合的 μop 计算，处理器每周期最多发射 4 个融合的 μop，这相当于一个 4-issue（4 发射）处理器。

    如果按 原始 x86 指令 计算，处理器每周期最多解码 5 条 x86 指令，意味着在这种定义下它是一个 5-issue 处理器。

- 宽度的学术性难题：

    这种“宽度”标定问题更多是学术性的问题，因为实际使用中，处理器不会维持如此高水平的指令级并行性（ILP）。因此，定义处理器的宽度时，不同的专家可能会根据自己的侧重点（是否考虑 μop 的融合、是否考虑 x86 指令）给出不同的答案。

## Threads – SMT, Hyper-Threading & Multi-Core

Simultaneous multi-threading (SMT): 旨在从其他程序或同一程序的其他线程中寻找独立指令填补误预测惩罚或者数据流依赖导致的`pipeline bubbles`。

其理念是用有用的指令填充流水线中的空隙，但这次不是使用来自同一代码中更底层的指令（这些指令很难获得），而是来自同时运行的多个线程 ，所有线程都在一个处理器核心上。因此，对于系统的其余部分来说，SMT 处理器就像多个独立的处理器一样，就像一个真正的多处理器系统。

![SMT flow](https://s2.loli.net/2025/09/27/MJfKXykCArqI12c.png)

SMT 设计中的所有线程都共享一个处理器核心和一组缓存，与真正的多处理器（或多核）相比，这会带来严重的性能劣势。 在 SMT 处理器的流水线中，如果一个线程占用了其他线程所需的一个功能单元，那么它实际上会阻塞所有其他线程，即使它们对该单元的使用量相对较少。

。因此，平衡线程的进度至关重要，**而 SMT 最有效的用途是用于代码混合变化很大的应用程序，这样线程就不会一直竞争相同的硬件资源**。归根结底，如果不加以注意，即使对某些应用程序而言非常谨慎，**SMT 的性能实际上也可能比单线程性能和传统的线程间上下文切换更差** 。

鉴于 SMT 能够将线程级并行性转换为指令级并行性，再加上特别适合 ILP 的代码具有更好的单线程性能优势，您现在可能会问，既然同样宽（总体而言）的 SMT 设计更胜一筹，为什么有人会构建多核处理器。事实证明，非常宽的超标量设计在芯片面积和时钟速度方面都非常糟糕。一个关键问题是，**复杂的多发射调度逻辑的扩展速度大约是发射宽度的平方 ，因为所有 n 条候选指令都需要与其他所有候选指令进行比较**。应用排序限制或“发射规则”可以减少这种扩展速度，一些巧妙的工程设计也可以做到这一点，但仍然处于 n^ 2 的量级。也就是说， 5 发射处理器的调度逻辑比 4 发射设计大 50% 以上，其中 6 发射是 4 发射设计的两倍多， 7 发射是 4 发射设计的 3 倍多， 8 发射是 4 发射设计的 4 倍多（但宽度只有 2 倍），等等。

**SMT 本质上是一种将 TLP 转换为 ILP 的方法**

带有SMT的OOO核心大小与简单有序核心面积上的区别如下图所示，左图为`Core i*2 Sandy Bridge`,右图为`UltraSPARC T3`，分别带有4，16个核心。

![img](https://s2.loli.net/2025/09/28/i9ubXCDxz4Q6HrA.png)

## Single instruction, multiple data SIMD

前面提到，丰富的ILP将会导致内存门限。许多程序在ILP，TLP之外还有另一种并行来源——数据并行。其理念并非寻找并行执行多组指令的方法，而是寻找使一条指令并行应用于一组数据值的方法。

SIMD并行在更常见的情况下，它被称为向量处理。超级计算机过去经常使用向量处理，处理非常长的向量，因为在超级计算机上运行的科学程序类型非常适合向量处理。然而，如今向量超级计算机早已被多处理器设计所取代，其中每个处理单元都是一个商用 CPU。那么，为什么要复兴向量处理呢？

像如下一个有关图像、视频和多媒体应用的计算中，SIMD通常是像这样的

![img](https://s2.loli.net/2025/09/28/NhOMGdy9lBsg1Ij.png)

这里发生的操作与 32 位加法完全相同，只是每个 8 位进位不会被传递。此外，当所有 8 位都已满时，值可能不会回绕为零，而是保持在 255 作为最大值（称为饱和运算）。换句话说，每个 8 位进位不会被传递，而是会触发一个全 1 的结果。因此，上面显示的向量加法运算实际上只是修改后的 32 位加法。

从硬件角度来看，添加这些类型的矢量指令并非难事——可以利用现有的寄存器，而且在很多情况下，功能单元可以与现有的整数或浮点单元共享。还可以添加其他有用的打包和解包指令，用于字节重组等，以及一些类似谓词的指令，用于位掩码等。经过深思熟虑，一小组矢量指令就能带来显著的加速提升。

### Cache and The Meory Hierarchy

![img](https://s2.loli.net/2025/09/30/YNP1y6nm8z2QCt9.png)

现代存储层次结构如上图所示。

## REF

1. <https://jarenl.com/index.php/2025/02/24/csapp_chp4/>
2. <https://www.lighterra.com/papers/modernmicroprocessors/>
