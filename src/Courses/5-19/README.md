# 5-19

![5-19](https://s2.loli.net/2025/11/04/NpbJ827CgfwA1HZ.png)

结果是一致的
```sh
gcc -std=c99 5.19.c -lprofiler -o prof.5.19
env CPUPROFILE=/tmp/prof.out ./prof.5.19
pprof --text prof.5.19 /tmp/prof.out 
File: prof.5.19
Type: cpu
Showing nodes accounting for 60ms, 100% of 60ms total
      flat  flat%   sum%        cum   cum%
      40ms 66.67% 66.67%       40ms 66.67%  psum_4_1a
      20ms 33.33%   100%       20ms 33.33%  psum1a
         0     0%   100%       60ms   100%  [prof.5.19]
         0     0%   100%       60ms   100%  __libc_start_call_main
         0     0%   100%       60ms   100%  __libc_start_main_impl
         0     0%   100%       60ms   100%  register_tm_clones
```

## REF

1. [5.19 - CASPP 3e 解决方案 --- 5.19 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter5/5.19/)