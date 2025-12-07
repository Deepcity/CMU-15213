/* statinfo: print POSIX metadata of a path */
#define _XOPEN_SOURCE 700
#include <sys/types.h>
#include <sys/sysmacros.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <time.h>

static const char* ftype(mode_t m) {
    if (S_ISREG(m)) return "regular";
    if (S_ISDIR(m)) return "directory";
    if (S_ISCHR(m)) return "char-device";
    if (S_ISBLK(m)) return "block-device";
    if (S_ISFIFO(m)) return "fifo";
    if (S_ISLNK(m)) return "symlink";
    if (S_ISSOCK(m)) return "socket";
    return "unknown";
}

static void print_time(const char *name, time_t t) {
    char buf[64];
    struct tm tm;
    localtime_r(&t, &tm);
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &tm);
    printf("  %-6s : %s\n", name, buf);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s PATH\n", argv[0]);
        return 1;
    }
    struct stat st;
    if (lstat(argv[1], &st) < 0) { perror("lstat"); return 1; }

    printf("File: %s\n", argv[1]);
    printf("Type: %s\n", ftype(st.st_mode));
    printf("Size: %lld bytes\n", (long long)st.st_size);
    printf("Mode: %04o\n", st.st_mode & 07777);
    printf("Links: %lu\n", (unsigned long)st.st_nlink);
    printf("UID:GID: %u:%u\n", st.st_uid, st.st_gid);
#ifdef __linux__
    printf("Inode: %lu\n", (unsigned long)st.st_ino);
    printf("Dev  : %u:%u\n", major(st.st_dev), minor(st.st_dev));
#endif
    print_time("atime", st.st_atime);
    print_time("mtime", st.st_mtime);
    print_time("ctime", st.st_ctime);
    return 0;
}
