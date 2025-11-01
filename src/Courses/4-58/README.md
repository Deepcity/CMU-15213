# 4-58

这一节从实际出发，针对寄存器文件有两个写端口，在所有指令中只有popq指令会用到两个端口，针对这一点

![image-20251101192242988](https://s2.loli.net/2025/11/01/IiUbvDPHkW16BF4.png)


设计了一个w_valE，将写回值W_valE与W_valM合并（W_valM是进popq会用到的）。

对于模拟模型来说，可以禁止寄存器端口M，使用如下HCL代码

```hcl
## Disable register port M
## Set M port register ID
word w_dstM = RNONE;

## Set M port value
word w_valM = 0;
```

然后就是需要使得模拟模型在popq以下语句的执行效果上保持一致
```hcl
iaddq $8, %rsp
mrmovq -8(%rsp), rA
```

1. fetch popq instruction twice.
2. first time fetch popq, works like iaddq; second time fetch popq2, works like mrmovq
3. load/use condition should be popq2 not popq.

| phase      | popq rA       | popq2 rA            |
| :--------- | :------------ | :------------------ |
| works like | iadd $8, %rsp | mrmovq -8(%rsp), rA |
| F          | valP = PC     | valP = PC + 2       |
| D          | valB=R[rsp]   | valB=R[rsp]         |
| E          | valE=valB+8   | valE=valB-8         |
| M          |               | valM=M8[valE]       |
| W          | R[rsp]=valE   | R[rA]=valM          |

修改在`pipe-1w.hcl`上进行