// setjmp_demo.c
#include <stdio.h>
#include <setjmp.h>
#include <stdlib.h>

static jmp_buf env;

static void deep_layer3(int which) {
    if (which == 1) {
        // 发现错误，携带错误码 100 回退
        longjmp(env, 100);
    }
    // 正常返回
}

static void deep_layer2(int which) { deep_layer3(which); }
static void deep_layer1(int which) { deep_layer2(which); }

int main(int argc, char **argv) {
    int which = (argc > 1) ? atoi(argv[1]) : 0;

    int rc = setjmp(env);
    if (rc == 0) {
        // 第一次到达这里：布置“异常恢复点”，然后进入深层逻辑
        printf("[main] setjmp returns 0 (first time), run deep call chain...\n");
        deep_layer1(which);
        printf("[main] deep call chain finished normally.\n");
    } else {
        // 通过 longjmp 回来的：rc 就是 longjmp 第二个参数（错误码）
        printf("[main] recovered from error via longjmp, code=%d\n", rc);
    }

    return 0;
}
