# 19. 动态内存分配基础

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

-----

## **1. 动态内存分配的基本概念**

动态内存分配允许程序在运行时通过 `malloc/free` 获取或释放内存。分配器（allocator）管理一段称为 **heap（堆）** 的虚拟内存区域，包含一系列大小可变的块（blocks），每个 block 要么被分配，要么处于空闲状态。

常见类型：

- **显式分配器**：需要用户调用 `malloc/free`（C语言）
- **隐式分配器**：程序只申请不释放，由垃圾回收处理（Java、Lisp）

------

## **2. malloc/free 接口与行为**

### `malloc(size)`

- 返回至少 `size` 字节的已分配块指针，满足对齐要求（x86 为 8B，x86-64 为 16B）。
- 若失败返回 NULL。

### `free(ptr)`

- 将 `ptr` 对应内存块归还给分配器。

其他常见函数：

- `calloc`：分配并清零
- `realloc`：变更块大小
- `sbrk`：底层扩展 heap 边界

------

## **3. 分配器的限制与挑战**

分配器必须应对任意顺序的 malloc/free 调用，并必须**立即响应**每一次分配请求，而不能延期或重排。

限制包括：

- 不能移动已分配的块（不允许压缩/compaction）
- 只能操作空闲块存储的辅助信息（不可写用户数据）
- 必须保持对齐

这些限制导致 **碎片问题（fragmentation）**。

------

## **4. 性能目标：吞吐量与内存利用率**

### **吞吐量（Throughput）**

每秒完成的 malloc/free 数量越多越好。

### **峰值内存利用率（Peak Memory Utilization）**

$$ U_k = \frac{\max_{i\le k} P_i}{H_k} $$
 其中

- (P_i)：当前所有 allocated 块的 payload 之和
- (H_k)：当前堆的大小（通常单调递增）

目标是尽可能高的利用率。吞吐量与利用率常常相互冲突。

------

## **5. 碎片化（Fragmentation）**

### **内部碎片（Internal Fragmentation）**

payload 小于块大小时产生。来自：

- 对齐填充（padding）
- 管理信息开销（header/footer）
- block split 后剩余空间过大

### **外部碎片（External Fragmentation）**

heap 中总空闲空间足够，但缺乏一个连续大块。难以测量，因为依赖未来的分配模式。

------

## **6. 如何知道 free 多少字节：Header（块头）**

每个块前通常放一个 **header**，记录块大小与是否已分配。

为了节省空间：

- 块大小满足对齐，因此低位比特恒为 0
- 分配器利用最低位 bit 作为 allocation flag
  - `a = 1`：allocated
  - `a = 0`：free

------

## **7. 跟踪空闲块的方式**

四种主流方案：

1. **隐式空闲链表（Implicit free list）**
    通过遍历整个 heap，逐块查看 header 判断是否空闲。
2. **显式空闲链表（Explicit free list）**
    空闲块中加入前驱/后继指针，只遍历 free блокs。
3. **分离空闲链表（Segregated free list）**
    按 block 大小区间维护多个 free lists（实践主流方法）。
4. **平衡树（如红黑树）按大小组织 free blocks**
    高级实现，用于快速 best-fit。

本 PPT 主要介绍的是 **方案 1：隐式空闲链表**。

------

## **8. 隐式空闲链表（implicit list）核心机制**

### **（1）Block 格式**

```
Header: [ block size | alloc flag ]
Payload: 用户数据
(Free blocks可能没有payload)
```

根据 header 获取 block 大小，顺序遍历所有块。

------

### **（2）空闲块查找策略**

三种基本策略：

- **First-fit**：从头开始找第一个足够大的 free block
   *速度较快，但容易在前部留下小碎片。*
- **Next-fit**：从上次结束位置继续搜索
   *吞吐量略好于 first-fit，但碎片更严重。*
- **Best-fit**：选择最接近请求大小的 free block
   *更好的利用率，但速度慢。*

------

### **（3）分割（Splitting）**

若选中的 free block 比请求大，则将其分为：

- 分配块
- 剩余 free block（重新插入链）

------

### **（4）释放（Freeing）与合并（Coalescing）**

释放一个 block 时：

- 清除 its alloc flag
- 尝试与 **后一个块** 合并（同样 free 才能 coalesce）

但要与前一个块合并，需要知道前块是否空闲，因此增加：

### **Boundary Tags（边界标记）**

在 free block 底部加一个 footer：

```
Footer: [ block size | alloc flag ]
```

使得分配器能在常数时间判断前块大小并实现双向合并。

四种合并情况（当前、前、后是否 free）：均能在 O(1) 完成。

------

### **（5）缺点**

- 每个 free 块多一个 footer，增加内部碎片。
- 遍历速度慢（分配操作 worst-case O(n)）。
   因此，隐式链表一般不用于生产级 malloc 实现，但相关思想（分割、合并、boundary tags）仍是所有分配器的基础。

------

## **9. 分配器设计的关键策略总结**

### **Placement 策略**

- first-fit / best-fit / next-fit

### **Splitting 策略**

- 是否切出剩余 free block
- 允许多少内部碎片

### **Coalescing 策略**

- **立即合并**：每次 free 都 coalesce
- **延迟合并**：需要时才合并，如搜索 free list 时进行 coalesce

------

## **10. 章节总结**

隐式空闲链表的优点是 **简单易实现**，缺点是 **分配速度慢、碎片多**。它奠定了现代内存分配器（如 glibc malloc、tcmalloc、jemalloc）的基础思想，例如：

- header/footer 用于快速访问块信息
- 分割与边界合并
- 多种 placement 策略比较
- 内外部碎片分析

现代分配器采用更先进的数据结构（如 segregated lists），但隐式链表是学习分配器原理的重要起点。

## REF

1.[19-malloc-basic](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/19-malloc-basic.pdf)

2.[ChatGPT - CMU15213](https://chatgpt.com/g/g-p-68e7b4b594a48191a3896754ae062e4f-cmu15213/c/6935488a-2b80-8329-9df2-f11cd8e40fc7)
