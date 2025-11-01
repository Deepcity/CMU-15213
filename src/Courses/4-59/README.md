# 4-59

要求测试前面所构建的53，55，56，57，58五种方式在bubble中的性能优劣并清楚为什么

## 测试

```sh
make psim VERSION={version_code}
```

`pipe_{version_code}.hcl`，需要使用哪一个hcl构建就是用哪一个version_code

| Version Code | Description          | output -v0                              |
| ------------ | -------------------- | --------------------------------------- |
| std          | std                  | CPI: 155 cycles/141 instructions = 1.10 |
| bypass       | 旁路转发             | CPI: 336 cycles/141 instructions = 2.38 |
| nt           | 非条件跳转与条件跳转 | CPI: 165 cycles/141 instructions = 1.17 |
| btfnt        | 前向后向跳转         | CPI: 155 cycles/141 instructions = 1.10 |
| lf           | 加载转发             | CPI: 148 cycles/140 instructions = 1.06 |
| 1w           | popq与pop2           | CPI: 155 cycles/141 instructions = 1.10 |
| full         | full                 | CPI: 155 cycles/141 instructions = 1.10 |

4.47 is the better one

loop part in 4.47

L4:
  mrmovq 8(%rax), %r9
  mrmovq (%rax), %r10
  rrmovq %r9, %r8
  subq %r10, %r8
  jge L3
  rmmovq %r10, 8(%rax)
  rmmovq %r9, (%rax)
50% jge is right, run 5 instructions; 50% jge is wrong, run 7 instructions and 2 nop bubble. so Cycles Per Loop is 50% *5 + (7 + 2)* 50% = 7

loop part in 4.48

L4:
  mrmovq 8(%rax), %r9
  mrmovq (%rax), %r10
  rrmovq %r9, %r8
  subq %r10, %r8
  cmovl %r9, %r11
  cmovl %r10, %r9
  cmovl %r11, %r10
  rmmovq %r9, 8(%rax)
  rmmovq %r10, (%rax)
Cycles Per Loop is 9

loop part in 4.49

L4:
  mrmovq 8(%rax), %r9
  mrmovq (%rax), %r10
  rrmovq %r9, %r8
  rrmovq %r10, %r11
  xorq %r9, %r10
  subq %r11, %r8
  cmovge %r11, %r9
  xorq %r10, %r9
  xorq %r9, %r10
  rmmovq %r9, 8(%rax)
  rmmovq %r10, (%rax)
Cycles Per Loop is 11

## 总结

这里由于版本变化略有不同，看个结果就好，对于循环体的分析，这里算是特例而不是知识点，主要是学会如何分析

## REF

1. [4.59 - CASPP 3e 解决方案 --- 4.59 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter4/4.59/)
