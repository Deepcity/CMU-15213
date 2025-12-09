# 20 Malloc Advanced: 内存分配器设计与实现进阶

## Declaration

本文使用了 AIGC 来提高效率，其中可能存在谬误，我已尽力检查并校对，但仍不保证完全准确，欢迎指正。

接着上一次的内容，这一份 PPT 讲的是 **动态内存分配的进阶内容**：更高效的数据结构（显式/分离空闲链表）、垃圾回收（GC）以及常见的内存错误与调试方法。

------

## 一、显式空闲链表（Explicit Free List）

### 1. 基本思想

- 不再像隐式链表那样顺序扫描 **所有块**，而是只维护 **空闲块的链表**。
- 每个空闲块的 payload 区里放两个指针：
  - `prev`：指向上一空闲块
  - `next`：指向下一空闲块
- 仍然需要 header / footer（boundary tag）来记录大小和 allocated bit，以支持合并（coalescing）。

块格式（空闲块）大致是：

```text
[ header | prev | next | ... 空闲空间 ... | footer ]
```

### 2. 逻辑视图 vs 物理视图

- **逻辑上**：空闲块按链表连接（A → B → C）。
- **物理上**：A/B/C 在堆中的地址顺序可以是任意的，不必连续。

### 3. 分配（malloc）

从空闲链表中选一个空闲块：

1. 找到合适大小的 free block（first-fit / best-fit 等）。
2. 必要时对块进行 **split**。
3. 将使用部分从 free list 中移除，剩余部分仍作为 free block 插回链表。

### 4. 释放（free）与插入策略

释放时，需要：

1. 把块标记为 free。
2. 与前后块尝试 coalesce。
3. 把合并后的块插回 free list。

**插入策略**：

- **LIFO（后进先出）**：把新 free 的块插在链表头：
  - 优点：实现简单，时间复杂度 O(1)。
  - 缺点：实验表明碎片比“按地址有序”的要严重。
- **地址有序（address-ordered）**：
  - 把 free block 根据地址插入链表，保持地址从小到大。
  - 优点：碎片更小。
  - 缺点：插入时需要遍历查找合适位置，成本较高。

### 5. 小结：显式 vs 隐式

- 分配开销：显式链表的查找是 **相对于空闲块数量线性**，比“扫描所有块”的隐式链表快得多。
- 操作复杂度：需要维护 prev/next 指针，free 过程略复杂。
- 额外开销：每个空闲块多占两个指针字段（内部碎片略增）。

实际 malloc 实现里，**显式链表通常和“分离空闲链表”一起使用**。

------

## 二、分离空闲链表（Segregated Free Lists, Seglist）

### 1. 设计动机

单一 free list 对于大堆来说查找仍然较慢。分离空闲链表的核心想法：

> **按块大小划分多个 free list，每个链表只管理其对应大小范围的块。**

例子（PPT 中示意）：

- 第 1 类：块大小 1–2
- 第 2 类：大小 3
- 第 3 类：大小 4
- 第 4 类：大小 5–8
- 第 5 类：大小 9–∞

实现时：

- 小块可以“每个尺寸一个链表”（精细粒度）。
- 大块可以使用“2 的幂”作为 size class 边界（1,2,4,8,16,...）。

### 2. 分配流程

要分配大小为 $n$ 的块时：

1. 找到对应 size class 的 free list。
2. 在该 list 中找第一个大小 $m \ge n$ 的块。
3. 找到后，可以选择：
   - 直接使用；或
   - 分裂：把多余部分分出，放回合适的 size class。
4. 如果当前 size class 中找不到块，就去 **更大的 size class** 查找，依次类推。
5. 如果所有 list 都找不到：
   - 向 OS 请求更多堆空间（例如 `sbrk`）。
   - 从新空间中切出一块大小为 $n$ 的块，剩余部分作为最大的 size class 的 free block 插入。

### 3. 释放流程

- 对被 free 的块进行 coalesce（和相邻 free 块合并）。
- 根据合并后块的大小，放入对应的 size class 链表中。

### 4. 优点

- 查找复杂度接近 $O(\log n)$（若使用 2 的幂 size class）。
- 在每个 size class 内做 first-fit，整体效果接近 **在全堆做 best-fit**，从而：
  - **吞吐量**更高；
  - **内存利用率**也较好。
- 极端情况下，如果每个大小单独一个链表，相当于理想的 best-fit。

------

## 三、垃圾回收（Garbage Collection, GC）

### 1. 隐式内存管理的核心思想

GC 是一种 **自动回收堆内存** 的机制：程序只分配、不显式 free。常见于：

- Python、Java、Ruby、ML、Lisp 等语言。

也有适用于 C/C++ 的 **保守垃圾回收器（conservative GC）**，但无法保证回收所有垃圾。

### 2. “内存图”模型

将内存看成一个有向图：

- 每个堆块是一个节点。
- 块之间的指针是边。
- 栈、寄存器中的指针、全局变量中的指针是 **根节点（root）**。
- 定义：
  - 若从任一 root 出发能到达某块，则该块是 **可达（reachable）** 的。
  - 若某块不可达，则它一定不会再被程序使用，可以回收——这就是垃圾。

### 3. Mark-and-Sweep（标记-清扫）算法

GC 实现里常用、结构清晰的一种：

#### （1）基础假设

GC 需要一些“辅助操作”，例如：

- `is_ptr(p)`：判断某个字是否是指向堆块的指针；
- `length(b)`：得到块 b 的长度；
- `get_roots()`：获得所有 root 指针集合。

每个块的 header 中有一个 **mark bit** 用于标记。

#### （2）标记（mark）阶段——DFS/BFS 遍历

