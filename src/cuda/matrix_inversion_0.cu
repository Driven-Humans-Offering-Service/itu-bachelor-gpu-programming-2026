// Naive implementation
#include "../utilities/utils.h"
#include <cstdio>
#include <cstdlib>
#include <cuda/cmath>

#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>
#include <stdlib.h>

#define PROFILE 0
#define DEBUG 0
#define IDX(i, j, size) (((i) * (size)) + (j))
// Taken from
// https://stackoverflow.com/questions/14038589/what-is-the-canonical-way-to-check-for-errors-using-the-cuda-runtime-api
#define gpuErrchk(ans)                                                         \
  {                                                                            \
    gpuAssert((ans), __FILE__, __LINE__);                                      \
  }

#if PROFILE
#include <stdio.h>

#define PROFILE_CALL(name, ...)                                                \
  do {                                                                         \
    struct timespec _prof_start, _prof_end;                                    \
    clock_gettime(CLOCK_MONOTONIC, &_prof_start);                              \
    __VA_ARGS__;                                                               \
    clock_gettime(CLOCK_MONOTONIC, &_prof_end);                                \
    double _prof_elapsed = (_prof_end.tv_sec - _prof_start.tv_sec) +           \
                           (_prof_end.tv_nsec - _prof_start.tv_nsec) / 1e9;    \
    printf("[PROFILE] %s took %.6f seconds\n", name, _prof_elapsed);           \
  } while (0)

#else

#define PROFILE_CALL(name, ...)                                                \
  do {                                                                         \
    __VA_ARGS__;                                                               \
  } while (0)

#endif

inline void gpuAssert(cudaError_t code, const char *file, int line,
                      bool abort = true) {
  if (code != cudaSuccess) {
    fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file,
            line);
    if (abort)
      exit(code);
  }
}

__global__ void fill_diagonal(float *m, const int N) {
  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row < N && col < N && row == col) {
    m[IDX(row, col, N)] = 1;
  }
}

__global__ void transpose_matrix(const float *m, float *res, const int N) {

  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row < N && col < N) {
    res[IDX(row, col, N)] = m[IDX(col, row, N)];
  }
}

__global__ void find_beta(float *alpha, float *beta, const float *a,
                          const int N, const int j) {
  for (int i = 0; i <= j; i++) {
    float sum = 0.0f;
    for (int k = 0; k < i; k++) {
      sum += alpha[IDX(i, k, N)] * beta[IDX(j, k, N)];
    }
    beta[IDX(j, i, N)] = a[IDX(i, j, N)] - sum;
  }
}

__global__ void find_alpha(float *alpha, float *beta, const float *a,
                           const int N, const int j) {

  int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < N && i > j) {
    float sum = 0;
    float *alpha_p = &alpha[IDX(i, 0, N)];
    float *beta_p = &beta[IDX(j, 0, N)];
    for (int k = 0; k < j; k++) {
      sum += alpha_p[k] * beta_p[k];
    }
    alpha[IDX(i, j, N)] = (1 / beta[IDX(j, j, N)]) * (a[IDX(i, j, N)] - sum);
  }
}

void LU_decompose(float *alpha, float *beta, const float *a,
                  const int total_size, const int N, dim3 block, dim3 grid) {

  float *beta_t;
  gpuErrchk(cudaMalloc(&beta_t, total_size * sizeof(float)));

  fill_diagonal<<<grid, block>>>(alpha, N);

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(total_size, threads);
  for (int j = 0; j < N; j++) {
    cudaDeviceSynchronize();
    find_beta<<<1, 1>>>(alpha, beta_t, a, N, j);
    cudaDeviceSynchronize();
    find_alpha<<<thread_blocks, threads>>>(alpha, beta_t, a, N, j);
  }

  cudaDeviceSynchronize();
  transpose_matrix<<<grid, block>>>(beta_t, beta, N);
  cudaDeviceSynchronize();
  cudaFree(&beta_t);
}

__global__ void findx(float *alpha, float *beta, float *b_full, float *x_full,
                      float *y_full, const int N) {

  int col = blockDim.x * blockIdx.x + threadIdx.x;

  if (col > N)
    return;
  col = IDX(col, 0, N);

  float *y = &y_full[col];
  float *x = &x_full[col];
  float *b = &b_full[col];

  y[0] = b[0] / alpha[0];

  for (int i = 1; i < N; i++) {
    float sum = 0.0f;
    for (int j = 0; j < i; j++) {
      sum += alpha[IDX(i, j, N)] * y[j];
    }
    y[i] = (b[i] - sum) / alpha[IDX(i, i, N)];
  }

  x[N - 1] = y[N - 1] / beta[IDX(N - 1, N - 1, N)];

  for (int i = N - 2; i >= 0; i--) {

    float sum = 0.0f;

    for (int j = i + 1; j < N; j++) {
      sum += beta[IDX(i, j, N)] * x[j];
    }
    x[i] = (y[i] - sum) / beta[IDX(i, i, N)];
  }
}

unsigned long runtime;
void run_cuda(Matrices *ma) {

  unsigned long before = get_time_nanoseconds();

  float *d_m1, *d_res, *alpha, *beta, *E, *y, *x;
  gpuErrchk(cudaMalloc(&d_m1, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_res, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&alpha, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&beta, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&y, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&x, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&E, ma->total_size * sizeof(float)));

  gpuErrchk(cudaMemcpy(d_m1, ma->m1, ma->total_size * sizeof(float),
                       cudaMemcpyHostToDevice));

  cudaEvent_t start, stop;
  gpuErrchk(cudaEventCreate(&start));
  gpuErrchk(cudaEventCreate(&stop));
  gpuErrchk(cudaEventRecord(start));

  dim3 block(32, 32);
  dim3 grid((ma->size + block.x - 1) / block.x,
            (ma->size + block.y - 1) / block.y);

  fill_diagonal<<<grid, block>>>(E, ma->size);

  LU_decompose(alpha, beta, d_m1, ma->total_size, ma->size, block, grid);

  gpuErrchk(cudaDeviceSynchronize());

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(ma->size, threads);
  findx<<<thread_blocks, threads>>>(alpha, beta, E, x, y, ma->size);

  gpuErrchk(cudaDeviceSynchronize());

  transpose_matrix<<<grid, block>>>(x, d_res, ma->size);

  gpuErrchk(cudaEventRecord(stop));
  gpuErrchk(cudaEventSynchronize(stop));
  float ms = 0.0f;
  gpuErrchk(cudaEventElapsedTime(&ms, start, stop));
  kernel_time = ms * 1000000;

  gpuErrchk(cudaMemcpy(ma->result, d_res, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));

  cudaFree(d_m1);
  cudaFree(y);
  cudaFree(d_res);

  unsigned long after = get_time_nanoseconds();
  runtime = after - before;
}

int main(int argc, char **argv) { return shared_main(argc, argv, &run_cuda); }
