// Naive multiplication
// total FLOPs : total_size * 2 * size
#include "../utilities/utils.h"
#include "../utilities/matrix.h"
#include <cstdio>
#include <cuda/cmath>

#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>
#include <stdlib.h>

// Taken from
// https://stackoverflow.com/questions/14038589/what-is-the-canonical-way-to-check-for-errors-using-the-cuda-runtime-api
#define gpuErrchk(ans)                                                         \
  {                                                                            \
    gpuAssert((ans), __FILE__, __LINE__);                                      \
  }
inline void gpuAssert(cudaError_t code, const char *file, int line,
                      bool abort = true) {
  if (code != cudaSuccess) {
    fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file,
            line);
    if (abort)
      exit(code);
  }
}

// 2 * size FLOPs per thread
__global__ void matrix_mul(const float *m1, const float *m2, float *res,
                           int size) {
  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int col = blockDim.x * blockIdx.x + threadIdx.x;

  if (row < size && col < size) {
    float sum = 0;
    for (int i = 0; i < size; i++) {
      sum += m1[row * size + i] * m2[i * size + col];
    }
    res[row * size + col] = sum;
  }
}

int run_cuda(Matrices *ma) {

  float *d_m1, *d_m2, *d_res;
  gpuErrchk(cudaMalloc(&d_m1, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_m2, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_res, ma->total_size * sizeof(float)));

  gpuErrchk(cudaMemcpy(d_m1, ma->m1, ma->total_size * sizeof(float),
                       cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_m2, ma->m2, ma->total_size * sizeof(float),
                       cudaMemcpyHostToDevice));

  cudaEvent_t start, stop;
  gpuErrchk(cudaEventCreate(&start));
  gpuErrchk(cudaEventCreate(&stop));
  gpuErrchk(cudaEventRecord(start));
  cudaDeviceProp prop;

  gpuErrchk(cudaGetDeviceProperties_v2(&prop, 0));

  dim3 block(32, 32);
  dim3 grid((ma->size + block.x - 1) / block.x,
            (ma->size + block.y - 1) / block.y);

  matrix_mul<<<grid, block>>>(d_m1, d_m2, d_res, ma->size);

  gpuErrchk(cudaDeviceSynchronize());
  gpuErrchk(cudaEventRecord(stop));
  gpuErrchk(cudaEventSynchronize(stop));
  float ms = 0.0f;
  gpuErrchk(cudaEventElapsedTime(&ms, start, stop));
  kernel_time = ms * 1000000;

  gpuErrchk(cudaMemcpy(ma->result, d_res, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));

  cudaFree(d_m1);
  cudaFree(d_m2);
  cudaFree(d_res);
  return 0;
}

int main(int argc, char **argv) { return shared_main(argc, argv, &run_cuda); }
