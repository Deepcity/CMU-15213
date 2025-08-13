## bomblab

要求通过反汇编与debuger，借助主函数源文件实现对6个密码的findout。

## 记录

### 环境与工具
objdump： 反汇编工具
cgdb： debuger工具 gdb+vim
ubuntu 22.04

### bomb 解密

#### prepare stage

生成 bomb .t .s 符号表与反汇编

```shell
objdump -s bomb > bomb.s
objdump -t bomb > bomb.t
```

.t 搜符号表 bomb可以发现 explode_bomb，cgdb调试，并`b explode_bomb`设置断点，避免误bomb。。。随后打断点到`input=read_line()`中。

详细注释在.s 反汇编中。

#### phase_1 stage

首先给phase_1打断点，然后单步调试，通过`dump of assmebler code`的内容直接可以看到一个地址`0x402400`，根据底下的strings_not_equal猜测与字符串有关，通过`x/s 地址`查看字符串格式的内容，可见
```shell
 1│ Dump of assembler code for function phase_1:
 2│    0x0000000000400ee0 <+0>:     sub    $0x8,%rsp
 3├──> 0x0000000000400ee4 <+4>:     mov    $0x402400,%esi
 4│    0x0000000000400ee9 <+9>:     call   0x401338 <strings_not_equal>
 5│    0x0000000000400eee <+14>:    test   %eax,%eax
 6│    0x0000000000400ef0 <+16>:    je     0x400ef7 <phase_1+23>
 7│    0x0000000000400ef2 <+18>:    call   0x40143a <explode_bomb>
 8│    0x0000000000400ef7 <+23>:    add    $0x8,%rsp
 9│    0x0000000000400efb <+27>:    ret
10│ End of assembler dump.
(gdb) x/s 0x402400 
0x402400:       "Border relations with Canada have never been better."
```
初步可猜测其是第一步的答案

> `sub $0x8 %rsp` 这样对栈顶减去一个直接值得情况，通常可认为这是开辟了一个局部变量，在传参过程中使用第一个寄存器大概率表示第一个参数已经被使用了，根据源代码可以猜测，第一个参数大概是phase_1的传参

```shell
Dump of assembler code for function strings_not_equal:
 2│    0x0000000000401338 <+0>:     push   %r12
 3│    0x000000000040133a <+2>:     push   %rbp
 4│    0x000000000040133b <+3>:     push   %rbx
 5│    0x000000000040133c <+4>:     mov    %rdi,%rbx
 6│    0x000000000040133f <+7>:     mov    %rsi,%rbp
 7├──> 0x0000000000401342 <+10>:    call   0x40131b <string_length>
 8│    0x0000000000401347 <+15>:    mov    %eax,%r12d
```

> 这里使用到了`rbx`基址寄存器，虽然该寄存器有这个名字，但是其调用者使用原则使其可以稳定的长期记录数据（不会被随意更改）

很显然，这里是在获取我们输入的参数的长度，并将数据保存到r12d中。

随后的一个结构中

```shell
14│ 	 0x000000000040135c <+36>:    movzbl (%rbx),%eax
15│    0x000000000040135f <+39>:    test   %al,%al
16│    0x0000000000401361 <+41>:    je     0x401388 <strings_not_equal+80>
17│    0x0000000000401363 <+43>:    cmp    0x0(%rbp),%al
18│    0x0000000000401366 <+46>:    je     0x401372 <strings_not_equal+58>
19│    0x0000000000401368 <+48>:    jmp    0x40138f <strings_not_equal+87>
```
这里将rbx指向的字符（8位，一个字节）传入到ax中扩展为32位，并判断是否为空，随后对比一个字节大小的bp与al,即写死的字符与最初传参的第一个字符

