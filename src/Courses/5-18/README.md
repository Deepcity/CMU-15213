# 5-18

![5-18](https://s2.loli.net/2025/11/04/y3XxkCFs9iMTnAJ.png)

assignment:
    1. 混合Horner直接求值伐与优化技术结合，理想情况下应该能达到吞吐量界限

这里Solution中提到了google的gperftools，就采用这个进行测试[gperftools/gperftools：主要 gperftools 存储库 --- gperftools/gperftools: Main gperftools repository](https://github.com/gperftools/gperftools)

这里可见，pprof被go语言重写[Google/pprof：pprof 是一种用于可视化和分析分析分析数据的工具 --- google/pprof: pprof is a tool for visualization and analysis of profiling data](https://github.com/google/pprof)

## Env

- core： i7-11700h

## Answer

详见5.18.c

首先安装go: [下载并安装 - Go 编程语言 --- Download and install - The Go Programming Language](https://go.dev/doc/install)


随后安装`go install github.com/google/pprof@latest`

然后就可以直接使用了，可视化需要安装别的东西，比如graphviz
编译并运行程序，生成`cpu.prof`文件：

这里的[Makefile](Makefile)中已经包含了生成`cpu.prof`文件的命令，来源于[CSAPP-3e-Solutions/site/content/chapter5/code/makefile at master · DreamAndDead/CSAPP-3e-Solutions](https://github.com/DreamAndDead/CSAPP-3e-Solutions/blob/master/site/content/chapter5/code/makefile)

```sh
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Courses/5-18$ make 5.18.prof
gcc -std=c99 5.18.c -lprofiler -o prof.5.18
env CPUPROFILE=/tmp/prof.out ./prof.5.18
PROFILE: interrupts/evictions/bytes = 6/1/344
pprof --text prof.5.18 /tmp/prof.out 
File: prof.5.18
Type: cpu
Showing nodes accounting for 60ms, 100% of 60ms total
      flat  flat%   sum%        cum   cum%
      40ms 66.67% 66.67%       40ms 66.67%  poly_6_3a
      20ms 33.33%   100%       20ms 33.33%  poly
         0     0%   100%       60ms   100%  __libc_start_call_main
         0     0%   100%       60ms   100%  __libc_start_main_impl
         0     0%   100%       60ms   100%  _start
         0     0%   100%       60ms   100%  main
```

结果略微有些难评

## REF
1. [5.18 - CASPP 3e 解决方案 --- 5.18 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter5/5.18/)