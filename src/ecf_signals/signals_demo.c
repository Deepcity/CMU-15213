// signals_demo.c
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

static volatile sig_atomic_t chld_flag = 0; // 仅作标志位

static void safe_write(const char *s) {
    /* 仅在 handler 中使用 write —— 异步信号安全 */
    ssize_t _ = write(STDERR_FILENO, s, strlen(s));
    (void)_;
}

static void sigchld_handler(int sig) {
    (void)sig;
    int saved = errno;             // 保护/恢复 errno
    int status;
    pid_t pid;

    // 回收所有已经退出的子进程，防止僵尸
    while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
        safe_write("[handler] SIGCHLD received, reaped a child.\n");
    }
    chld_flag = 1;                 // 仅设置标志，复杂逻辑放到主循环
    errno = saved;
}

int main(void) {
    struct sigaction sa;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;      // 更平滑地重启被中断的慢系统调用
    sa.sa_handler = sigchld_handler;
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        return 1;
    }

    // 1) 在进入关键区之前，阻塞 SIGCHLD，防止竞态
    sigset_t block, prev, empty;
    sigemptyset(&block);
    sigaddset(&block, SIGCHLD);
    if (sigprocmask(SIG_BLOCK, &block, &prev) == -1) {
        perror("sigprocmask");
        return 1;
    }

    // 2) fork 子进程；子进程“快速退出”模拟竞态
    pid_t pid = fork();
    if (pid == -1) { perror("fork"); return 1; }

    if (pid == 0) {
        // 子进程：做点事，然后以特定码退出
        sleep(1);
        _exit(42); // 用 _exit，避免多次 flush
    }

    // 父进程：关键区（例如：将子进程加入作业表）
    // 这里用打印模拟关键区
    fprintf(stderr, "[parent] critical section: tracking child %d\n", pid);

    // 3) 原子地解除阻塞并等待信号到来
    sigemptyset(&empty);
    while (!chld_flag) {
        // 将掩码临时切到 empty（解除阻塞），并睡眠等待信号
        if (sigsuspend(&empty) == -1 && errno != EINTR) {
            perror("sigsuspend");
            break;
        }
    }

    // 4) 恢复旧的信号屏蔽字
    if (sigprocmask(SIG_SETMASK, &prev, NULL) == -1) {
        perror("sigprocmask restore");
        return 1;
    }

    // 到这里，子进程已经在 handler 中被回收
    fprintf(stderr, "[parent] child reaped inside handler, exiting cleanly.\n");
    return 0;
}
