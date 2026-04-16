// Make it faster to find Y
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

// ceil(cols / BLOCK_SIZE) + log2(BLOCK_SIZE) FLOPs per thread
template <unsigned int BLOCK_SIZE>
__global__ void row_reduce_kernel(const float *__restrict__ input,
                                  float *__restrict__ output, int cols) {
  const int row = blockIdx.x;
  const float *row_ptr = input + (size_t)row * cols;

  float sum = 0.0f;
  for (int i = threadIdx.x; i < cols; i += BLOCK_SIZE) {
    sum += row_ptr[i];
  }

  __shared__ float sdata[BLOCK_SIZE];
  sdata[threadIdx.x] = sum;
  __syncthreads();

  if (BLOCK_SIZE >= 1024) {
    if (threadIdx.x < 512) {
      sdata[threadIdx.x] += sdata[threadIdx.x + 512];
    }
    __syncthreads();
  }
  if (BLOCK_SIZE >= 512) {
    if (threadIdx.x < 256) {
      sdata[threadIdx.x] += sdata[threadIdx.x + 256];
    }
    __syncthreads();
  }
  if (BLOCK_SIZE >= 256) {
    if (threadIdx.x < 128) {
      sdata[threadIdx.x] += sdata[threadIdx.x + 128];
    }
    __syncthreads();
  }
  if (BLOCK_SIZE >= 128) {
    if (threadIdx.x < 64) {
      sdata[threadIdx.x] += sdata[threadIdx.x + 64];
    }
    __syncthreads();
  }

  if (threadIdx.x < 32) {
    float val = sdata[threadIdx.x] + sdata[threadIdx.x + 32];

    for (int offset = 16; offset > 0; offset /= 2)
      val += __shfl_down_sync(0xffffffff, val, offset);

    if (threadIdx.x == 0) {
      output[row] = val;
    }
  }
}

