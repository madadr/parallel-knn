#include <cuda.h>
#include <math.h>
#include <stdio.h>
#include <random>
#include <iomanip>
#include <iostream>

#define N 16
#define BLOCKSIZE 16

__global__ void minmaxKernel(double *max, double *min, const double *a) {
	__shared__ double maxtile[BLOCKSIZE];
	__shared__ double mintile[BLOCKSIZE];
	
	unsigned int tid = threadIdx.x;
	unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
	maxtile[tid] = a[i];
	mintile[tid] = a[i];
	__syncthreads();
	
	// strided index and non-divergent branch
	for (unsigned int s = 1; s < blockDim.x; s *= 2) {
		int index = 2 * s * tid;
		if (index < blockDim.x) {
			if (maxtile[tid + s] > maxtile[tid])
				maxtile[tid] = maxtile[tid + s];
			if (mintile[tid + s] < mintile[tid])
				mintile[tid] = mintile[tid + s];
		}
		__syncthreads();
	}
	
	if (tid == 0) {
		max[blockIdx.x] = maxtile[0];
		min[blockIdx.x] = mintile[0];
	}
}

int main()
{
    const double a[N*N] = {-8.5, -8.4, -6.8, -4.5, -4.2, -3.9, -3.4, -2.3, 1.5, 3.3, 4.3, 4.7, 6.5, 6.7, 8.0, 9.4,
							-7.3, -6.9, -6.0, -4.8, -4.4, -4.3, -3.8, -5.0, 2.5, 2.9, 5.8, 6.3, 6.7, 7.1, 8.0, 9.0,
							-9.0, -8.2, -6.0, -4.8, -1.7, -1.2, -1.0, 2.1, 2.7, 3.1, 4.0, 4.2, 7.3, 7.9, 8.1, 8.8,
							-9.4, -8.5, -7.2, -6.6, -5.1, -4.4, -3.8, -3.1, -1.9, 2.0, 1.7, 2.5, 3.3, 5.1, 5.7, 6.6,
							-9.6, -8.9, -5.9, -2.5, -2.1, -1.8, -8.0, 1.0, 1.7, 2.3, 3.0, 3.8, 5.3, 6.4, 8.4, 9.9,
							-9.7, -8.8, -8.1, -7.5, -4.9, -4.2, -2.2, -6.0, 2.1, 3.3, 3.5, 5.3, 5.8, 5.9, 6.7, 7.2,
							-9.5, -8.8, -8.3, -8.2, -7.1, -6.5, -4.4, -3.6, -1.1, -6.0, 2.5, 3.8, 4.5, 4.7, 7.1, 9.6,
							-9.6, -8.6, -8.4, -6.9, -5.5, -5.4, -4.8, -3.9, -3.6, -7.0, 9.0, 1.1, 3.4, 4.3, 5.8, 10.0,
							-9.7, -9.3, -6.1, -5.9, -4.9, -4.6, -4.2, -4.1, -1.8, 4.0, 1.4, 4.0, 5.0, 5.2, 7.3, 7.7,
							-7.9, -5.5, -5.0, -4.2, -4.1, -3.7, -1.5,  1.9, 4.5, 5.4, 6.1, 6.5, 6.7, 7.7, 8.1, 9.8,
							-8.6, -7.1, -5.3, -5.1, -4.5, -4.1, -2.7, -2.4, -2.1, -1.3, -7.0, 4.4, 6.7, 7.0, 8.2, 9.7,
							-9.2, -8.7, -7.9, -6.9, -6.7, -5.3, -2.6, -2.2, -1.9, -1.1, 4.0, 1.4, 6.9, 7.1, 7.9, 9.5,
							-9.9, -6.0, -4.8, -3.4, 4.0,   7.0,  1.2,  1.6, 4.5, 5.3, 6.5, 7.3, 7.6, 8.0, 9.0, 9.8,
							-9.6, -9.0, -6.7, -6.5, -4.8, -3.0, -2.4,  1.1, 1.2, 1.4, 4.0, 4.5, 4.9, 5.5, 7.0, 7.3,
							-8.5, -7.7, -7.1, -6.0, -5.1, -4.8, -3.7, -2.8, -1.8, -1.4, 2.0, 2.3, 4.8, 5.3, 6.4, 9.2,
							-9.4, -6.7, -5.2, -4.6, -3.2, -2.3, -1.9, -5.0, 2.0, 2.9, 3.2, 4.3, 4.7, 5.1, 6.4, 6.6};
    double *max;
	double *min;
	float time = 0.0f;
	float seq_time = 0.0f;

	max = (double *)malloc((N)*sizeof(double));
	min = (double *)malloc((N)*sizeof(double));

    minmaxKernel<<<N,1>>>(dev_att, dev_normAtt, dev_min, dev_diff);
    cudaError_t cudaStatus = minmaxKernel(max, min, a);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "minmaxCuda failed!");
        return 1;
    }

    return 0;
}