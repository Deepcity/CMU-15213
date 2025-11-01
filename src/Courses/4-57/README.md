# 4-57

该章节要求我们实现加载转发（load forwarding）

在这里的pipe设计中，只要一条指令执行了load操作，从内存读一个值到寄存器，并且下一台指令要用这个寄存器作为源操作数，就会产生数据冒险，一个stall。

但对于第二条指令只是需要存储寄存器值的情况，是不需要这样的暂停的，考虑下面这段代码示例

```assembly
    mrmovq ..., %rdx
    pushq %rdx
    nop
    pop %rdx
    rmmovq ..., 0(%rdx)
```

在这里，第二条指令`pushq %rdx`需要用到`%rdx`的值，但是这个值是从内存中load进来的，所以会产生一个stall。

这里我们可以观察到实际上我们在访存阶段才会需要%rdx的值，因此可以设计一条转发旁路将m_valM的值转发到流水线寄存器M中的valA字段这种技术叫加载转发（load forward）

注意上面的y86，第4，5行无法应用加载转发，popq指令加载的值是作为下一条指令地址计算的一部分的。在执行阶段就一定要应用到这个值了。

实现在`pipe-lf.hcl`中

## 分析

| instructions | d_srcA | valA used in phase E? | load-forward works? |
| :----------- | :----- | :-------------------- | :------------------ |
| rrmovq       | rA     | Y                     | N                   |
| rmmovq       | rA     | N                     | Y                   |
| opq          | rA     | Y                     | N                   |
| pushq        | rA     | N                     | Y                   |
| ret          | rsp    | N                     | N                   |
| popq         | rsp    | N                     | N                   |

最终可以将

旁路转发总结为

```hcl
 word e_valA = [E_icode in { IRMMOVQ, IPUSHQ } && 
                E_srcA == M_dstM : m_valM;
```

数据冒险总结为

```hcl
E_icode in { IMRMOVQ, IPOPQ } &&
(
  E_dstM == d_srcB ||
  (
    E_dstM == d_srcA && !(D_icode in { IRMMOVQ, IPUSHQ })
  )
);
```

## 修改总览

```sh
--- origin-pipe-lf.hcl 2021-02-25 07:26:33.309259378 +0000
+++ pipe-lf.hcl 2021-02-25 07:26:33.309259378 +0000
@@ -271,6 +271,7 @@
 ##   from memory stage when appropriate
 ## Here it is set to the default used in the normal pipeline
 word e_valA = [
+ E_icode in { IRMMOVQ, IPUSHQ } && E_srcA == M_dstM : m_valM;
  1 : E_valA;  # Use valA from stage pipe register
 ];
 
@@ -329,7 +330,13 @@
 bool F_stall =
  # Conditions for a load/use hazard
  ## Set this to the new load/use condition
- 0 ||
+ E_icode in { IMRMOVQ, IPOPQ } &&
+  (
+    E_dstM == d_srcB ||
+    (
+      E_dstM == d_srcA && !(D_icode in { IRMMOVQ, IPUSHQ })
+    )
+  ) ||
  # Stalling at fetch while ret passes through pipeline
  IRET in { D_icode, E_icode, M_icode };
 
@@ -338,15 +345,29 @@
 bool D_stall = 
  # Conditions for a load/use hazard
  ## Set this to the new load/use condition
- 0; 
+ E_icode in { IMRMOVQ, IPOPQ } &&
+  (
+    E_dstM == d_srcB ||
+    (
+      E_dstM == d_srcA && !(D_icode in { IRMMOVQ, IPUSHQ })
+    )
+  );
 
 bool D_bubble =
  # Mispredicted branch
  (E_icode == IJXX && !e_Cnd) ||
  # Stalling at fetch while ret passes through pipeline
  # but not condition for a load/use hazard
- !(E_icode in { IMRMOVQ, IPOPQ } && E_dstM in { d_srcA, d_srcB }) &&
-   IRET in { D_icode, E_icode, M_icode };
+ !(
+  E_icode in { IMRMOVQ, IPOPQ } &&
+  (
+  E_dstM == d_srcB ||
+  (
+   E_dstM == d_srcA && !(D_icode in { IRMMOVQ, IPUSHQ })
+   )
+  )
+ ) &&
+ IRET in { D_icode, E_icode, M_icode };
 
 # Should I stall or inject a bubble into Pipeline Register E?
 # At most one of these can be true.
@@ -356,7 +377,13 @@
  (E_icode == IJXX && !e_Cnd) ||
  # Conditions for a load/use hazard
  ## Set this to the new load/use condition
- 0;
+ E_icode in { IMRMOVQ, IPOPQ } &&
+ (
+  E_dstM == d_srcB ||
+  (
+   E_dstM == d_srcA && !(D_icode in { IRMMOVQ, IPUSHQ })
+  )
+ );
 
 # Should I stall or inject a bubble into Pipeline Register M?
 # At most one of these can be true.
```

## REF

1. [4.57 - CASPP 3e 解决方案 --- 4.57 - CASPP 3e Solutions](https://dreamanddead.github.io/CSAPP-3e-Solutions/chapter4/4.57/)
