# 4-56

要求修改分支预测逻辑，满足后向分支与前向分支的不同预测逻辑，用于循环的优化

逻辑为：

1. 当 valC < valP，即当要跳转的指令小于当前指令的下一指令时，默认跳转
2. 当 valC >= valP，则不跳转

同时满足55的预测逻辑

传回valC, valP至M寄存器，如果发生预测错误，我们需要判断跳回valC或valP

修改在`pipe-btfnt.hcl`中进行

（使用有符号比较来实现这个测试）

## 修改

首先应该考虑pc与predPC

简单的修改

```sh
@@ -139,7 +139,10 @@
 ## What address should instruction be fetched at
 word f_pc = [
  # Mispredicted branch.  Fetch at incremented PC
- M_icode == IJXX && !M_Cnd : M_valA;
+ # backward taken error
+ M_icode == IJXX && M_ifun != UNCOND && M_valE < M_valA && !M_Cnd : M_valA;
+ # forward not-taken error
+ M_icode == IJXX && M_ifun != UNCOND && M_valE >= M_valA && M_Cnd : M_valE;
  # Completion of RET instruction
  W_icode == IRET : W_valM;
  # Default: Use predicted value of PC
@@ -183,6 +186,8 @@
 # Predict next value of PC
 word f_predPC = [
  # BBTFNT: This is where you'll change the branch prediction rule
+ f_icode == IJXX && f_ifun != UNCOND && f_valC < f_valP : f_valC;
+ f_icode == IJXX && f_ifun != UNCOND && f_valC >= f_valP : f_valP;
  f_icode in { IJXX, ICALL } : f_valC;
  1 : f_valP;
 ];
```

这里的修改主要是对于f_valC以及f_valP的取值，pc预测取值完成在f_pc中，预测失败的处理发生在D,E阶段

这里可见执行的M_valE，这里没有说明该值，这是由于我们需要引入对alu的修改

```sh
 ## Select input A to ALU
 word aluA = [
  E_icode in { IRRMOVQ, IOPQ } : E_valA;
  E_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ } : E_valC;
  E_icode in { ICALL, IPUSHQ } : -8;
  E_icode in { IRET, IPOPQ } : 8;
+ E_icode in { IJXX } : E_valC;
  # Other instructions don't need ALU
 ];
 
@@ -258,6 +266,7 @@
  E_icode in { IRMMOVQ, IMRMOVQ, IOPQ, ICALL, 
        IPUSHQ, IRET, IPOPQ } : E_valB;
  E_icode in { IRRMOVQ, IIRMOVQ } : 0;
+ E_icode in { IJXX } : 0;
  # Other instructions don't need ALU
 ];
```

这里很明确，就是通过alu将valC的值传入了M_valE。而M_valA的值就是就是valP(jxx是这样的)

最后是对预测错误的处理，这里有个小trike，如果e_Cnd的值与我们fc取值的时M_Cnd的值相同，就认为这个预测是错误的

>有点烧脑，这里我们可以从特殊到一般
>
> 对于一个跳转值小于M_valA的命令，我们认为，M_Cnd == 0 （jxx的条件） 时，我们才做跳转到M_valA的操作（跳转到jxx的下一条指令），也就是说，我们默认认为跳转应该是成立的，这时我们发生了jxx的控制冒险，也就是说我们不知道它是不成立的
>
> 如果此时，e_Cnd==0，说明跳转指令的条件判断应该是不成立的，此时就出现了jxx错误。
> 
> 也就是说，出现jxx错误时我们的条件语句中的e_Cnd取值永远是和我们pc的判断条件中的M_Cnd是一致的。

```sh
@@ -343,7 +352,11 @@
 
 bool D_bubble =
  # Mispredicted branch
- (E_icode == IJXX && !e_Cnd) ||
+ # backward taken error or forward not-taken error
+ (
+ (E_icode == IJXX && E_ifun != UNCOND && E_valC < E_valA && !e_Cnd) ||
+ (E_icode == IJXX && E_ifun != UNCOND && E_valC >= E_valA && e_Cnd)
+ ) ||
  # BBTFNT: This condition will change
  # Stalling at fetch while ret passes through pipeline
  # but not condition for a load/use hazard
@@ -355,7 +368,11 @@
 bool E_stall = 0;
 bool E_bubble =
  # Mispredicted branch
- (E_icode == IJXX && !e_Cnd) ||
+ # backward taken error or forward not-taken error
+ (
+ (E_icode == IJXX && E_ifun != UNCOND && E_valC < E_valA && !e_Cnd) ||
+ (E_icode == IJXX && E_ifun != UNCOND && E_valC >= E_valA && e_Cnd)
+ ) ||
  # BBTFNT: This condition will change
  # Conditions for a load/use hazard
  E_icode in { IMRMOVQ, IPOPQ } &&
```
