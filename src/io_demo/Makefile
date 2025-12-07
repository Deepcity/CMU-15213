CC = gcc
CFLAGS = -Wall -Wextra -O2 -g

ALL = echo_rio mini_redirect statinfo

all: $(ALL)

rio.o: rio.c rio.h
	$(CC) $(CFLAGS) -c rio.c

echo_rio: echo_rio.c rio.o
	$(CC) $(CFLAGS) -o $@ echo_rio.c rio.o

mini_redirect: mini_redirect.c
	$(CC) $(CFLAGS) -o $@ mini_redirect.c

statinfo: statinfo.c
	$(CC) $(CFLAGS) -o $@ statinfo.c

clean:
	rm -f $(ALL) *.o
