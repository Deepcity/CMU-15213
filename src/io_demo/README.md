# I/O Demo Programs

This directory contains a few small utilities used when exploring Chapter 10 (I/O) from CMU 15-213. They illustrate different systems-programming primitives: robust buffered I/O, manual redirection with `dup2`, and querying file metadata with `stat`.

## Building

```bash
make            # builds echo_rio, mini_redirect, statinfo
make clean      # removes binaries and object files
```

The Makefile uses `gcc` with `-Wall -Wextra -O2 -g`. Feel free to override `CC`/`CFLAGS` on the command line if needed.

## Programs

### `echo_rio`

Reads stdin line-by-line using the robust I/O layer in `rio.c`/`rio.h` (the `rio_t` abstraction from CS:APP) and writes each completed line to stdout. Handy for experimenting with short reads/writes or as a safer replacement for naïve `gets`/`fgets` loops.

Usage example:

```bash
./echo_rio < input.txt > output.txt
```

### `mini_redirect`

Emulates the shell syntax `cmd ... > outfile`. It opens/creates the output file, redirects stdout with `dup2`, and then `execvp`s the requested command. Arguments after the outfile are passed verbatim to the child process.

```bash
./mini_redirect out.txt /bin/ls -l /
```

### `statinfo`

Shows POSIX metadata (type, permissions, owner, timestamps, device numbers, etc.) for a single path using `lstat`. This is useful for understanding how `stat` populates its fields or for debugging filesystem behaviors.

```bash
./statinfo /path/to/file
```

## Notes

- `rio.c` provides the reusable robust I/O helpers shared by `echo_rio`.
- All programs only depend on the standard C library and POSIX APIs, so they should compile on any Unix-like system with `gcc` or `clang`.
