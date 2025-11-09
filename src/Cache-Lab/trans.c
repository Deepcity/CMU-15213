/*
 * trans.c - Matrix transpose B = A^T
 *
 * Each transpose function must have a prototype of the form:
 * void trans(int M, int N, int A[N][M], int B[M][N]);
 *
 * A transpose function is evaluated by counting the number of misses
 * on a 1KB direct mapped cache with a block size of 32 bytes.
 */
#include "cachelab.h"
#include <stdio.h>

int is_transpose(int M, int N, int A[N][M], int B[M][N]);

/*
 * transpose_submit - This is the solution transpose function that you
 *     will be graded on for Part B of the assignment. Do not change
 *     the description string "Transpose submission", as the driver
 *     searches for that string to identify the transpose function to
 *     be graded.
 */
char transpose_submit_desc[] = "Transpose submission";
void transpose_submit(int M, int N, int A[N][M], int B[M][N]) {
  int i, j, k, l;
  int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

  if (M == 32 && N == 32) {
    for (i = 0; i < N; i += 8) {
      for (j = 0; j < M; j += 8) {
        for (k = i; k < i + 8; ++k) {
          tmp1 = -1;
          for (l = j; l < j + 8; ++l) {
            if (k == l) {
              tmp0 = A[k][l];
              tmp1 = k;
            } else {
              B[l][k] = A[k][l];
            }
          }
          if (i == j && tmp1 != -1) {
            B[tmp1][tmp1] = tmp0;
          }
        }
      }
    }
    return;
  }

  if (M == 64 && N == 64) {
    for (i = 0; i < N; i += 8) {
      for (j = 0; j < M; j += 8) {
        
        // 读取 A 的 4 行 × 8 列：A[i+k][j+0..7]（每行正好 8 个 int = 1 条
        // line） 写到 B 的两个位置：
        //   左上 4×4：B[j+0..3][i+k]
        //   右上 4×4 的“暂存位”：B[j+0..3][i+k+4]
        for (k = 0; k < 4; ++k) {
          tmp0 = A[i + k][j + 0];
          tmp1 = A[i + k][j + 1];
          tmp2 = A[i + k][j + 2];
          tmp3 = A[i + k][j + 3];

          tmp4 = A[i + k][j + 4];
          tmp5 = A[i + k][j + 5];
          tmp6 = A[i + k][j + 6];
          tmp7 = A[i + k][j + 7];

          B[j + 0][i + k] = tmp0;
          B[j + 1][i + k] = tmp1;
          B[j + 2][i + k] = tmp2;
          B[j + 3][i + k] = tmp3;

          B[j + 0][i + k + 4] = tmp4;
          B[j + 1][i + k + 4] = tmp5;
          B[j + 2][i + k + 4] = tmp6;
          B[j + 3][i + k + 4] = tmp7;
        }

        // 从 B[j+k][i+4..i+7] 读出“暂存”的 4 个数（tmp0..3）
        // 同时读 A[i+4..i+7][j+k]（A 的下 4 行 × 左 4 列）
        // 然后：
        //   把 A[i+4..i+7][j+k] 写回到 B[j+k][i+4..i+7]（完成右上 4×4
        //   的正确转置） 把暂存的 tmp0..3 写到 B[j+4..j+7][i+0..i+3]（完成左下
        //   4×4）
        for (k = 0; k < 4; ++k) {
          tmp0 = B[j + k][i + 4];
          tmp1 = B[j + k][i + 5];
          tmp2 = B[j + k][i + 6];
          tmp3 = B[j + k][i + 7];

          tmp4 = A[i + 4][j + k];
          tmp5 = A[i + 5][j + k];
          tmp6 = A[i + 6][j + k];
          tmp7 = A[i + 7][j + k];

          B[j + k][i + 4] = tmp4;
          B[j + k][i + 5] = tmp5;
          B[j + k][i + 6] = tmp6;
          B[j + k][i + 7] = tmp7;

          B[j + k + 4][i + 0] = tmp0;
          B[j + k + 4][i + 1] = tmp1;
          B[j + k + 4][i + 2] = tmp2;
          B[j + k + 4][i + 3] = tmp3;
        }

        // 顺序读 A[i+4..i+7][j+4..j+7]（仍然按行 8 连续）
        // 顺序写到 B[j+4..j+7][i+4..i+7]
        for (k = 4; k < 8; ++k) {
          tmp0 = A[i + k][j + 4];
          tmp1 = A[i + k][j + 5];
          tmp2 = A[i + k][j + 6];
          tmp3 = A[i + k][j + 7];

          B[j + 4][i + k] = tmp0;
          B[j + 5][i + k] = tmp1;
          B[j + 6][i + k] = tmp2;
          B[j + 7][i + k] = tmp3;
        }
      }
    }
    return;
  }
  
  for (i = 0; i < N; i += 16) {
    for (j = 0; j < M; j += 16) {
      for (k = i; k < N && k < i + 16; ++k) {
        tmp1 = -1;
        for (l = j; l < M && l < j + 16; ++l) {
          if (k == l) {
            tmp0 = A[k][l];
            tmp1 = k;
          } else {
            B[l][k] = A[k][l];
          }
        }
        if (i == j && tmp1 != -1) {
          B[tmp1][tmp1] = tmp0;
        }
      }
    }
  }
}

/*
 * You can define additional transpose functions below. We've defined
 * a simple one below to help you get started.
 */

/*
 * trans - A simple baseline transpose function, not optimized for the cache.
 */
char trans_desc[] = "Simple row-wise scan transpose";
void trans(int M, int N, int A[N][M], int B[M][N]) {
  int i, j, tmp;

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      tmp = A[i][j];
      B[j][i] = tmp;
    }
  }
}

/*
 * registerFunctions - This function registers your transpose
 *     functions with the driver.  At runtime, the driver will
 *     evaluate each of the registered functions and summarize their
 *     performance. This is a handy way to experiment with different
 *     transpose strategies.
 */
void registerFunctions() {
  /* Register your solution function */
  registerTransFunction(transpose_submit, transpose_submit_desc);

  /* Register any additional transpose functions */
  // registerTransFunction(trans, trans_desc);
}

/*
 * is_transpose - This helper function checks if B is the transpose of
 *     A. You can check the correctness of your transpose by calling
 *     it before returning from the transpose function.
 */
int is_transpose(int M, int N, int A[N][M], int B[M][N]) {
  int i, j;

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; ++j) {
      if (A[i][j] != B[j][i]) {
        return 0;
      }
    }
  }
  return 1;
}
