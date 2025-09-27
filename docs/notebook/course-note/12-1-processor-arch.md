# 现代微处理器架构

## Motivation

因CS:APP第四章中部分未学习知识点以及[现代微处理器 - 90 分钟指南！ --- Modern Microprocessors - A 90-Minute Guide!](https://www.lighterra.com/papers/modernmicroprocessors/)中的归纳总结构建的特殊章节

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





## REF
1. https://jarenl.com/index.php/2025/02/24/csapp_chp4/
2. https://www.lighterra.com/papers/modernmicroprocessors/