# Program Optimization

## Performance Realities - OPtimization

这里一句话总结：**我推荐任何人尝试1900分以下的codeforce**。
基本上就是在阐述大O优化与常数优化之间的利弊

> 有关编译器优化，在[Attacklab](../lab-note/attacklog.md)中有提到一个简单的例子，但实际情况可能更为复杂，新版本的GCC在单个文件内进行过程分析，不在不同文件间进行代码分析，他们大都仅依赖静态信息，难以识别运行时输入。**最关键的是如果有任何问题，务必优先怀疑编译器优化**。

下面是一些常见的静态优化代码
![generally optimization](https://s2.loli.net/2025/08/19/k6iC1BlA8579XOp.png)
![O1](https://s2.loli.net/2025/08/19/eODHlNahUcuBojF.png)
![reduction in strength](https://s2.loli.net/2025/08/19/DzOQ4B6AIrl27oC.png)
![share common subexpressions](https://s2.loli.net/2025/08/19/eLdaEK7C2jURkFA.png)

考虑下面这个函数，如何进行优化
![procedure1](https://s2.loli.net/2025/08/19/8qbdmOeAUTQaRxP.png)
![lower case conversion perf](https://s2.loli.net/2025/08/19/eUOPo5m9b1JsrFK.png)

![convert loop to goto form](https://s2.loli.net/2025/08/19/yNbkVID9qFfsgMP.png)
![calling strlen](https://s2.loli.net/2025/08/19/yJcZB1thX8kzN5n.png)
还是一些常规的优化手段，一般认为循环体内的数据函数调用，在非记忆化的状态下会造成常数级别的性能问题，但在这个函数中，由于c的特定，造成了大O级别的额外性能开销

cpp不会有这种问题，绝大多数情况下cpp“额外做的事”就是这样的事。
因为string库中的.length数据是记忆化的。

但c为什么会表现得这么“蠢”?以至于使得开销凭空放大了这么多。
这是因为这个函数比较特殊，它不断在改变字符数组，而编译器不敢改变程序逻辑，因为它并不知道长度会不会在这个函数中被改动。

![Memory Matters](https://s2.loli.net/2025/08/21/qTJs1iIkogFzARU.png)
这里的关注点在于嵌套循环中为何要更新b数组的迭代，可见每次都在用同样的值更新xmm0，然后存回对应的地址。
![memory alias](https://s2.loli.net/2025/08/21/7wuYIz4nQVE5Dqa.png)
这里a与b指向了同样的区域造成了预期外的错误

然后说明了以下int与fp的区别
![difference of fp and int](https://s2.loli.net/2025/08/21/pNe1SvslGZDmA75.png)

![pipline parallelism](https://s2.loli.net/2025/08/21/HuB1TQCLOidjUx4.png)

> 引入一个这里没有提到的pp方式的概念：bubble，即在pp中其他pipe在运行时造成的“气泡”空闲，通常通过提高并行任务数量减少，但不会完全消失

这里的内容都有些无趣，讲的基本上就是不要在循环中定义变量，记忆化参数，fp计算慢，divide尤其慢之类的问题。以及循环展开提升性能的问题

> 除法为什么这么慢，首先是大O级别的，除法没有太好的算法（例如乘法可以二进制优化），其次除法因为依赖无法pp执行。如果有学过高精度算法，就能意识到这其中的原因。

## Architecture
![modern cpu design](https://s2.loli.net/2025/08/21/TVRQPOX8sjN67Kq.png)

- `superscalar out of order execution`: 超标量乱序执行，指cpu乱序执行非依赖的大量指令
- `Instruction-level parallelism`: 指由 superscalar out of order execution等带来的指令级并行。
- `superscalar instruction CPU`: 指具备superscalar out of order execution的CPU,其能在同一时钟周期内执行多条指令

	> superscalar&hyper-therading: 超标量和超线程。这是两个不同的技术。涉及完全不同的两种并行方式ILP（Instruction level parallelism）与TLP（Therad level parallelism）。
		超线程是一种通过物理核心模拟多个逻辑核心的技术，example：就像后厨有两只手和同时接待两个客人的区别。

![pipeline illustraction](https://pic1.zhimg.com/v2-d46808e832516895c8c8dfb9155616e0_1440w.jpg)
- 执行指令的两个指标
	- `延迟（latency）`是指一个指令从头到尾需要多少时间
	- `Cycles/Issue` 表示流水线中两个小步骤之间的距离。
- `loop unrolling`指通过将多个嵌套循环内的操作展开到一个循环中，即flat的操作，也是acm中很常见的操作
- `浮点数的计算精度问题`这是由于整数表示为补码计算，符合结合律和交换律，群论的说法是符合阿贝尔群，而浮点数不符合，所以会出现所谓“浮点数精度问题”。解决方法也很简单，少用浮点数。否则，认真review代码。
- `CPE` Cycles Per Element每个元素的时钟周期这是一个衡量程序性能的指标，用来表示处理一个数据元素所需的平均时钟周期数。

![RESULT](https://pica.zhimg.com/v2-e2c9235ac2852537e192cb57709fb542_1440w.jpg)
![RESULT2](https://picx.zhimg.com/v2-2f68dcac5dc29562ad87ecfc80360eb7_1440w.jpg)

- `CPU级别tricks` 例如ppt最后提到的YMM寄存器，这类优化通常利用特殊的寄存器，指令优化程序，也是最神秘的优化方式，通过这种方式通常能够达到最令人惊奇的方式，也是很多官方库中的优化方式。
- `SIMD` Single Instruction, Multiple Data单指令流多数据流这是一种并行计算模型，**允许一条指令同时处理多个数据元素**，这是一种在各种架构中都很常见的优化方式。能够极大的提高运行效率
- `分支预测` 顺序结构指令，CPU 会一次读取尽量多指令，把指令分开。但如果遇到分支结构，CPU会预测哪一个分支最有可能执行，`最前沿的方向之一`。

## Summary

ACMer在这回合算是狠狠赢了，基本都会，但是有关superscalar，SIMD，分支预测，可能还需要paper reading和experiments.

## REF

1. https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/10-optimization.pdf#page=38.00
2. https://zhuanlan.zhihu.com/p/659510293
