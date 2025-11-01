# 4.55

添加非条件跳转并修改预测部分逻辑

逻辑为：

1. 对于条件跳转预测不跳转
2. 对于非条件跳转以及ret预测跳转

实现在 `pipe-nt.hcl` 文件中

## 问题解释

J_YES在问题中被声明为0，但在代码中不存在，这里将J_YES改为UNCOND

代码如下

```hcl
wordsig UNCOND 'C_YES'             # Unconditional transfer
```

以下代码表示条件跳转

```hcl
M_icode == IJXX && M_ifun != UNCOND
```

对于原本的错误预测处理

```hcl
# situation: jxx error
# bool s_jxx_error = (E_icode == IJXX && !e_Cnd);
```

原本处理 e_Cnd 表示预测错误，这里的逻辑是

修改为

```hcl
(E_icode = IJXX && E_ifun != UNCOND && eCnd);
```

这是由于原本的预测是认为预测条件不满足，原本就是不跳转的，因此，e_Cnd表示条件跳转不满足，虽然不应该跳转是对的，但我原本就认为不跳转，所以当e_Cnd说不应该跳转时，代码运行反而才是对的。因此，这里需要不跳转。

具体如何修改为原本就不跳转呢，我们查看f_pc，以及f_predPC

这两个值分别是本次实际使用的取值地址，当前取指指令的预测下一个指令，非jxx与call一般是f_valP

```hcl
@@ -139,7 +139,7 @@
 ## What address should instruction be fetched at
 word f_pc = [
  # Mispredicted branch.  Fetch at incremented PC
- M_icode == IJXX && !M_Cnd : M_valA;
+ M_icode == IJXX && M_ifun != UNCOND && M_Cnd : M_valA;
  # Completion of RET instruction
  W_icode == IRET : W_valM;
  # Default: Use predicted value of PC
    1 : F_predPC;
@@ -183,6 +183,7 @@
 # Predict next value of PC
 word f_predPC = [
  # BNT: This is where you'll change the branch prediction rule
+ f_icode == IJXX && f_ifun != UNCOND : f_valP;
  f_icode in { IJXX, ICALL } : f_valC;
  1 : f_valP;
 ];
```

可见对于原本的f_pc这里原本是直接有 !M_Cnd 的，也就是如果在访存阶段的代码是IJXX，并且条件不满足，认为应该直接取访存阶段的valA

而在修改之后，可见必须是非条件跳转并且条件满足才能进访存的M_valA

而对于f_predPC

这里则是提前（顺序应该是需要保证的）加上了一个非条件跳转的判断

## 修改总览

```sh
--- origin-pipe-nt.hcl 2021-02-25 07:26:33.309259378 +0000
+++ pipe-nt.hcl 2021-02-25 07:26:33.309259378 +0000
@@ -139,7 +139,7 @@
 ## What address should instruction be fetched at
 word f_pc = [
  # Mispredicted branch.  Fetch at incremented PC
- M_icode == IJXX && !M_Cnd : M_valA;
+ M_icode == IJXX && M_ifun != UNCOND && M_Cnd : M_valA;
  # Completion of RET instruction
  W_icode == IRET : W_valM;
  # Default: Use predicted value of PC
@@ -183,6 +183,7 @@
 # Predict next value of PC
 word f_predPC = [
  # BNT: This is where you'll change the branch prediction rule
+ f_icode == IJXX && f_ifun != UNCOND : f_valP;
  f_icode in { IJXX, ICALL } : f_valC;
  1 : f_valP;
 ];
@@ -273,7 +274,11 @@
  !m_stat in { SADR, SINS, SHLT } && !W_stat in { SADR, SINS, SHLT };
 
 ## Generate valA in execute stage
-word e_valA = E_valA;    # Pass valA through stage
+## pass branch address back by M_valA
+word e_valA = [
+ E_icode == IJXX && E_ifun != UNCOND : E_valC;
+ 1 : E_valA;    # Pass valA through stage
+];
 
 ## Set dstE to RNONE in event of not-taken conditional move
 word e_dstE = [
@@ -343,7 +348,7 @@
 
 bool D_bubble =
  # Mispredicted branch
- (E_icode == IJXX && !e_Cnd) ||
+ (E_icode == IJXX && E_ifun != UNCOND && e_Cnd) ||
  # Stalling at fetch while ret passes through pipeline
  # but not condition for a load/use hazard
  !(E_icode in { IMRMOVQ, IPOPQ } && E_dstM in { d_srcA, d_srcB }) &&
@@ -354,7 +359,7 @@
 bool E_stall = 0;
 bool E_bubble =
  # Mispredicted branch
- (E_icode == IJXX && !e_Cnd) ||
+ (E_icode == IJXX && E_ifun != UNCOND && e_Cnd) ||
  # Conditions for a load/use hazard
  E_icode in { IMRMOVQ, IPOPQ } &&
   E_dstM in { d_srcA, d_srcB};
```

## 附录

在 HCL（如 Y86-64 流水线实现）中，`e_Cnd` 是 **Execute 阶段计算出的条件码结果（Condition Evaluate）**，也就是：

> **e_Cnd = ALU计算的分支条件是否满足**

对于 `jxx` 指令而言：

```
e_Cnd = cond(E_ifun, CC)
```

表示当前 `jxx` 的跳转条件是否成立。

- 如果成立 → `e_Cnd = 1`
- 如果不成立 → `e_Cnd = 0`

## REF

1. [ChatGPT - CMU15213](https://chatgpt.com/g/g-p-68e7b4b594a48191a3896754ae062e4f-cmu15213/c/6905b8f0-25d4-8325-b212-f93fc0399815)
2. [4.55 - CASPP 3e 解决方案 --- 4.55 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter4/4.55/)
