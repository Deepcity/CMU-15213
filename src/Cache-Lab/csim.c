#include "cachelab.h"
#include <getopt.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int verbose = 0, s, E, b, S, B;

typedef uint64_t addr_t;
typedef struct {
  int valid;
  unsigned long tag;
  unsigned long long last_used;
} line_t;
typedef line_t *group_t;

typedef enum { MISS, HIT, EVICTION } result_t;
const char *result_str[] = {"miss", "hit", "eviction"};
unsigned int result_cnt[3] = {0, 0, 0};
group_t *cache = NULL;
unsigned long long lru_clock = 0;

FILE *opt(int argc, char **argv);
void usage(void);
void init();
void destroy();
void find_line(addr_t addr, result_t *result);

void usage(void) {
  fprintf(stderr, "Usage: ./csim [-hv] -s <num> -E <num> -b <num> -t <file>\n");
  exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
  FILE *tracefile = opt(argc, argv);
  init();

  char op;
  addr_t addr;
  int size;
  while (fscanf(tracefile, " %c %lx,%d", &op, &addr, &size) == 3) {
    if (op == 'I')
      continue;

    int accesses = (op == 'M') ? 2 : 1;
    if (verbose)
      fprintf(stdout, "%c %lx,%d", op, addr, size);

    for (int i = 0; i < accesses; i++) {
      result_t resultV;
      find_line(addr, &resultV);
      switch (resultV) {
      case HIT:
        result_cnt[HIT]++;
        if (verbose)
          fprintf(stdout, " %s", result_str[HIT]);
        break;
      case MISS:
        result_cnt[MISS]++;
        if (verbose)
          fprintf(stdout, " %s", result_str[MISS]);
        break;
      case EVICTION:
        result_cnt[MISS]++;
        result_cnt[EVICTION]++;
        if (verbose)
          fprintf(stdout, " %s %s", result_str[MISS], result_str[EVICTION]);
        break;
      }
    }

    if (verbose)
      fprintf(stdout, "\n");
  }

  printSummary(result_cnt[HIT], result_cnt[MISS], result_cnt[EVICTION]);
  destroy();
  fclose(tracefile);
  return 0;
}

void init() {
  cache = malloc(S * sizeof(group_t));
  for (int i = 0; i < S; i++) {
    cache[i] = malloc(E * sizeof(line_t));
    for (int j = 0; j < E; j++) {
      cache[i][j].valid = 0;
      cache[i][j].tag = 0;
      cache[i][j].last_used = 0;
    }
  }
}

FILE *opt(int argc, char **argv) {
  FILE *tracefile = NULL;
  int have_s = 0, have_E = 0, have_b = 0;

  for (int c; (c = getopt(argc, argv, "hvs:E:b:t:")) != -1;) {
    switch (c) {
    case 'h': /* print help message */
      usage();
      break;
    case 'v': /* emit additional diagnostic info */
      verbose = 1;
      break;
    case 't': /* 文件 */
      tracefile = fopen(optarg, "r");
      if (tracefile == NULL) {
        perror("Failed to open trace file");
        exit(EXIT_FAILURE);
      }
      break;
    case 's': // 组数的位
      s = atoi(optarg);
      if (s <= 0)
        usage();
      S = 1 << s;
      have_s = 1;
      break;
    case 'E': // 每一组的行数
      E = atoi(optarg);
      if (E <= 0)
        usage();
      have_E = 1;
      break;
    case 'b':
      b = atoi(optarg);
      if (b <= 0)
        usage();
      B = 1 << b;
      have_b = 1;
      break;
    default:
      usage();
      break;
    }
  }
  if (!have_s || !have_E || !have_b || tracefile == NULL) {
    usage();
  }
  return tracefile;
}

void destroy() {
  if (!cache)
    return;
  for (int i = 0; i < S; i++) {
    free(cache[i]);
  }
  free(cache);
  cache = NULL;
}

void find_line(addr_t addr, result_t *result) {
  unsigned long tag = addr >> (s + b);
  unsigned long set_index = (addr >> b) & ((1 << s) - 1);

  group_t group = cache[set_index];
  int hit_index = -1;
  int empty_index = -1;
  int lru_index = 0;
  unsigned long long oldest_use = ULLONG_MAX;

  for (int i = 0; i < E; i++) {
    if (group[i].valid) {
      if (group[i].tag == tag) {
        hit_index = i;
        break;
      }
      if (group[i].last_used < oldest_use) {
        oldest_use = group[i].last_used;
        lru_index = i;
      }
    } else if (empty_index == -1) {
      empty_index = i;
    }
  }

  if (hit_index != -1) {
    *result = HIT;
    group[hit_index].last_used = ++lru_clock;
  } else {
    if (empty_index != -1) {
      *result = MISS;
      group[empty_index].valid = 1;
      group[empty_index].tag = tag;
      group[empty_index].last_used = ++lru_clock;
    } else {
      *result = EVICTION;
      group[lru_index].valid = 1;
      group[lru_index].tag = tag;
      group[lru_index].last_used = ++lru_clock;
    }
  }
}
