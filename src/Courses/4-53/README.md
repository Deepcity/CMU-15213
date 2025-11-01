# 4-53

本节在`pipe-nobypass.hcl`中修改增加旁路功能，避免数据冒险。

## Recall

重新回顾一下一些基本知识点

| 名称       | 中文名 | 本质                                     | 影响阶段     | 作用                     |
| ---------- | ------ | ---------------------------------------- | ------------ | ------------------------ |
| **stall**  | 暂停   | 某个流水线寄存器**保持当前状态**，不更新 | 上游（阻塞） | 防止错误数据流入后续阶段 |
| **bubble** | 气泡   | 向流水线插入一条**空操作（NOP）**        | 下游（清空） | 占位，防止错误指令执行   |

对于`M_dstE`来说，该寄存器应该按如下方式解释
M/m，表示该寄存器是访存阶段的输入/输出，dstE表示该寄存器是执行阶段的目标寄存器



## 数据冒险

```hcl
d_srcA in { e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
d_srcB in { e_dstE, M_dstM, M_dstE, W_dstM, W_dstE }
```

发生数据冒险时，需要在E阶段插入气泡，并且暂停F&D阶段，避免数据冒险。（nobypass的处理）

于是得到数据冒险bool值定义如下

```hcl
# situation: data_hazard
bool s_data_hazard =
  (
    (
      d_srcA != RNONE  &&
      d_srcA in { e_dstE, E_dstM, M_dstM, M_dstE, W_dstM, W_dstE }
    ) ||
    (
      d_srcB != RNONE  &&
      d_srcB in { e_dstE, E_dstM, M_dstM, M_dstE, W_dstM, W_dstE }
    )
  )
```

## ret 情况

保持不变

```hcl
# situation: ret
bool s_ret = IRET in { D_icode, E_icode, M_icode };
# And some command attempt to
```

## jxx error

```hcl
# situation: jxx error
bool s_jxx_error = (E_icode == IJXX && !e_Cnd);
```

| num 数字 | data 数据 | ret 保留 | jxx 杰克斯 | F          | D           | E           | M    | W    |
| :------- | :-------- | :------- | :--------- | :--------- | :---------- | :---------- | :--- | :--- |
| 1        | 0         | 0        | 0          | X          | X           | X           | X    | X    |
| 2        | 0         | 0        | 1          | X          | bubble 气泡 | bubble 气泡 | X    | X    |
| 3        | 0         | 1        | 0          | stall 暂停 | bubble 气泡 | X           | X    | X    |
| 4        | 1         | 0        | 0          | stall 暂停 | stall 暂停  | bubble 气泡 | X    | X    |

情况 1：没有发生任何事情，一切都很好

情况 2：只是 jxx 错误，与书上一致

情况 3：直接 ret，与 book 保持一致

情况 4：只是数据风险，拖延阶段 F 和 D，在阶段 E 插入气泡，M 和 W 保持不变

如果其中两到三件事情同时发生会怎样？

| num 数字 | data 数据 | ret 保留 | jxx 杰克斯 | F          | D           | E           | M    | W    |
| :------- | :-------- | :------- | :--------- | :--------- | :---------- | :---------- | :--- | :--- |
| 1        | 0         | 0        | 0          | X          | X           | X           | X    | X    |
| 2        | 0         | 0        | 1          | X          | bubble 气泡 | bubble 气泡 | X    | X    |
| 3        | 0         | 1        | 0          | stall 暂停 | bubble 气泡 | X           | X    | X    |
| 4        | 1         | 0        | 0          | stall 暂停 | stall 暂停  | bubble 气泡 | X    | X    |
| 5        | 0         | 1        | 1          | X          | bubble 气泡 | bubble 气泡 | X    | X    |
| 6        | 1         | 0        | 1          | X          | bubble 气泡 | bubble 气泡 | X    | X    |
| 7        | 1         | 1        | 0          | stall 暂停 | stall 暂停  | bubble 气泡 | X    | X    |
| 8        | 1         | 1        | 1          | X          | bubble 气泡 | bubble 气泡 | X    | X    |

情况 5：ret 优先于 jxx 错误，与 book 保持一致

