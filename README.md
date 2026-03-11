# CMU-15213

## Link

[CS：APP3e、科比和奥哈拉隆 --- CS:APP3e, Bryant and O'Hallaron](https://csapp.cs.cmu.edu/3e/students.html)

## Introducion

“Computer Systems: A Programmer's Perspective”（计算机系统：程序员的视角），是卡内基梅隆大学（Carnegie Mellon University, CMU）开设的一门著名本科计算机科学课程，通常也被称为“CS:APP”课程（取自其配套教材《Computer Systems: A Programmer's Perspective》的缩写）。

该REPO为个人学习REPO，依据CMU课程，Lab相关要求，请勿将答案直接填入CMU作业中，因擅自使用这份答案的后果个人自负，与本项目库无关，详细请参见[学术诚信 - 大学政策 - Carnegie Mellon University --- Academic Integrity - University Policies - Carnegie Mellon University](https://www.cmu.edu/policies/student-and-student-life/academic-integrity.html)与[学术诚信 - 卡内基梅隆大学工程学院 --- Academic integrity - College of Engineering at Carnegie Mellon University](https://engineering.cmu.edu/education/academic-policies/academic-integrity.html)。

该REPO含有AI-generate，Blog以及他人帮助，并非完全独立完成，如有侵权，请邮件联系我。

## Main Content

1. **信息的表示与处理**：整数与浮点数的二进制表示、字节序、位运算等。
2. **汇编语言与机器级代码**：通过x86-64汇编语言理解C程序如何被编译和执行。
3. **程序的链接与加载**：静态链接、动态链接、可执行文件结构（ELF）等。
4. **内存层次结构**：缓存（Cache）原理与性能优化。
5. **程序的执行与优化**：处理器流水线、指令级并行、编译器优化。
6. **虚拟内存系统**：地址翻译、分页、内存映射、缺页处理。
7. **系统级I/O与异常控制流**：系统调用、进程、信号、上下文切换。
8. **并发与并行**：进程与线程、同步机制（如互斥锁、信号量）、多线程编程。

## Main Lab

- **Data Lab**：位操作编程
- **Bomb Lab**：逆向工程拆解“二进制炸弹”
- **Attack Lab**：理解缓冲区溢出攻击与防御
- **Architecture Lab**：实现 Y86-64 流水线处理器
- **Cache Lab**：缓存性能优化
- **Shell Lab**：实现一个简易Unix shell
- **Malloc Lab**：实现动态内存分配器
- **Proxy Lab**：实现并发Web代理服务器


## Schedule Table

### Lab Table

| LabName             | StartTime  | EndTime    |
| ------------------- | ---------- | ---------- |
| **Data Lab**        | 2025-07-31 | 2025-08-04 |
| **Bomb Lab**        | 2025-08-06 | 2025-08-10 |
| **Attack Lab**      | 2025-08-13 | 2025-08-17 |
| **Architecture Lab**| 2025-08-18 | 2025-08-24 |
| **Cache Lab**       | 2025-09-01 | 2025-09-07 |
| **Shell Lab**       | 2025-09-08 | 2025-09-14 |
| **Malloc Lab**      | 2025-09-15 | 2025-09-28 |
| **Proxy Lab**       |            |            |

## Project Structure

```
CMU-15213
├── backup
├── docs
│   └── notebook
│       ├── course-note
│       └── lab-note
├── README.md
├── resources
│   ├── architecture_lab
│   ├── attack_lab
│   ├── books
│   ├── cache_lab
│   ├── code-all.tar
│   ├── courses
│   │   └── 2015fall
│   ├── malloc_lab
│   ├── papers
│   └── shell_lab
└── src
    ├── Architecture-Lab
    ├── Attack-Lab
    ├── Bomb-Lab
    ├── Buffer-Lab
    ├── Cache-Lab
    ├── Datalab-Lab
    ├── Malloc-Lab
    └── Shell-Lab
```

## REF
1. [学术诚信 - 卡内基梅隆大学工程学院 --- Academic integrity - College of Engineering at Carnegie Mellon University](https://engineering.cmu.edu/education/academic-policies/academic-integrity.html)
2. [学术诚信 - 大学政策 - Carnegie Mellon University --- Academic Integrity - University Policies - Carnegie Mellon University](https://www.cmu.edu/policies/student-and-student-life/academic-integrity.html)
3. [15-213：计算机系统概论/2015年秋季课程 --- 15-213: Introduction to Computer Systems / Schedule Fall 2015](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/schedule.html)