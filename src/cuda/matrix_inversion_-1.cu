// Make it faster to find X
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
__device__ bool isInvertible1(float *beta, int n) {
  for (int i = 0; i < n; i++) {
    if (fabsf(beta[IDX(i, i, n)]) < 1e-6f) {
      return false;
    }
  }
  return true;
}

/* N * (N + 1) * (2 * N + 1) / 6 + N * (N - 1) * (2 * N + 5) / 6 + N * (2 * N *
N + 2 * N - 2) N * (8 * N * N + 9 * N - 8) / 3 FLOPs per thread*/
__global__ void inverse_matrix_kernel(float *a, float *res, float *alpha,
                                      float *beta, float *E, float *y, float *x,
                                      int size, int N, int *error) {
  if (threadIdx.x != 0 || blockIdx.x != 0)
    return;

  // LU_decompose
  for (int i = 0; i < N; i++) {
    alpha[IDX(i, i, N)] = 1;
  }

  for (int j = 0; j < N; j++) {
    for (int i = 0; i <= j; i++) {
      float sum = 0.0f;
      for (int k = 0; k < i; k++) {
        sum += alpha[IDX(i, k, N)] * beta[IDX(j, k, N)];
      }
      beta[IDX(j, i, N)] = a[IDX(i, j, N)] - sum;
    }
    for (int i = j + 1; i < N; i++) {
      float sum = 0;
      float *alpha_p = &alpha[IDX(i, 0, N)];
      float *beta_p = &beta[IDX(j, 0, N)];
      for (int k = 0; k < j; k++) {
        sum += alpha_p[k] * beta_p[k];
      }
      alpha[IDX(i, j, N)] = (1 / beta[IDX(j, j, N)]) * (a[IDX(i, j, N)] - sum);
    }
  }
  // transpose beta
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < i; j++) {
      float tmp = beta[IDX(i, j, N)];
      beta[IDX(i, j, N)] = beta[IDX(j, i, N)];
      beta[IDX(j, i, N)] = tmp;
    }
  }

  if (!isInvertible1(beta, N)) {
    *error = 1;
    return;
  }

  // populate identity matrix
  for (int i = 0; i < N; i++) {
    E[IDX(i, i, N)] = 1.0f;
  }

  // solve for each column
  for (int col = 0; col < N; col++) {
    // findY
    float *b = &E[IDX(col, 0, N)];
    y[0] = b[0] / alpha[0];
    for (int i = 1; i < N; i++) {
      float sum = 0.0f;
      for (int j = 0; j < i; j++) {
        sum += alpha[IDX(i, j, N)] * y[j];
      }
      y[i] = (b[i] - sum) / alpha[IDX(i, i, N)];
    }

    // findX
    x[N - 1] = y[N - 1] / beta[IDX(N - 1, N - 1, N)];
    for (int i = N - 2; i >= 0; i--) {
      float sum = 0.0f;
      for (int j = i + 1; j < N; j++) {
        sum += beta[IDX(i, j, N)] * x[j];
      }
      x[i] = (y[i] - sum) / beta[IDX(i, i, N)];
    }

    // copy result column
    for (int j = 0; j < N; j++) {
      res[IDX(col, j, N)] = x[j];
    }
  }

  // transpose result
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < i; j++) {
      float tmp = res[IDX(i, j, N)];
      res[IDX(i, j, N)] = res[IDX(j, i, N)];
      res[IDX(j, i, N)] = tmp;
    }
  }
}

int inverse_matrix(Matrices *ma) {
  float *d_a, *d_res, *d_alpha, *d_beta, *d_E, *d_y, *d_x;
  int *d_error;
  int size = ma->total_size;
  int small_size = ma->size;

  cudaMalloc(&d_error, sizeof(int));
  cudaMalloc(&d_a, size * sizeof(float));
  cudaMalloc(&d_res, size * sizeof(float));
  cudaMalloc(&d_alpha, size * sizeof(float));
  cudaMalloc(&d_beta, size * sizeof(float));
  cudaMalloc(&d_E, size * sizeof(float));
  cudaMalloc(&d_y, small_size * sizeof(float));
  cudaMalloc(&d_x, small_size * sizeof(float));

  cudaMemcpy(d_a, ma->m1, size * sizeof(float), cudaMemcpyHostToDevice);

  inverse_matrix_kernel<<<1, 1>>>(d_a, d_res, d_alpha, d_beta, d_E, d_y, d_x,
                                  size, small_size, d_error);
  cudaDeviceSynchronize();

  cudaMemcpy(ma->result, d_res, size * sizeof(float), cudaMemcpyDeviceToHost);
  int error = 0;
  cudaMemcpy(&error, d_error, sizeof(int), cudaMemcpyDeviceToHost);

  cudaFree(d_a);
  cudaFree(d_res);
  cudaFree(d_alpha);
  cudaFree(d_beta);
  cudaFree(d_E);
  cudaFree(d_y);
  cudaFree(d_x);
  return error;
}

int main(int argc, char **argv) {
  return shared_main(argc, argv, &inverse_matrix);
}