```shell
20├──> 0x000000000040136a <+50>:    cmp    0x0(%rbp),%al
21│    0x000000000040136d <+53>:    nopl   (%rax)
22│    0x0000000000401370 <+56>:    jne    0x401396 <strings_not_equal+94>
23│    0x0000000000401372 <+58>:    add    $0x1,%rbx
24│    0x0000000000401376 <+62>:    add    $0x1,%rbp
25│    0x000000000040137a <+66>:    movzbl (%rbx),%eax
26│    0x000000000040137d <+69>:    test   %al,%al
27│    0x000000000040137f <+71>:    jne    0x40136a <strings_not_equal+50>
```
这是一个循环体，其中`26`行为判断退出的条件，即传入的`rbx`字符串在循环迭代中非空。

综上两个接口，可以看出这是一个`while...do`，或者说`for`循环的结构体，用于判断两个字符串是否相同，至此可以判断phase_1的答案是

```shell
Border relations with Canada have never been better. 
```

完成对剩余代码的分析
```shell
b 0x401381
c
```
跳过循环

可以看到一堆jmp以及mov .. to %edx

这里直接给出定义，这里是不同分支的归一并给标志参数赋值！

```shell
28│    0x0000000000401381 <+73>:    mov    $0x0,%edx
29│    0x0000000000401386 <+78>:    jmp    0x40139b <strings_not_equal+99>
30│    0x0000000000401388 <+80>:    mov    $0x0,%edx
31│    0x000000000040138d <+85>:    jmp    0x40139b <strings_not_equal+99>
32│    0x000000000040138f <+87>:    mov    $0x1,%edx
33│    0x0000000000401394 <+92>:    jmp    0x40139b <strings_not_equal+99>
34│    0x0000000000401396 <+94>:    mov    $0x1,%edx
35├──> 0x000000000040139b <+99>:    mov    %edx,%eax
36│    0x000000000040139d <+101>:   pop    %rbx
37│    0x000000000040139e <+102>:   pop    %rbp
38│    0x000000000040139f <+103>:   pop    %r12
39│    0x00000000004013a1 <+105>:   ret    
```
最后复原寄存器的值，并将标志参数rdx返回到ax中（标准返回寄存器）

#### phase_2 stage

phase2中存在一个复杂的开栈记录数据的过程

