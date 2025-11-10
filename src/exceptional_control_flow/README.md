# ECF Demo

A compact example program that shows the basic lifecycle of exceptional control flow on Unix-like systems:

1. The parent prints its PID and forks.
2. The child replaces itself with `/bin/echo` via `execve`, supplying a custom environment (`MYVAR=CSAPP`).
3. The parent waits for the child with `waitpid` and reports how it exited (normal exit, signal, stop, etc.).

## Building

```sh
gcc -Wall -Wextra -std=c11 -o ecf_demo ecf_demo.c
```

Adjust the compiler or flags as needed for your environment.

## Running

```sh
./ecf_demo
```

Example output:

```
[parent] pid=12345, about to fork...
[parent] forked child pid=12346, waiting...
[child ] pid=12346, ppid=12345, execve(/bin/echo)
hello from execve MYVAR is visible?
[parent] child 12346 exited normally with code 0
```

The `hello from execve ...` line comes from `/bin/echo`, demonstrating that the child successfully loaded a new program and that the `MYVAR` environment variable is visible within that program.

## Notes

- To inherit the parent's full environment, change the `execve` call in `ecf_demo.c` to pass `environ` instead of the custom `envp` array.
- If `execve` fails you will see a `[child] execve failed ...` message and the child exits with status `127`, which `waitpid` reports in the parent.
- The parent inspects every possible `waitpid` status (`WIFEXITED`, `WIFSIGNALED`, `WIFSTOPPED`, `WIFCONTINUED`) so you can experiment by sending signals to the child before it calls `execve`.
