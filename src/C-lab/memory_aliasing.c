#include <stdio.h>

void sum_row1(double* a, double* b, long n){
		long i, j;
		for (i = 0; i < n; i++) {
			b[i] = 0.0;
			for (j = 0; j < n; j++) {
				printf("a[%ld][%ld] = %f\n", i, j, a[i * n + j]);
				b[i] += a[i * n + j];
			}
			for(j = 0; j < n; j++) {
				printf("b[%ld] = %f\n", j, b[j]);
			}
		}
}

int main(){
	double A[9] = {
		0, 1, 2,
		4, 8, 16,
		32, 64, 128
	};
	double* B = A + 3;

	sum_row1(A, B, 3);

	return 0;
}