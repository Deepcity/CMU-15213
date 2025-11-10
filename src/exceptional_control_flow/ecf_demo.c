// ecf_demo.c
// Minimal demo: fork -> execve("/bin/echo", ...) -> waitpid
#define _GNU_SOURCE
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;  // 使用当前进程的环境变量，也可以自定义 envp 传给 execve

static void die(const char *msg) {
    int e = errno;
    fprintf(stderr, "[FATAL] %s: %s\n", msg, strerror(e));
    exit(EXIT_FAILURE);
}

int main(void) {
    printf("[parent] pid=%d, about to fork...\n", getpid());
    fflush(stdout);  // 确保 fork 前输出不被重复刷两次

    pid_t pid = fork();
    if (pid < 0) die("fork");

    if (pid == 0) {
        // --- 子进程路径 ---
        // 要执行的程序与参数（argv[0] 必须是程序名约定）
        const char *path = "/usr/bin/env";
        char *const argv_child[] = {
            "env",
            NULL
        };

        // 演示：可以传入自定义环境（不使用继承的 environ）
        // 也可直接传 environ 表示继承父进程环境
        char *const envp[] = {
            "MYVAR=CSAPP",
            NULL
        };

        printf("[child ] pid=%d, ppid=%d, execve(%s)\n", getpid(), getppid(), path);
        fflush(stdout);

        // 用自定义环境：envp；若想继承父环境，改成 execve(path, argv_child, environ)
        if (execve(path, argv_child, envp) == -1) {
            // 只有在 execve 失败时，这里才会执行到
            fprintf(stderr, "[child ] execve failed: %s\n", strerror(errno));
            _exit(127);  // 约定：exec 失败时以 127 退出
        }
        __builtin_unreachable();
    }

    // --- 父进程路径 ---
    int status = 0;
    printf("[parent] forked child pid=%d, waiting...\n", pid);
    fflush(stdout);

    pid_t w = waitpid(pid, &status, 0);
    if (w == -1) die("waitpid");

    if (WIFEXITED(status)) {
        printf("[parent] child %d exited normally with code %d\n",
               w, WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
        printf("[parent] child %d was terminated by signal %d\n",
               w, WTERMSIG(status));
#ifdef WCOREDUMP
        if (WCOREDUMP(status)) printf("[parent] (core dumped)\n");
#endif
    } else if (WIFSTOPPED(status)) {
        printf("[parent] child %d stopped by signal %d\n",
               w, WSTOPSIG(status));
    } else if (WIFCONTINUED(status)) {
        printf("[parent] child %d continued\n", w);
    } else {
        printf("[parent] child %d changed state (unknown)\n", w);
    }

    return 0;
}
