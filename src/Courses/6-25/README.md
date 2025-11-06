# 6-25

![6-25](https://s2.loli.net/2025/11/04/OxDTfM2djruQgC9.png)

## Answer

首先是简单的总结

| Symbol | Meaning                                    |
| :----- | :----------------------------------------- |
| **m**  | Number of bits in the **physical address** |
| **C**  | Total cache size in **bytes** (data only)  |
| **B**  | Block (or line) size in **bytes**          |
| **E**  | Associativity — number of lines per set    |
| **S**  | Number of **sets** (cache groups)          |
| **b**  | Number of **block offset bits**            |
| **s**  | Number of **set index bits**               |
| **t**  | Number of **tag bits**                     |

---

- 每个块包含 **B 个字节** ，因此我们需要足够的位来寻址一个块内的所有字节。
$$
b = \log_2(B)
$$

---


- 每个集合包含 E 块 ，总缓存容量为 C 字节：

$$
S = \frac{C}{B \times E}
$$

---

- 我们需要足够的位来选择其中一个 S 集合

$$
s = \log_2(S)
$$

---

- :物理地址分为三个部分
$$
\text{[Tag | Index | Block offset]}
$$

所以标签位的数量是：

$$
t = m - (s + b)
$$

---

### ✅ 5. Summary of relationships

| Quantity | Formula                  | Meaning           |
| :------- | :----------------------- | :---------------- |
| ( b )    | ( \log_2(B) )            | Block offset bits |
| ( S )    | ( \frac{C}{B \times E} ) | Number of sets    |
| ( s )    | ( \log_2(S) )            | Index bits        |
| ( t )    | ( m - s - b )            | Tag bits          |

---

### 🧠 Example

Suppose:

* Physical address: ( m = 32 ) bits
* Cache size ( C = 32\text{ KB} = 32 \times 1024 ) bytes
* Block size ( B = 64 ) bytes
* 4-way set associative (so ( E = 4 ))

Compute:

1. ( b = \log_2(64) = 6 )
2. ( S = \frac{32 \times 1024}{64 \times 4} = 128 )
3. ( s = \log_2(128) = 7 )
4. ( t = 32 - (7 + 6) = 19 )

✅ **Result:**

* Tag bits (t = 19)
* Index bits (s = 7)
* Offset bits (b = 6)
* Number of sets (S = 128)

---

最终的答案


| m    | c    | B    | E    | S    | t    | s    | b    |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 32   | 1024 | 4    | 4    | 64   | 24   | 6    | 2    |
| 32   | 1024 | 4    | 256  | 1    | 30   | 0    | 2    |
| 32   | 1024 | 8    | 1    | 128  | 22   | 7    | 3    |
| 32   | 1024 | 8    | 128  | 1    | 29   | 0    | 3    |
| 32   | 1024 | 32   | 1    | 32   | 22   | 5    | 5    |
| 32   | 1024 | 32   | 4    | 8    | 24   | 3    | 5    |


## REF

1. [6.25 - CASPP 3e 解决方案 --- 6.25 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter6/6.25/)   