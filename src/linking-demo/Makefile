CC=gcc
CFLAGS=-Iinclude -fPIC -O2 -Wall -Wextra
LDFLAGS=
AR=ar

ALL_BIN=main dlopen_demo
ALL_LIB=libhello.a libmylib.so libmymalloc.so

.PHONY: all clean run dlopen preload

all: $(ALL_LIB) $(ALL_BIN)

# 静态库
libhello.a: src/hello.o
	$(AR) rcs $@ $^

src/hello.o: src/hello.c include/hello.h
	$(CC) $(CFLAGS) -c $< -o $@

# 共享库
libmylib.so: src/mylib.o
	$(CC) -shared -o $@ $^

src/mylib.o: src/mylib.c include/mylib.h
	$(CC) $(CFLAGS) -c $< -o $@

# 预加载劫持库
libmymalloc.so: interpose/mymalloc.o
	$(CC) -shared -o $@ $^ -ldl

interpose/mymalloc.o: interpose/mymalloc.c
	$(CC) $(CFLAGS) -c $< -o $@

# 可执行文件（链接顺序：先对象与依赖，再库；并确保静态库在命令行靠后）
main: src/main.o libhello.a
	$(CC) src/main.o -L. -lhello -L. -lmylib -Wl,-rpath,'$$ORIGIN' -o $@

src/main.o: src/main.c include/hello.h include/mylib.h
	$(CC) $(CFLAGS) -c $< -o $@

# 运行时加载示例
dlopen_demo: src/dlopen_demo.o
	$(CC) $^ -ldl -o $@

src/dlopen_demo.o: src/dlopen_demo.c
	$(CC) $(CFLAGS) -c $< -o $@

# 便捷命令
run: all
	@echo "== Running ./main =="
	@./main

dlopen: all
	@echo "== Running ./dlopen_demo (dlopen libmylib.so) =="
	@./dlopen_demo

preload: all
	@echo "== Running with LD_PRELOAD=./libmymalloc.so ./main =="
	@LD_PRELOAD=./libmymalloc.so ./main

clean:
	rm -f src/*.o interpose/*.o *.a *.so $(ALL_BIN)
