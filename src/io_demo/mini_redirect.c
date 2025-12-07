/* mini_redirect: emulate `cmd ... > outfile` using open+dup2+execvp
 * Usage: ./mini_redirect OUTFILE CMD [ARGS...]
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s OUTFILE CMD [ARGS...]\n", argv[0]);
        return 1;
    }

    const char *outfile = argv[1];
    int fd = open(outfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }

    if (dup2(fd, STDOUT_FILENO) < 0) { perror("dup2"); return 1; }
    close(fd); /* no longer needed */

    /* build argv for execvp: shift by 2 (program + outfile) */
    execvp(argv[2], &argv[2]);
    perror("execvp"); /* if returns, it's an error */
    return 1;
}