__inline__ void row_reduce(const float *d_input, float *d_output, int rows,
                           int cols) {
  int block_size = 256;
  if (cols <= 64)
    block_size = 64;
  else if (cols <= 128)
    block_size = 128;
  else if (cols <= 256)
    block_size = 256;
  else if (cols <= 512)
    block_size = 512;
  else
    block_size = 256;

  dim3 grid(rows);
  dim3 block(block_size);

  switch (block_size) {
  case 1024:
    row_reduce_kernel<1024><<<grid, block>>>(d_input, d_output, cols);
    break;
  case 512:
    row_reduce_kernel<512><<<grid, block>>>(d_input, d_output, cols);
    break;
  case 256:
    row_reduce_kernel<256><<<grid, block>>>(d_input, d_output, cols);
    break;
  case 128:
    row_reduce_kernel<128><<<grid, block>>>(d_input, d_output, cols);
    break;
  case 64:
    row_reduce_kernel<64><<<grid, block>>>(d_input, d_output, cols);
    break;
  default:
    row_reduce_kernel<256><<<grid, block>>>(d_input, d_output, cols);
    break;
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

// 3 (j >= i) or 5 (j < i) FLOPs per thread
__global__ void find_diag(float *alpha, float *beta, const float *a,
                          const int N, const int d, float *sum_array) {
  int y = blockDim.x * blockIdx.x + threadIdx.x;
  int i = d < N ? y : d - (N - 1 - y);
  int j = d < N ? d - y : N - 1 - y;
  if (i < 0 || j < 0 || i >= N || j >= N)
    return;
  float sum = sum_array[i];
  if (j >= i) {
    if (i >= 1) {
      sum += alpha[IDX(i, i - 1, N)] * beta[IDX(j, i - 1, N)];
    }
    beta[IDX(j, i, N)] = a[IDX(i, j, N)] - sum;
  } else {
    if (j >= 1) {
      sum += alpha[IDX(i, j - 1, N)] * beta[IDX(j, j - 1, N)];
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
  float *m_host = (float *)std::malloc(total_size * sizeof(float));
  gpuErrchk(cudaMemcpy(m_host, m, total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaDeviceSynchronize());
  print_matrix(m_host, N);
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
  for (int d = 0; d < N * 2 - 1; d++) {
    /* printf("\nalpha %d\n", d);
    print_cuda_matrix(alpha, N, total_size);
    printf("\nbeta %d\n", d);
    print_cuda_matrix(beta, N, total_size);
    printf("\nsum_array %d\n", d + 1);
    print_cuda_matrix(sum_array, N, total_size);
    printf("\nsum_matrix %d\n", d + 1);
    print_cuda_matrix(sum_matrix, N, total_size); */
    gpuErrchk(cudaDeviceSynchronize());
    // unsigned long before = get_time_nanoseconds();
    multiply<<<grid, block>>>(alpha, beta_t, sum_matrix, N, d + 1);
    find_diag<<<thread_blocks, threads>>>(alpha, beta_t, a, N, d, sum_array);

    gpuErrchk(cudaDeviceSynchronize());
    row_reduce(sum_matrix, sum_array, N, N);
  }

#if DEBUG
  gpuErrchk(cudaDeviceSynchronize());
  float *sum_matrix_host = (float *)std::malloc(total_size * sizeof(float));
  gpuErrchk(cudaMemcpy(sum_matrix_host, sum_matrix, total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));
  gpuErrchk(cudaDeviceSynchronize());
  printf("sum_matrix\n");
  print_matrix(sum_matrix_host, N);

  /* float *tmp = (float *)malloc(1000 * sizeof(float));
  for (int i = 1; i <= 1000; i++)
    tmp[i - 1] = i;
  float *tmp_d;
  float *res_d;
  float *res = (float *)malloc(sizeof(float));
  gpuErrchk(cudaMalloc(&tmp_d, 1000 * sizeof(float)));
  gpuErrchk(cudaMalloc(&res_d, sizeof(float)));
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaMemcpy(tmp_d, tmp, 1000 * sizeof(float), cudaMemcpyDefault));
  gpuErrchk(cudaDeviceSynchronize());
  reduce6<1>
      <<<thread_blocks, threads, threads * sizeof(float)>>>(tmp_d, res_d, 1000);
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaMemcpy(res, res_d, sizeof(float), cudaMemcpyDeviceToHost));
  gpuErrchk(cudaDeviceSynchronize());
  printf("\nres:%f\n", *res); */

#endif

  gpuErrchk(cudaDeviceSynchronize());
  // printf("Beta time: %lu\n", betaTime);
  transpose_matrix<<<grid, block>>>(beta_t, beta, N);
  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaFree(beta_t));
  gpuErrchk(cudaFree(sum_matrix));
}

// 1 + N * (N - 1) + 2 * (N - 1)
// N * N + N - 1 FLOPs per thread
__global__ void findx(float *alpha, float *beta, float *b_full, float *x_full,
                      float *y_full, const int N) {

  int col = blockDim.x * blockIdx.x + threadIdx.x;

  if (col > N)
    return;
  col = IDX(col, 0, N);

  float *y = &y_full[col];
  float *x = &x_full[col];
  float *b = &b_full[col];

  x[N - 1] = y[N - 1] / beta[IDX(N - 1, N - 1, N)];

  for (int i = N - 2; i >= 0; i--) {

    float sum = 0.0f;

    for (int j = i + 1; j < N; j++) {
      sum += beta[IDX(i, j, N)] * x[j];
    }
    x[i] = (y[i] - sum) / beta[IDX(i, i, N)];
  }
}

// 2 FLOPs per thread
__global__ void add_new_row(float *sum_array, float *alpha, float *y, int size,
                            int i) {
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  int row = blockDim.y * blockIdx.y + threadIdx.y;

  if (row >= size || col >= size)
    return;
  if (row <= i + 1)
    return;

  sum_array[IDX(row, col, size)] +=
      alpha[IDX(row, i, size)] * y[IDX(col, i, size)];
}

// 4 (i >= 1) or 2 (i == 0) FLOPs per thread
__global__ void findy(float *sum_array, float *alpha, float *y, int size, int i,
                      float *b) {
  int col = blockDim.x * blockIdx.x + threadIdx.x;

  if (col >= size)
    return;

  float sum = i >= 1 ? (sum_array[IDX(i, col, size)] +
                        alpha[IDX(i, i - 1, size)] * y[IDX(col, i - 1, size)])
                     : 0;

  y[IDX(col, i, size)] = (b[IDX(i, col, size)] - sum) / alpha[IDX(i, i, size)];
}

unsigned long runtime;
int run_cuda(Matrices *ma) {

  unsigned long before = get_time_nanoseconds();

  float *d_m1, *d_res, *alpha, *beta, *E, *y, *x, *sum_array;
  gpuErrchk(cudaMalloc(&d_m1, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_res, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&alpha, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&beta, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&y, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&x, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&E, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&sum_array, ma->total_size * sizeof(float)));

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
    cudaFree(sum_array);
    return 1;
  }

  int threads = 1024;
  int thread_blocks = cuda::ceil_div(ma->size, threads);
  // findx<<<thread_blocks, threads>>>(alpha, beta, E, x, y, ma->size);
  findy<<<thread_blocks, threads>>>(sum_array, alpha, y, ma->size, 0, E);
  for (int i = 1; i < ma->size; i++) {
    gpuErrchk(cudaDeviceSynchronize());
    add_new_row<<<grid, block>>>(sum_array, alpha, y, ma->size, i - 1);
    findy<<<thread_blocks, threads>>>(sum_array, alpha, y, ma->size, i, E);
  }

  gpuErrchk(cudaDeviceSynchronize());
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