情况 6：data hazard 优先于 jxx 错误，与 book 保持一致

情况 7：data hazard 优先于 ret，与 book 保持一致

情况 8：data hazard 优先于 ret 和 jxx 错误，与 book 保持一致

因此最终的解释逻辑如下：

- 三个条件列：
  - `data`：表示**Load-Use（载入-使用）数据冒险**检测到（即译码阶段的指令要读的寄存器，是一条还在内存/执行阶段的 load 要写的寄存器，需要等待内存读回）。
  - `ret`：表示流水线中出现 `ret`（return）指令，需要从栈/内存读出返回地址。
  - `jxx`：表示当前有条件跳转（`jXX`）需要处理（分支相关）。
- 五个阶段列（F、D、E、M、W）：表示对**该阶段采取的动作**：
  - `X`：不做特殊处理（正常推进）。
  - `stall`（暂停）：该阶段**保留当前内容**（不向后推），即不更新该阶段的寄存器（下一周期继续处理同一条指令），通常其它早期阶段也要配合停住，防止错误推进。
  - `bubble`（气泡/插入 nop）：在该阶段插入一个空操作（把该阶段寄存器写成 `nop`），相当于“清掉”当前在该阶段的指令，让后续阶段空转一拍以等待资源或结果。

------

## 控制逻辑的核心思想（以及优先级规则）

实际实现中，管线控制对这三类事件采取不同的动作——并且**三者有优先级**。从你表格的结果可以看到的优先级是：

**`jxx`（分支/跳转）优先级最高 ＞ `data`（load-use）次之 ＞ `ret`（return）最低。**

解释原因（直观）：

- 分支/跳转（`jxx`）通常在译码/执行阶段就能被检测/预测，处理策略是**清掉（bubble）译码与执行阶段**的错误路径指令，而不总是停下 Fetch（允许继续取指进行预测执行）。因此它倾向于插入气泡而不是让整个取指停下来。
- load-use（`data`）是典型必须**暂停 Fetch 与 Decode 一个周期**、并且在 Execute 插入一个气泡以等待 load 完成的情况（也就是必须 stall F、D，bubble E）。
- `ret` 因为返回地址需从内存/栈读出，通常必须**暂停 Fetch**（不能随意去取错的下一条），并在 Decode 阶段插入气泡以等待返回地址确定，但其优先级最低：如果同时出现更高优先级的事件（如 `jxx` 或 `data`），则会被较高优先级的处理覆盖。

------

- **逐行解释（按你表中 1..8 的行）**

> 我用一句话总结每行情形的“发生了什么”和“为什么这样处理”。

- 行 1：`data=0, ret=0, jxx=0`

**动作：所有阶段 X（正常）**
 解释：没有冒险也无控制事件，流水线正常推进。

------

- 行 2：`data=0, ret=0, jxx=1`

**动作：F = X，D = bubble，E = bubble，其它 X。**
 解释：检测到条件跳转/分支（`jxx`）。处理策略是“吐空译码与执行阶段”（把可能是错误路径的指令清掉），让执行阶段计算分支条件并决定下一 PC。Fetch 不停（允许继续取指/预测），所以 F 为 `X`。因此 D、E 插入气泡以防错误推进。

------

- 行 3：`data=0, ret=1, jxx=0`

**动作：F = stall，D = bubble，E = X。**
 解释：只有 `ret`（返回）发生。因为 `ret` 的目标地址需要读内存/栈得到返回地址，不能冒进去取指下一个地址，所以 **必须暂停 Fetch**（F stall）。同时用 `bubble` 清掉 Decode 那里可能进入错误路径的指令（D bubble）。执行阶段继续向前（E X）——也就是让已有指令继续执行，直到返回地址准备好。

------

- 行 4：`data=1, ret=0, jxx=0`

**动作：F = stall，D = stall，E = bubble。**
 解释：典型的 **load-use** 数据冒险：下一条指令需要刚刚发出的 load 的返回值。必须**停一拍 Fetch 与 Decode（F、D stall）**，并在 Execute 插入一个气泡（E bubble）等待 load 在 Memory 阶段把数据弄回来。这是 load-use 的标准处理（等待内存读完）。

