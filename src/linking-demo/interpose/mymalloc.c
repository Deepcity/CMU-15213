#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static void *(*real_malloc)(size_t) = NULL;
static void (*real_free)(void*) = NULL;

static void init_real() {
    if (!real_malloc) {
        real_malloc = (void*(*)(size_t)) dlsym(RTLD_NEXT, "malloc");
    }
    if (!real_free) {
        real_free = (void(*)(void*)) dlsym(RTLD_NEXT, "free");
    }
}

void *malloc(size_t size) {
    init_real();
    void *p = real_malloc(size);
    fprintf(stderr, "[interpose] malloc(%zu) -> %p\n", size, p);
    return p;
}

void free(void *ptr) {
    init_real();
    fprintf(stderr, "[interpose] free(%p)\n", ptr);
    real_free(ptr);
}