![img](https://pica.zhimg.com/v2-6cf9a6407eee1098534a64a65f162fe0_1440w.jpg)

phase2中由于超出了6个参数（包括格式），因此出现了栈上传参的方法，常见传参六个寄存器为

| 参数号   | 对应寄存器 |
| ----- | ----- |
| 第 1 个 | RDI   |
| 第 2 个 | RSI   |
| 第 3 个 | RDX   |
| 第 4 个 | RCX   |
| 第 5 个 | R8    |
| 第 6 个 | R9    |

> 在调用read_six_number函数前，程序保存了rsi参数的值，这是第二个参数，为什么不是第一个参数rdi呢？这可能是因为rdi的设置发生在更早的指令中。

## regs ref

rbp base point基址指针寄存器
rbx base 基址寄存器
rsp 栈顶寄存器

rbx，rbp，r12，r13，14，15 用作数据存储，遵循被调用者使用规则，简单说就是随便用，调用子函数之前要备份它，以防他被修改

al寄存器是rax八位寄存器的一部分（地位），还有相似的其他寄存器，例如bl等

| 参数号   | 对应寄存器 |
| ----- | ----- |
| 第 1 个 | RDI   |
| 第 2 个 | RSI   |
| 第 3 个 | RDX   |
| 第 4 个 | RCX   |
| 第 5 个 | R8    |
| 第 6 个 | R9    |

## command ref

### lea

lea Load Effective Address
```assembly
lea  源地址,  目的寄存器
lea  0x10(%rax), %rbx
```
将 %rax + 0x10 这个地址的值，存入 %rbx
<==>rbx = rax + 0x10;

tip:
```assembly
lea  (%rax, %rax, 2), %rdx
```
计算：%rax + %rax * 2 = 3 * %rax
所以 %rdx = 3 * %rax

### cmp

比较两个数据是否相等

eg:
```shell
cmp %eax %r12d
```
就是比较寄存器eax与r12d的值，该命令会更改标志寄存器，常与jne,je搭配使用跳转函数

### movzbl 与 扩展命令

> MovZero-extended Byte to Long 

将一个 8 位的字节（byte） 零扩展为 32 位的整数（long），并存入目标寄存器。

这类“扩展命令”还有很多，基本是零扩展与符号扩展

| 指令      | 含义                              | 源 → 目标  | 示例                |
|---------|---------------------------------|---------|-------------------|
| movzbl  | Move Zero-extended Byte to Long | 8 → 32  | movzbl %al, %eax  |
| movzwl  | Move Zero-extended Word to Long | 16 → 32 | movzwl %ax, %eax  |
| movzbq  | Move Zero-extended Byte to Quad | 8 → 64  | movzbq %al, %rax  |
| movzwq  | Move Zero-extended Word to Quad | 16 → 64 | movzwq %ax, %rax  |
| movzlq  | Move Zero-extended Long to Quad | 32 → 64 | movzlq %ax, %rax  |

### test

对两个操作数进行 按位与（bitwise AND） 运算，但不保存结果，只根据结果 更新标志寄存器（EFLAGS）

equal
```shell
// test %eax, %eax 相当于：
if (eax & eax) {
    // 非零 → ZF = 0
} else {
    // 为零 → ZF = 1
}
```
### nopl

> No Operation Long

不执行任何有意义的操作（does nothing）,只是占用一个时钟周期（极短），用于填充（padding）,主要用于 对齐指令边界 或 填充空间

## gdb ref

```shell
break main          # 在 main 函数设断点
break phase_1       # 在 phase_1 设断点
break *0x401234     # 在指定地址设断点
break file.c:10     # 在文件某行设断点
delete              # 删除所有断点
delete 1            # 删除编号为 1 的断点
disable 1           # 禁用断点
enable 1            # 启用断点
```

```shell
run                 # 开始运行程序
run < input.txt     # 带输入文件运行
continue (或 c)     # 继续执行（跳出断点）
stepi (或 si)       # 单步执行一条汇编指令
nexti (或 ni)       # 单步跳过函数调用（汇编级）
step                # 单步进入函数（源码级）
next                # 单步跳过函数（源码级）
finish              # 运行到当前函数返回
```

```shell
disassemble         # 反汇编当前函数
disas phase_1       # 反汇编 phase_1 函数
info registers      # 查看所有寄存器值
print $rax          # 打印寄存器 rax 的值
x/s $rdi            # 以字符串格式查看 $rdi 指向的内容
x/d $rsp            # 以十进制查看栈顶内容
x/10gx $rsp         # 查看栈顶 10 个 8 字节十六进制值
info frame          # 查看当前栈帧信息
backtrace (或 bt)   # 查看调用栈
```

```shell
print variable      # 打印变量值（如果有符号信息）
print &variable     # 打印变量地址
x/20c array         # 以字符形式查看数组前 20 项
x/6dw input_array   # 查看 6 个整数（如 read_six_numbers 的输入）
```

```shell
break phase_2 if $rdi == 0x402450
break *0x401234 if $rax > 100
```

```shell
run
r
启动程序（可带参数，如
run < input.txt
）
continue
c
继续执行，直到下一个断点或程序结束
step
s
单步执行（进入函数内部）
next
n
单步执行（跳过函数调用）
stepi
si
单步执行一条汇编指令
（关键！用于汇编级调试）
nexti
ni
单步执行一条汇编指令，但不进入函数
finish
fin
运行到当前函数返回（跳出函数）
kill
-
终止当前运行的程序
quit
q
退出 CGDB
```

| 操作                 | 快捷键             |
|--------------------|-----------------|
| 进入命令行窗口（输入 GDB 命令） | 按 i 或 Insert 键  |
| 返回源码/汇编窗口          | 按 Esc 键         |


## references
1. [zhihu CSAPPLab]https://zhuanlan.zhihu.com/p/449879729