------

- 行 5：`data=0, ret=1, jxx=1`

**动作：F = X，D = bubble，E = bubble。**
 解释：`jxx` 与 `ret` 同时检测到，但根据优先级 **`jxx` 优先**，流水线采取 `jxx` 的处理（清掉 D、E），而不是 `ret` 的“停取指”行为。因此 F 不停（X），D/E 被气泡。直观上可以理解为：分支处理策略（气泡）胜过对 `ret` 的停取指需要（在这种实现优先级下）。

------

- 行 6：`data=1, ret=0, jxx=1`

**动作：F = X，D = bubble，E = bubble。**
 解释：`jxx` 与 `data` 同时出现时，表中显示 `jxx` 的策略被采用（即 `jxx` 优先），所以仍然是对 D、E 施加气泡，而不是对 F、D 停止（data 的 stall 被覆盖）。这体现了设计中给 `jxx` 更高优先级的决策——可能是为了简化控制或提高分支预测吞吐。

------

- 行 7：`data=1, ret=1, jxx=0`

**动作：F = stall，D = stall，E = bubble。**
 解释：`data` 与 `ret` 同时出现，优先执行 **`data`（load-use）** 策略。因此我们执行 load-use 必须的停顿（F、D stall）和 E 的气泡。`ret` 的停取指行为被 `data` 的更严格要求覆盖（因为 load-use 必须等待内存返回值，否则语义错乱）。

------

- 行 8：`data=1, ret=1, jxx=1`

**动作：F = X，D = bubble，E = bubble。**
 解释：三者同时出现，`jxx` 优先级最高，所以采用 `jxx` 的处理（D、E 插入气泡），其它事件的 stall 要求被覆盖。

------

- 小结（便于记忆的规则）

- **如果 `jxx` 为真 → 按 `jxx` 的策略：插气泡到 D 和 E（清掉可能的错误路径）；Fetch 不停（允许预测/取指）。**
- **否则如果 `data` 为真 → 按 load-use 策略：停 Fetch 和 Decode（F、D stall），在 Execute 插入气泡（E bubble）。**
- **否则如果只有 `ret` 为真 → 停 Fetch（F stall），在 Decode 插入气泡（D bubble）。**
- **如果都为 0 → 正常推进（都 X）。**

也就是说，表中展现的是一个**基于优先级的冲突解决**结果：`jxx` > `data` > `ret`。这就是为什么在含有多个同时发生事件的行里，结果看起来像“某个事件把另一个事件覆盖了”。

对FED三个阶段的修改，避免数据冒险.

