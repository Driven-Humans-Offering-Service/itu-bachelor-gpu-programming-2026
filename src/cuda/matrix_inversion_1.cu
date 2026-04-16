// Find LU on the diagonal
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

// 0 FLOPs per thread
__global__ void isInvertibleCuda(float *beta, const int N, int *error) {
  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row < N && col < N && row == col) {
    if (fabsf(beta[IDX(row, col, N)]) < 1e-6f) {
      *error = 1;
    }
  }
}

// 0 FLOPs per thread
__global__ void fill_diagonal(float *m, const int N) {
  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row < N && col < N && row == col) {
    m[IDX(row, col, N)] = 1;
  }
}

// 0 FLOPs per thread
__global__ void transpose_matrix(const float *m, float *res, const int N) {

  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row < N && col < N) {
    res[IDX(row, col, N)] = m[IDX(col, row, N)];
  }
}

// 2 * i + 1 (j >= i) or 2 * j + 3 (j < i) FLOPs per thread
__global__ void find_diag(float *alpha, float *beta, const float *a,
                          const int N, const int x) {
  int y = blockDim.x * blockIdx.x + threadIdx.x;
  int i = x < N ? y : x - (N - 1 - y);
  int j = x < N ? x - y : N - 1 - y;
  if (i < 0 || j < 0 || i >= N || j >= N)
    return;
  if (j >= i) {
    float sum = 0.0f;
    for (int k = 0; k < i; k++) {
      sum += alpha[IDX(i, k, N)] * beta[IDX(j, k, N)];
    }
    beta[IDX(j, i, N)] = a[IDX(i, j, N)] - sum;
  } else {
    float sum = 0;
    float *alpha_p = &alpha[IDX(i, 0, N)];
    float *beta_p = &beta[IDX(j, 0, N)];
    for (int k = 0; k < j; k++) {
      sum += alpha_p[k] * beta_p[k];
    }
    alpha[IDX(i, j, N)] = (1 / beta[IDX(j, j, N)]) * (a[IDX(i, j, N)] - sum);
  }
}
// 1 FLOP per thread
__global__ void multiply(float *alpha, float *beta, float *sum_matrix,
                         const int N, const int d) {
  int x = blockDim.x * blockIdx.x + threadIdx.x;
  int y = blockDim.y * blockIdx.y + threadIdx.y;

  int i = y;
  int j = d - y;
  if (i < 0 || j < 0 || i >= N || j >= N) {
    return;
  }
  if (y > x) {
    if (x >= j - 1 || x >= i - 1) { // Skip the diag before this one
      return;
    }
    sum_matrix[IDX(y, x, N)] = alpha[IDX(i, x, N)] * beta[IDX(j, x, N)];
  }
}

// 0 FLOPs per thread
__global__ void fill(float *p, const int N) {
  for (int i = 0; i < N; i++) {
    p[i] = 0;
  }
}

void print_cuda_matrix(float *m, const int N, const int total_size) {
  gpuErrchk(cudaDeviceSynchronize());
  float *m_host;
  real_malloc((void**)&m_host, total_size * sizeof(float));
  gpuErrchk(cudaMemcpy(m_host, m, total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaDeviceSynchronize());
  print_matrix(m_host, N);
}

void LU_decompose2(float *alpha, float *beta, const float *a,
                   const int total_size, const int N, dim3 block, dim3 grid) {
  float *beta_t;
  gpuErrchk(cudaMalloc(&beta_t, total_size * sizeof(float)));

  fill_diagonal<<<grid, block>>>(alpha, N);

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(N, threads);
  for (int j = 0; j < N * 2; j++) {
    gpuErrchk(cudaDeviceSynchronize());
    find_diag<<<thread_blocks, threads>>>(alpha, beta_t, a, N, j);
  }

  gpuErrchk(cudaDeviceSynchronize());
  transpose_matrix<<<grid, block>>>(beta_t, beta, N);
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaFree(beta_t));
}
// 1 + N * (N - 1) + 2 * (N - 1) + N * (N - 1) + 2 * (N - 1) + 1
// 2 * N * N + 2 * N - 2 FLOPs per thread
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
int run_cuda(Matrices *ma) {

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

  LU_decompose2(alpha, beta, d_m1, ma->total_size, ma->size, block, grid);

  gpuErrchk(cudaDeviceSynchronize());

  int *d_error;
  int h_error = 0;
  gpuErrchk(cudaMalloc(&d_error, sizeof(int)));
  gpuErrchk(cudaMemset(d_error, 0, sizeof(int)));
  isInvertibleCuda<<<grid, block>>>(beta, ma->size, d_error);
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaMemcpy(&h_error, d_error, sizeof(int), cudaMemcpyDeviceToHost));
  cudaFree(d_error);
  if (h_error) {
    cudaFree(d_m1);
    cudaFree(d_res);
    cudaFree(alpha);
    cudaFree(beta);
    cudaFree(y);
    cudaFree(x);
    cudaFree(E);
    return 1;
  }

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

#if DEBUG
  float *L, *U, *y1;
  real_malloc((void**)&L, ma->total_size * sizeof(float));
  real_malloc((void**)&U, ma->total_size * sizeof(float));
  real_malloc((void**)&y1, ma->total_size * sizeof(float));

  gpuErrchk(cudaMemcpy(L, alpha, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaMemcpy(U, beta, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaMemcpy(y1, y, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
#endif
  gpuErrchk(cudaMemcpy(ma->result, d_res, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));

#if DEBUG
  printf("\nU:\n");
  print_matrix(U, ma->size);
  printf("L:\n");
  print_matrix(L, ma->size);
  printf("\ny:\n");
  print_matrix(y1, ma->size);
  printf("\nx:\n");
  print_matrix(ma->result, ma->size);
  printf("\n");
#endif

  cudaFree(d_m1);
  cudaFree(y);
  cudaFree(d_res);

  unsigned long after = get_time_nanoseconds();
  runtime = after - before;
  return 0;
}

int main(int argc, char **argv) { return shared_main(argc, argv, &run_cuda); }
