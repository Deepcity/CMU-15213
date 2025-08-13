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



## REF