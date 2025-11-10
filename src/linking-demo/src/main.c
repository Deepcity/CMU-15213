#include <stdio.h>
#include <stdlib.h>
#include "hello.h"
#include "mylib.h"

int main() {
    hello("CSAPP");                 // 来自静态库 libhello.a
    int x = add(3, 4);              // 来自共享库 libmylib.so
    int y = mul(5, 6);

    // 故意触发几次 malloc/free，便于 LD_PRELOAD 演示
    void *p = malloc(128);
    void *q = malloc(256);
    free(p);
    free(q);

    printf("[main] add(3,4)=%d, mul(5,6)=%d\n", x, y);
    return 0;
}
