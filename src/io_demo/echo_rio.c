/* echo_rio: read lines from stdin robustly and echo to stdout */
#include "rio.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    rio_t rio;
    char buf[4096];

    rio_readinitb(&rio, STDIN_FILENO);
    while (1) {
        ssize_t n = rio_readlineb(&rio, buf, sizeof(buf));
        if (n < 0) { perror("rio_readlineb"); return 1; }
        if (n == 0) break; /* EOF */
        if (rio_writen(STDOUT_FILENO, buf, (size_t)n) < 0) {
            perror("rio_writen"); return 1;
        }
    }
    return 0;
}
