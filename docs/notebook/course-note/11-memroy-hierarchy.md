# Memroy Hierarchy

由于这里也提前学会了一些有关内存的内容，所以这一章省略也会比较多。

## Storage technologies and trends

1. `cell`：一般指在内存分配中不可拆分的单元，一般认为是`mmap`内存映射时的最小单位，通常为8个字节。
![CPU and memory trans](https://pic4.zhimg.com/v2-fba4fd4c2bc97ed153e32882766ee011_1440w.jpg)
2. `Cache`: 一般Core都具有两级Cache，通常叫做`L1`,`L2`...还有`L0`cache，一般数字越小越靠近执行核心（因为不一定为CPU,所以这里不叫ALU），特殊的，一般在存储设备上还会有`LLC`（Last-level Cache）
3. `存储介质`：这里提到了磁盘，但个人电脑上目前很少见了，目前热门的存储为一个接口协议CXL，提供各个不同Level的异构存储的调用，通常认为强于外存（例如SSD，M2），但弱于内存（RAM,HBM）。
4. `局部性原理`: 尤其核心的原理，弥补CPU与MemoryGAP的重要方式，同时在网络等各种计算机方向均有运用。
![Locality](https://picx.zhimg.com/v2-8450d5a54aba082385a80e0e91da64bd_1440w.jpg)
二重循环中最容易体现，也是很多入门的常用eg，简单的讲就是让指令之间调度的内存尽可能相近，甚至顺序。

5. **内存分级**：存储领域最重要的概念之一，在很多地方有一个放大时间版本的Latency示意图。最近的资源是CMU DATABASE课程15445中的图
![Memroy Hierarchy](https://pica.zhimg.com/v2-d7d9ca560f7aa7a7ea9f68f541f02704_1440w.jpg)
![access times](https://s2.loli.net/2025/08/21/uiCBDAMndybYmvK.png)

- `Cache miss`
	- `cold miss`：无法避免，可以优化，数据过冷不命中
	- `capacity miss`：由于Cache容量的不命中
	- `conflict miss`：与缓存的实现方式有关。缓存的设计应该尽量简单，缓存最简单的模型之一就是块号为 i 的块只能放在（i mod 缓存大小）处，这导致存放数据的冲突

- `TLB`: Translation Lookaside Buffer，是一个在虚拟内存中使用的缓存。

![example](https://pica.zhimg.com/v2-6487fde1631f861c0a51b1878397ecbe_1440w.jpg)

## REF

1. https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/11-memory-hierarchy.pdf
2. https://zhuanlan.zhihu.com/p/659620678

