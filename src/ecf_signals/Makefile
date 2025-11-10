CC      := gcc
CFLAGS  := -Wall -Wextra -O2 -std=c11

.PHONY: all clean
SETJMP_SRC := set_jmp/setjmp_demo.c

.PHONY: all clean
all: signals_demo setjmp_demo

signals_demo: signals_demo.c
	$(CC) $(CFLAGS) -o $@ $<

setjmp_demo: $(SETJMP_SRC)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f signals_demo setjmp_demo
