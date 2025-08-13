## bomblab

要求通过反汇编与debuger，借助主函数源文件实现对6个密码的findout。

## 记录

### 环境与工具
objdump： 反汇编工具
cgdb： debuger工具 gdb+vim
ubuntu 22.04

### bomb 解密

#### prepare

生成 bomb .t .s 符号表与反汇编

```shell
objdump -s bomb > bomb.s
objdump -t bomb > bomb.t
```

.t 搜符号表 bomb可以发现 explode_bomb，cgdb调试，并`b explode_bomb`设置断点，避免误bomb。。。随后打断点到`input=read_line()`中。

```shell
cgdb ./bomb
```

详细注释在.s 反汇编中、

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

| 参数号   | 对应寄存器 |
| ----- | ----- |
| 第 1 个 | RDI   |
| 第 2 个 | RSI   |
| 第 3 个 | RDX   |
| 第 4 个 | RCX   |
| 第 5 个 | R8    |
| 第 6 个 | R9    |

## command ref

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

## references
1. [zhihu CSAPPLab]https://zhuanlan.zhihu.com/p/449879729