1. 从所有 root 指针开始，对每一个可达块做 DFS：
   - 若指针 p 不是指向堆块，则忽略。
   - 若该块未被标记，则设置其 mark bit。
   - 扫描块中的每个字 `p[i]`，若是指针，则递归调用 `mark(p[i])`。
2. 遍历结束后，所有 **可达块** 都被标记。

伪代码大致形如：

```c
void mark(ptr p) {
    if (!is_ptr(p)) return;
    if (markBitSet(p)) return;
    setMarkBit(p);
    for (i = 0; i < length(p); i++)
        mark(p[i]);
}
```

#### （3）清扫（sweep）阶段

1. 从堆起始地址线性扫描到结尾。
2. 对每个块：
   - 若 mark bit 置位 → 清除 mark bit，保留块（仍被使用）。
   - 若 mark bit 未置位且块为 allocated → 调用 `free(p)` 回收。
3. 扫描完所有块，垃圾（不可达块）即全部被释放。

伪代码近似：

```c
void sweep(ptr p, ptr end) {
    while (p < end) {
        if (markBitSet(p))
            clearMarkBit(p);
        else if (allocateBitSet(p))
            free(p);
        p += length(p);  // 跳到下一个块
    }
}
```

#### （4）保守 GC for C

对于 C 语言：

- `is_ptr` 通常通过判断一个字是否落在已分配堆块地址区间来实现。
- 由于 C 中指针可能指向块内部，需要额外的数据结构（例如平衡二叉树）记录所有堆块的起始地址，以便“往前找到块头”。

------

## 四、常见的内存错误与陷阱（Perils and Pitfalls）

PPT 中列举了一串在 C 里极易犯的错误：

### 1. 解引用坏指针（bad pointer）

典型例子：`scanf` 漏写 `&`：

```c
int val;
scanf("%d", val);   // 错：val 是 int，不是 int*，scanf 会把输入写到随机地址
```

### 2. 读未初始化内存

假设堆数据自动初始化为 0 是错误的：

```c
int *y = malloc(N * sizeof(int));  // y[i] 未初始化
...
y[i] += A[i][j] * x[j];            // 读出了未定义值
```

### 3. 覆盖内存（overwrite）

#### （1）分配错尺寸

```c
int **p;
p = malloc(N * sizeof(int));   // 应该是 N * sizeof(int*)，少了一维
```

#### （2）越界访问（off-by-one）

```c
p = malloc(N * sizeof(int *));
for (i = 0; i <= N; i++) {     // <= N 导致越界一格
    p[i] = malloc(M * sizeof(int));
}
```

#### （3）字符串不检查长度 —— 经典缓冲区溢出

```c
char s[8];
gets(s);   // 输入 "123456789"，溢出 s 的边界
```

#### （4）错误的指针算术

```c
while (*p && *p != val)
    p += sizeof(int);     // 错：指针加 sizeof(int) 会跳过很多元素
```

#### （5）把“指针本身”当成对象

例如试图递减 `*size` 却写成 `*size--` 等，导致行为和预期不符。

### 4. 引用不存在的局部变量（dangling stack pointer）

返回栈上局部变量地址：

```c
int *foo() {
    int val;
    return &val;  // 返回后 val 已经失效
}
```

### 5. 重复释放（double free）

```c
x = malloc(...);
free(x);
...
free(x);    // 再次 free 会破坏堆结构，后果极难调试
```

### 6. 使用已释放的块（use after free）

```c
x = malloc(...);
free(x);
...
y = malloc(...);
y[i] = x[i]++;   // x 指向的内存很可能已被 y 复用，逻辑错误 + 潜在崩溃
```

### 7. 内存泄漏（memory leak）

#### （1）完全忘记 free

```c
foo() {
    int *x = malloc(...);
    ...
    return;   // x 永远不 free
}
```

#### （2）只释放数据结构头结点

```c
struct list {
    int val;
    struct list *next;
};

foo() {
    struct list *head = malloc(...);
    ...
    free(head);   // 只释放头结点，后面整个链表泄漏
}
```

------

## 五、定位和修复内存 bug 的方法

PPT 最后介绍了一些实用工具和手段：

- **gdb 调试器**
  - 适合找“解引用坏指针”这种明显崩溃的问题。
- **数据结构一致性检查器**
  - 在代码里定期检查 free list 或其他结构是否有环、非法指针等，一旦发现问题就打印错误。
- **动态分析工具：valgrind（非常重要）**
  - 动态翻译并插桩程序，对每次内存访问进行检查。
  - 能检测：
    - 读未初始化内存；
    - 越界访问；
    - use-after-free；
    - 内存泄漏等。
- **glibc 自带的 malloc 检查**
  - 设置环境变量 `MALLOC_CHECK_` 可以开启简单的堆检查机制。

------

## 六、整个 “动态内存分配” 两讲的整体框架回顾

1. **基础讲（上一次）**
   - 堆和分配器基本模型（heap、block、header/footer）。
   - 碎片（internal/external）和性能指标（吞吐量、峰值利用率）。
   - 隐式空闲链表、分割、合并、boundary tags。
2. **进阶讲（这一次）**
   - 更高效的 free block 组织方式：
     - 显式空闲链表；
     - 分离空闲链表（接近工业级实现）。
   - 自动内存管理：mark-and-sweep GC 的基本思路和实现框架。
   - C 中常见的内存错误及调试工具。

## Recommend BLOG

1. [CSAPP Malloc Lab - 次林梦叶 - 博客园](https://www.cnblogs.com/cilinmengye/p/18093810)

## REF

1. [CMU15213 - CSAPP 动态内存分配总结](https://chatgpt.com/g/g-p-68e7b4b594a48191a3896754ae062e4f/c/6935488a-2b80-8329-9df2-f11cd8e40fc7)
2. [20-malloc-advanced](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/lectures/20-malloc-advanced.pdf)
