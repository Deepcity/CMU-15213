#include "rio.h"
#include <errno.h>
#include <string.h>

/* robust read n bytes: only returns short count on EOF or error */
ssize_t rio_readn(int fd, void *usrbuf, size_t n) {
    size_t nleft = n;
    ssize_t nread;
    char *bufp = usrbuf;

    while (nleft > 0) {
        if ((nread = read(fd, bufp, nleft)) < 0) {
            if (errno == EINTR) continue; /* interrupted -> retry */
            return -1; /* error */
        } else if (nread == 0) {
            break; /* EOF */
        }
        nleft -= nread;
        bufp  += nread;
    }
    return n - nleft;
}

/* robust write n bytes: never returns short count unless error */
ssize_t rio_writen(int fd, const void *usrbuf, size_t n) {
    size_t nleft = n;
    ssize_t nwritten;
    const char *bufp = usrbuf;

    while (nleft > 0) {
        if ((nwritten = write(fd, bufp, nleft)) <= 0) {
            if (nwritten < 0 && errno == EINTR) continue;
            return -1; /* error */
        }
        nleft -= nwritten;
        bufp  += nwritten;
    }
    return n;
}

/*************** buffered input ***************/

static ssize_t rio_read(rio_t *rp, char *usrbuf, size_t n) {
    int cnt;

    while (rp->rio_cnt <= 0) {  /* refill if buf empty */
        rp->rio_cnt = read(rp->rio_fd, rp->rio_buf, sizeof(rp->rio_buf));
        if (rp->rio_cnt < 0) {
            if (errno != EINTR) return -1;
        } else if (rp->rio_cnt == 0) {
            return 0; /* EOF */
        } else {
            rp->rio_bufptr = rp->rio_buf;
        }
    }

    cnt = n;
    if (rp->rio_cnt < (int)n)
        cnt = rp->rio_cnt;
    memcpy(usrbuf, rp->rio_bufptr, cnt);
    rp->rio_bufptr += cnt;
    rp->rio_cnt    -= cnt;
    return cnt;
}

void rio_readinitb(rio_t *rp, int fd) {
    rp->rio_fd = fd;
    rp->rio_cnt = 0;
    rp->rio_bufptr = rp->rio_buf;
}

/* read up to n bytes, may return short count on EOF */
ssize_t rio_readnb(rio_t *rp, void *usrbuf, size_t n) {
    size_t nleft = n;
    ssize_t nread;
    char *bufp = usrbuf;

    while (nleft > 0) {
        if ((nread = rio_read(rp, bufp, nleft)) < 0)
            return -1;
        else if (nread == 0)
            break; /* EOF */
        nleft -= nread;
        bufp  += nread;
    }
    return n - nleft;
}

/* read a line (at most maxlen-1 bytes), NUL-terminate */
ssize_t rio_readlineb(rio_t *rp, void *usrbuf, size_t maxlen) {
    int n, rc;
    char c, *bufp = usrbuf;

    for (n = 1; n < (int)maxlen; n++) {
        if ((rc = rio_read(rp, &c, 1)) == 1) {
            *bufp++ = c;
            if (c == '\n') break;
        } else if (rc == 0) {
            if (n == 1) return 0; /* EOF, no data */
            else break;           /* EOF, some data */
        } else {
            return -1;            /* error */
        }
    }
    *bufp = '\0';
    return n;
}
