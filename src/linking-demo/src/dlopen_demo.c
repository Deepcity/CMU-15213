#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

typedef int (*binop_fn)(int,int);

int main() {
    const char *soname = "./libmylib.so";
    void *handle = dlopen(soname, RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 1;
    }
    binop_fn add = (binop_fn)dlsym(handle, "add");
    binop_fn mul = (binop_fn)dlsym(handle, "mul");
    if (!add || !mul) {
        fprintf(stderr, "dlsym failed: %s\n", dlerror());
        return 1;
    }
    printf("[dlopen] add(10,20)=%d, mul(7,8)=%d\n", add(10,20), mul(7,8));
    dlclose(handle);
    return 0;
}