```sh
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/pipe$ make VERSION=bypass
# Building the pipe-bypass.hcl version of PIPE
../misc/hcl2c -n pipe-bypass.hcl < pipe-bypass.hcl > pipe-bypass.c
gcc -Wall -O2 -fcommon -DUSE_INTERP_RESULT -isystem /usr/include/tcl8.6 -I../misc -DHAS_GUI -o psim psim.c pipe-bypass.c \
        ../misc/isa.c -L/usr/lib -ltk -ltcl -lm
psim.c: In function ‘simResetCmd’:
psim.c:855:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  855 |         interp->result = "No arguments allowed";
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:863:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  863 |     interp->result = stat_name(STAT_AOK);
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘simLoadCodeCmd’:
psim.c:874:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  874 |         interp->result = "One argument required";
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:880:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  880 |         interp->result = tcl_msg;
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:887:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  887 |     interp->result = tcl_msg;
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘simLoadDataCmd’:
psim.c:897:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  897 |     interp->result = "Not implemented";
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:903:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  903 |         interp->result = "One argument required";
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:909:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  909 |         interp->result = tcl_msg;
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:913:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  913 |     interp->result = tcl_msg;
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘simRunCmd’:
psim.c:927:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  927 |         interp->result = "At most one argument allowed";
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:934:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  934 |         interp->result = tcl_msg;
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:938:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  938 |     interp->result = stat_name(status);
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘simModeCmd’:
psim.c:947:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  947 |         interp->result = "One argument required";
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:950:5: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  950 |     interp->result = argv[1];
      |     ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:959:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  959 |         interp->result = tcl_msg;
      |         ^~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘signal_register_update’:
psim.c:996:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
  996 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘create_memory_display’:
psim.c:1007:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1007 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c:1022:13: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1022 |             fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |             ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘set_memory’:
psim.c:1057:13: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1057 |             fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |             ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘show_cc’:
psim.c:1071:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1071 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘show_stat’:
psim.c:1083:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1083 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘show_cpi’:
psim.c:1098:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1098 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘signal_sources’:
psim.c:1112:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1112 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘signal_register_clear’:
psim.c:1122:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1122 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘report_line’:
psim.c:1136:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1136 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘report_pc’:
psim.c:1192:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1192 |         fprintf(stderr, "Error Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
psim.c: In function ‘report_state’:
psim.c:1206:9: warning: ‘result’ is deprecated: use Tcl_GetStringResult/Tcl_SetResult [-Wdeprecated-declarations]
 1206 |         fprintf(stderr, "\tError Message was '%s'\n", sim_interp->result);
      |         ^~~~~~~
In file included from /usr/include/tcl8.6/tk.h:19,
                 from psim.c:23:
/usr/include/tcl8.6/tcl.h:514:11: note: declared here
  514 |     char *result TCL_DEPRECATED_API("use Tcl_GetStringResult/Tcl_SetResult");
      |           ^~~~~~
./gen-driver.pl -n 4 -f ncopy.ys > sdriver.ys
../misc/yas sdriver.ys
./gen-driver.pl -n 63 -f ncopy.ys > ldriver.ys
../misc/yas ldriver.ys
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/pipe$ ./benchmark.pl 
        ncopy
0       6
1       6       6.00
2       6       3.00
3       6       2.00
4       6       1.50
5       6       1.20
6       6       1.00
7       6       0.86
8       6       0.75
9       6       0.67
10      6       0.60
11      6       0.55
12      6       0.50
13      6       0.46
14      6       0.43
15      6       0.40
16      6       0.38
17      6       0.35
18      6       0.33
19      6       0.32
20      6       0.30
21      6       0.29
22      6       0.27
23      6       0.26
24      6       0.25
25      6       0.24
26      6       0.23
27      6       0.22
28      6       0.21
29      6       0.21
30      6       0.20
31      6       0.19
32      6       0.19
33      6       0.18
34      6       0.18
35      6       0.17
36      6       0.17
37      6       0.16
38      6       0.16
39      6       0.15
40      6       0.15
41      6       0.15
42      6       0.14
43      6       0.14
44      6       0.14
45      6       0.13
46      6       0.13
47      6       0.13
48      6       0.12
49      6       0.12
50      6       0.12
51      6       0.12
52      6       0.12
53      6       0.11
54      6       0.11
55      6       0.11
56      6       0.11
57      6       0.11
58      6       0.10
59      6       0.10
60      6       0.10
61      6       0.10
62      6       0.10
63      6       0.10
64      6       0.09
Average CPE     0.44
Score   60.0/60.0
ubuntu@VM-0-8-ubuntu:~/learnning_project/CMU-15213/src/Architecture-Lab/sim/pipe$ ./correctness.pl 
Simulating with instruction set simulator yis
        ncopy
0       OK
1       OK
2       OK
3       OK
4       OK
5       OK
6       OK
7       OK
8       OK
9       OK
10      OK
11      OK
12      OK
13      OK
14      OK
15      OK
16      OK
17      OK
18      OK
19      OK
20      OK
21      OK
22      OK
23      OK
24      OK
25      OK
26      OK
27      OK
28      OK
29      OK
30      OK
31      OK
32      OK
33      OK
34      OK
35      OK
36      OK
37      OK
38      OK
39      OK
40      OK
41      OK
42      OK
43      OK
44      OK
45      OK
46      OK
47      OK
48      OK
49      OK
50      OK
51      OK
52      OK
53      OK
54      OK
55      OK
56      OK
57      OK
58      OK
59      OK
60      OK
61      OK
62      OK
63      OK
64      OK
128     OK
192     OK
256     OK
68/68 pass correctness test
```