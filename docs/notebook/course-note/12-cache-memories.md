# Cache Memories

## Cache Memory organization and operation

![memory hierarchy](https://s2.loli.net/2025/08/21/UaRL89fVjEb6uP4.png)

### Cache Organization

缓存一般可以这样构建：由$S=2^s$个组构成，每一组有$E=2^e$行，每一行由一个$B=2^b$字节的数据块组成，还有一个有效位，指明这个数据块是否有效

Cache总大小一般表示为 $C = S \times E \times B(\text{data\_bytes})$

![cache organization](https://pica.zhimg.com/v2-c1f2dcfe0749451d9205f93d9ef54e62_1440w.jpg)

### Cache Operation

Cache中的所有数据都是按块为单位与Main Memroy交互的，但与CPU交互的过程中，存取则是先找到块的特定偏移地址然后进行存取特定位的数据

![Cache Concept](https://pic2.zhimg.com/v2-084036822598bbceb07897aea9ffd4b3_1440w.jpg)

当程序执行指令，引用了主存里的一些数据时，CPU 把地址发给 Cache，询问该地址里的数据。在 Cache 中的地址表示中，有 s 位表示组索引，b 位表示块内地址，剩下的 t 位都是标志位。搜寻数据时，首先定位组索引，然后检查标志位和有效位，如果标志位正确、有效位有效，则命中。然后 Cache 用低 b 位确定具体位置。

![cache read](https://pic3.zhimg.com/v2-c2e3fd035208cfd97b133996c5488ac0_1440w.jpg)

在直接相联映射中每组只有一行（$E = 2 ^ e \text{(e = 0)}$），对于数据查找，首先确定Cache地址中的`set index`。

![set index find](https://pic2.zhimg.com/v2-a9b189b33ebbc0b8b394c35bc96b0029_1440w.jpg)

然后确认该组中的数据是否有效，以及tag是否相同

![direct mapped cache（E=1）](https://s2.loli.net/2025/08/21/7JWSOZVwxEHfb8Q.png)

如果此时没有命中，将会发生数据替换（按照数据更换规则例如LRU等）
![direct mapped cache（E=1）2](https://s2.loli.net/2025/08/21/DsNapurmx2LAvKl.png)

**Simulation**
例如目前Main memory共计16字节，B=2, S=4, E=1,也就是说有共计8bytes的Cache空间，共4个组，每个组2bytes。
依次读入数据为0，1，7，8，0地址trace
对于
$$
0 [0\underline{00}0_2] \\
第一个位是tag位，后两位为set\_offset \\
最后一位为数据block\_offset \\
1 [0\underline{00}1_2] \\
由于0读入了对应位置的块因此读入该组偏移为1的数据 \\
7 [0\underline{11}1_2] \\
因无效位miss \\
8 [1\underline{00}0_2] \\
因tag不一致miss(可能发生替换) \\
0 [0\underline{00}0_2] \\
因可能发生的替换miss
$$
![Cache Simulation](https://s2.loli.net/2025/08/21/WIXdVfAgbYUJmKp.png)

> cache 容量足够，但是由于每组只有一行，主存中的每一块都只能装入 Cache 的唯一位置，若该块已有内容，则产生块冲突，原有块被直接挤出，导致命中率低，这就是直接相联映射的缺点。
> 再看组相联映射，下面是二路组相联映射，每组有两行。同样地，组索引为 1，所以找 set 1。
> 然后同时比较这两行的 tag，如果匹配且有效，则命中。但是这种并行比较对硬件要求很高，电路复杂且昂贵，最极端的方式就是只有一个组，块可以放在任何地方，也就是全相联映射，你需要同时比较所有行的 tag。所以较低的相联度（associativity）虽然有缺点，但是有时候不值得用更复杂的硬件去改善这个问题。

**Simulation**
![2-way set associative cache](https://picx.zhimg.com/v2-bd20eca85104af6e7d4b2370b908220b_1440w.jpg)
这时，读取8后再读取0的操作就可以被命中了

> 我们来看看写操作。我们有多个数据副本，因为当前层的数据是下一层数据的子集。当我们进行写操作时，是先修改 cache 里的数据，如果命中：
>
> 那么我们现在就有两个选择，一是直接写进主存里（全写法：write-through），二是当数据所在行被替换时、再写进主存里（写回法：write-back）。
>
> 显然，全写法会增加访问主存的次数，写回法则需要额外的数据位（dirty bit），当该块被替换，dirty bit 被设置，那么就需要写回主存，否则就不用。
>
> 如果未命中：
> 我们也有两个选择，第一个是写分配法（write-allocate），一般和写回法一起用，把这个块加载到 cache 里然后更新，利用的是局部性原则；第二个是非写分配法（no-write-allocate），一般和全写法一起用，直接写入主存，不加载到 cache。

![write policies](https://pic1.zhimg.com/v2-e49f372e692bccd77076f0ae4ee7d1d2_1440w.jpg)

> 在现实系统中，我们会有多个 cache，多个内核。每个内核可以各自并行执行它们的独立指令流，每个内核里面有处于最高层的通用寄存器，下面是 L1 cache，分为 d-cache（数据缓存）和 i-cache（指令缓存），它们只有 32KB，是八路组相联映射的，再下层是 L2 unified cache，有 256KB，同样是八路组相联映射，不区分数据和指令。所有内核共享的下一层是 L3 unified cache，8MB，十六路组相联映射。然后再到由 I/O 桥连接的主存。

> 衡量 cache 性能的指标有很多。首先是未命中率（miss rate），一般要非常低；(常见的命中率可能保持在90%以上)然后是命中时间（hit time），如果命中了，需要多长时间搜索块，然后把数据传给数据请求者，对于 L1 需要 4 个时钟周期，L2 是 10 个；最后是未命中惩罚（miss penalty），未命中所导致从主存取回数据的额外时间，对于主存是 50-200 个时钟周期，越到底层未命中惩罚越高。

> 所以未命中时间 = 命中时间 + 未命中惩罚。

![cache performance metric](https://pic2.zhimg.com/v2-2a94dde98d511600e2c8b3aef868b79b_1440w.jpg)
![difference of different miss rate](https://picx.zhimg.com/v2-2241f544a797c3b4859f98fb7ad9300b_1440w.jpg)

> 高速缓存是由硬件控制的，没有指令集，你不能操作缓存的过程，这都由硬件自动执行。但你可以写缓存友好代码，让你的代码有更高的缓存命中率。你应该让经常执行的代码跑得更快，尽量减少内循环的未命中。
> 
> 由时间局部性，重复引用存在堆栈里的局部变量是好的（为什么不是全局变量？因为编译器可以把局部变量存在寄存器里，全局变量不行）。由空间局部性，以步长为 1 的模式引用内存是好的，因为一个块有 64 字节，步长为 2 就意味着未命中率翻倍。
> 
> 我们有了对缓存的理解后，就可以根据未命中率进行量化分析。

然后给出了一个intel core i7的架构图

![core i7](https://s2.loli.net/2025/08/21/6Zn42GXvkcsWCmh.png)

估计甚至是4代i7,鉴于当时intel的挤牙膏姿态，当时的CPU架构对现在x86芯片架构仍有很大参考意义。然后是该芯片的一些实际运行时数据

![i7 cache performance](./../../AppData/Roaming/Typora/typora-user-images/image-20250821153147277.png)

可见对于容量较小的L1,命中率也能保持在 `90%` 以上，而L2则在 `98%` 以上。
命中效率通常在`4clocks for l1`, `10clocks for l2`。
非命中效率通常在`50-200clocls`。

这也可以解释为什么运行在swap状态时极差的交互表现。

## Performance impact of cache

这里提出了深度探索计算机操作系统这本书的封面图。

![code review](https://s2.loli.net/2025/08/21/TAkMJoC8ihVGc2n.png)

![the memory mountain](https://s2.loli.net/2025/08/21/jeJQLBUv4r12YTK.png)

> 步长增加时，空间局部性减少；size 是每次需要读取的数据量大小，因为每次读取的数据量，每个元素越大，缓存能存的就变小了，所以时间局部性减少。
>
> 实际上就对应着 L1，L2，L3，主存的读取吞吐量。当你的步长达到块大小（s8），每次引用都会是新块，所以变得平坦，不再有空间局部性的增益。当步长为 1 时，当 size 大于 L1 d-cache 时，速度掉到了 L2；然后当 size 大于 L2 cache 时，速度仍然保持在 L2，这也许是因为硬件识别到了步长为 1 的引用模式，开始积极从 L3 调用块给 L2。

这里pdf版本似乎少了一张图
![tuple](https://pic2.zhimg.com/v2-c70e5e950366043230113a6f0a7808bd_1440w.jpg)

然后用一个`Matrix calculatation`表明了cache对性能的深度影响。
result如下

![matric](https://s2.loli.net/2025/08/21/XHeExyqS9ns3O67.png)

> cpu运行矩阵运算，尤其是fp矩阵运算现在已经完全比不上gpu的效率了。

**分块优化**

这也是一个ACM中常见的技巧，通过优化时间局部性，降低算法复杂度，硬件亲和的同时很多时候也能达到降低算法复杂度到开方级的效果

![eg](https://picx.zhimg.com/v2-2c05ed13d421989cb3a068ddf10e4b81_1440w.jpg)

> 我们每个块有 8 个 double 大小，cache 的大小远远大于 n。
> 
> 举个例子，假设 cache 只能存 32*32 个 double，n 为 8w。初始 cache 为空，那么询问 a[0][0] 时会 miss，然后把 a[0][0] 到 a[0][7] 存到 cache 里，接着询问 b[0][0]会 miss，把 b[0][0] 到 b[0][7] 存到 cache 里。根据矩阵乘法，接下来访问 a[0][1]，命中，然后访问 b[1][0]，miss，一直接着下去。
> 
> 我们可以发现，对于数组 a 每 8 次询问就会 miss 一次，这个应该显而易见。而对于数组 b 每次询问都会miss，为什么？根本原因是因为 cache 太小、n 太大，如果 cache 足够大、n足够小，在访问 b[0][0] 时，它应该可以从 b[0][0]、b[0][1]、...、b[0][n] 一直存到 b[1][0]，甚至到 b[n][0]，这样接下来询问 b[1][0] 时就可以命中了，不至于每次都 miss。
> 
> 所以，计算 c 的每一个元素时，都会有 n/8+n 即 9n/8 次 miss。


而 c 一共有 $n^2$ 个元素，所以一共会 miss $\frac{9n^3}{8}$ 次。
![cache miss analysis](https://pic1.zhimg.com/v2-9690435461990d5be6f20f04504df5b4_1440w.jpg)

> 既然根本原因是 cache 存不下，那我们把每次计算的行和列变小不就行了（调换计算顺序）？怎么变小呢？
> 
> 根据线性代数知识，如果我们把矩阵分成很多块，每一块大小为 8*8，矩阵分块乘法是不影响结果的，我们上面没分块的计算其实就相当于块大小为 1*1 的矩阵分块乘法。
> 
> 我们还是假设 cache 只能存 32*32 个 double，n 为 10w。接着刚才，我们 cache 现在有 a[0][0] 到 a[0][7]，还有 b[0][0] 到 b[0][7]，我们关注 b 数组，继续计算继续 miss 7 次后，我们 cache 就会有 b[0][0] 到 b[0][7]、b[1][0] 到 b[1][7]、...、b[7][0] 到 b[7][7]。
> 
> 到此，因为我们每块是 8*8，所以我们不访问 b[8][0]，而是访问 b[0][1]，我们惊奇地发现，cache 命中了，接下来的 b[1][1] 到 b[7][1]，b[0][2] 到 b[7][2]，以此类推都是命中的，所以我们只在 b[0][0] 到 b[7][0] miss，8*8 小块内的其它元素都是命中的，根本原因是我们在 miss 的时候把整个小块都存进去了，通过这种方式提高了命中率。
> 
> 对于数组 a，还是每 8 次 miss 1 次；对于数组 b，我们把命中率也提高到了每 8 次 miss 1 次。

线性代数的特性与硬件的特性决定了矩阵运算特别适合小矩阵的快速运算，而不是直接计算大矩阵，因为不同块之间的计算是无关的，这也就导致了矩阵运算的进程不可避免的转向并行计算。

> 所以对于每一个大小为 B\*B 的块，我们需要在里面询问 B\*B 次，每 8 次 miss 1 次，所以有 $\frac{B^2}{8}$ 次未命中。

> 对于数组 c 中的每一个块，我们需要询问数组 a 中的 n/B 个块，数组 b 中的 n/B 个块，加起来一共是 2n/B 个块，所以乘起来就是：对于数组 c 中的每一个块有 nB/4 次未命中
![blocked](https://pic1.zhimg.com/v2-225f50778155d00dd23e8eb770df8658_1440w.jpg)
> 对于数组 c 中的每一个块有 nB/4 次未命中，数组 c 一共有 $(n/B)^2$ 个块，再乘起来就是总共的未命 次数： $\frac{n^3}{4B}$ 。

![miss analysis2](https://pic3.zhimg.com/v2-971a49be260661f9f13a0af8793c8db6_1440w.jpg)

> 接下来我们只需要尽可能提高块的大小，就可以有效降低未命中次数。

![blocked summary](https://pic4.zhimg.com/v2-c4bc00e736344ad7cdd18e1e2092bf6b_1440w.jpg)

> 高速缓存寄存器非常重要。在编程中，应该注重内循环，因为内循环有大量的计算和内存引用。
> 
> 尽量以步长为 1 的模式引用内存，来提高空间局部性。
> 
> 尽量访问同一个变量，来提供时间局部性。

![Summary](https://pic4.zhimg.com/v2-e805df8f9014d88568ae52da4ffddd81_1440w.jpg)

## REF

1. https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/12-cache-memories.pdf#page=12.00
2. https://zhuanlan.zhihu.com/p/659738474