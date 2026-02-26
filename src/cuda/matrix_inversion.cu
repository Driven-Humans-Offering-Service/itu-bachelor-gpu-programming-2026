#include "../utilities/matrix.h"
#include "../utilities/utils.h"
#include <cstdio>
#include <cstdlib>
#include <cuda/cmath>
#include <cuda/std/__cuda/cmath_nvfp16.h>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>
#include <stdlib.h>

#define PROFILE 0
#define DEBUG 1
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

// Taken from
// https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf
template <unsigned int blockSize>
__global__ void reduce6(float *g_idata, float *g_odata, unsigned int n) {
  if (n <= 0)
    return;
  extern __shared__ float sdata[];
  unsigned int tid = threadIdx.x;
  unsigned int i = blockIdx.x * (blockSize * 2) + tid;
  unsigned int gridSize = blockSize * 2 * gridDim.x;
  sdata[tid] = 0;
  while (i < n) {
    sdata[tid] += g_idata[i] + g_idata[i + blockSize];
    i += gridSize;
  }
  __syncthreads();
  if (blockSize >= 512) {
    if (tid < 256) {
      sdata[tid] += sdata[tid + 256];
    }
    __syncthreads();
  }
  if (blockSize >= 256) {
    if (tid < 128) {
      sdata[tid] += sdata[tid + 128];
    }
    __syncthreads();
  }
  if (blockSize >= 128) {
    if (tid < 64) {
      sdata[tid] += sdata[tid + 64];
    }
    __syncthreads();
  }
  if (tid < 32) {

    if (blockSize >= 64)
      sdata[tid] += sdata[tid + 32];
    if (blockSize >= 32)
      sdata[tid] += sdata[tid + 16];
    if (blockSize >= 16)
      sdata[tid] += sdata[tid + 8];
    if (blockSize >= 8)
      sdata[tid] += sdata[tid + 4];
    if (blockSize >= 4)
      sdata[tid] += sdata[tid + 2];
    if (blockSize >= 2)
      sdata[tid] += sdata[tid + 1];
  }
  if (tid == 0)
    g_odata[blockIdx.x] = sdata[0];
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

__global__ void find_diag(float *alpha, float *beta, const float *a,
                          const int N, const int d, float *sum_array) {
  int y = blockDim.x * blockIdx.x + threadIdx.x;
  int i = d < N ? y : d - (N - 1 - y);
  int j = d < N ? d - y : N - 1 - y;
  if (i < 0 || j < 0 || i >= N || j >= N)
    return;
  if (j >= i) {
    float sum = sum_array[IDX(i, 0, N)];
    if (i >= 1) {
      sum += alpha[IDX(i, i - 1, N)] * beta[IDX(j, i - 1, N)];
    }
    beta[IDX(j, i, N)] = a[IDX(i, j, N)] - sum;
  } else {
    float sum = sum_array[IDX(i, 0, N)];
    if (j >= 1) {
      sum += alpha[IDX(i, j - 1, N)] * beta[IDX(j, j - 1, N)];
    }
    alpha[IDX(i, j, N)] = (1 / beta[IDX(j, j, N)]) * (a[IDX(i, j, N)] - sum);
  }
}

__global__ void multiply(float *alpha, float *beta, float *sum_matrix,
                         const int N, const int d) {
  int x = blockDim.x * blockIdx.x + threadIdx.x;
  int y = blockDim.y * blockIdx.y + threadIdx.y;

  int i = d < N ? x : d - (N - 1 - x);
  int j = d < N ? d - x : N - 1 - x;
  if (i < 0 || j < 0 || i >= N || j >= N)
    return;
  if (j < i) {
    if (x >= j - 1)
      return;
    sum_matrix[IDX(x, y, N)] = alpha[IDX(i, x, N)] * beta[IDX(j, x, N)];
  }
}

void LU_decompose2(float *alpha, float *beta, const float *a,
                   const int total_size, const int N, dim3 block, dim3 grid) {
  float *beta_t;
  float *sum_matrix;
  float *sum_array;
  gpuErrchk(cudaMalloc(&beta_t, total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&sum_matrix, total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&sum_array, N * sizeof(float)));

  fill_diagonal<<<grid, block>>>(alpha, N);

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(N, threads);
  // unsigned long betaTime = 0;
  for (int d = 0; d < N * 2; d++) {
    gpuErrchk(cudaDeviceSynchronize());
    // unsigned long before = get_time_nanoseconds();
    multiply<<<thread_blocks, threads>>>(alpha, beta_t, sum_matrix, N, d);
    find_diag<<<thread_blocks, threads>>>(alpha, beta_t, a, N, d, sum_array);

    gpuErrchk(cudaDeviceSynchronize());
    for (int i = 0; i < N; i++) {
      int j = d < N ? d - i : N - 1 - i;
      reduce6<1024><<<thread_blocks, threads, threads * sizeof(float)>>>(
          sum_matrix, &sum_array[i], i < j ? i - 2 : j - 2);
      printf("%d\n", i);
      gpuErrchk(cudaDeviceSynchronize());
    }
  }

#if DEBUG
  gpuErrchk(cudaDeviceSynchronize());
  float *sum_matrix_host = (float *)std::malloc(total_size * sizeof(float));
  gpuErrchk(cudaMemcpy(sum_matrix_host, sum_matrix, total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaDeviceSynchronize());
  printf("sum_matrix\n");
  print_matrix(sum_matrix_host, N);
#endif

  gpuErrchk(cudaDeviceSynchronize());
  // printf("Beta time: %lu\n", betaTime);
  transpose_matrix<<<grid, block>>>(beta_t, beta, N);
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaFree(beta_t));
  gpuErrchk(cudaFree(sum_matrix));
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

  dim3 block(32, 32);
  dim3 grid((ma->size + block.x - 1) / block.x,
            (ma->size + block.y - 1) / block.y);

  fill_diagonal<<<grid, block>>>(E, ma->size);

  LU_decompose2(alpha, beta, d_m1, ma->total_size, ma->size, block, grid);

  gpuErrchk(cudaDeviceSynchronize());

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(ma->size, threads);
  findx<<<thread_blocks, threads>>>(alpha, beta, E, x, y, ma->size);

  gpuErrchk(cudaDeviceSynchronize());

  transpose_matrix<<<grid, block>>>(x, d_res, ma->size);

#if DEBUG
  float *L, *U, *y1;
  L = (float *)std::malloc(ma->total_size * sizeof(float));
  U = (float *)std::malloc(ma->total_size * sizeof(float));
  y1 = (float *)std::malloc(ma->total_size * sizeof(float));

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
  printf("L:\n");
  print_matrix(L, ma->size);
  printf("\nU:\n");
  print_matrix(U, ma->size);
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

int main(int argc, char **argv) {

  char *path1 = argv[argc - 2];
  char *path2 = argv[argc - 1];
  int displayRuntime = contains_argument(argc, argv, "--time");
  int print_to_file = contains_argument(argc, argv, "--outputresult");

  Matrices *ma = load_matrices(path1, path2);

  unsigned long s = get_time_nanoseconds();
  cudaEvent_t start, stop;
  gpuErrchk(cudaEventCreate(&start));
  gpuErrchk(cudaEventCreate(&stop));

  gpuErrchk(cudaEventRecord(start));
  run_cuda(ma);
  gpuErrchk(cudaEventRecord(stop));
  gpuErrchk(cudaEventSynchronize(stop));
  float runtime_ms = 0.0f;
  gpuErrchk(cudaEventElapsedTime_v2(&runtime_ms, start, stop));
  unsigned long a = get_time_nanoseconds();

  if (displayRuntime)
    // printf("%lu\n", (unsigned long)(runtime_ms * 1e6));
    printf("%lu\n", a - s);

  if (print_to_file) {
    char *path = argv[print_to_file + 1];
    output_matrix(ma, path);
  }
  free_matrices(ma);
  return 0;
}
