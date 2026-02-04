#include "../utilities/matrix.h"
#include <cstdio>
#include <cuda/cmath>
#include <cuda/std/__cuda/cmath_nvfp16.h>
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

struct timespec tid;
unsigned long runtime;

__global__ void matrix_add(const float *m1, const float *m2, float *res,
                           int size) {

  int index = blockDim.x * blockIdx.x + threadIdx.x;

  if (index < size) {
    res[index] = m1[index] + m2[index];
  }
}

int run_cuda(Matrices *ma) {

  clock_gettime(CLOCK_REALTIME, &tid);
  unsigned long before = tid.tv_nsec;

  float *d_m1, *d_m2, *d_res;
  gpuErrchk(cudaMalloc(&d_m1, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_m2, ma->total_size * sizeof(float)));
  gpuErrchk(cudaMalloc(&d_res, ma->total_size * sizeof(float)));

  gpuErrchk(cudaMemcpy(d_m1, ma->m1, ma->total_size * sizeof(float),
                       cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_m2, ma->m2, ma->total_size * sizeof(float),
                       cudaMemcpyHostToDevice));

  int threads = 256;
  int blocks = cuda::ceil_div(ma->total_size, threads);

  printf("threads: %d\n", threads);
  printf("blocks: %d\n", blocks);
  printf("size: %d\n", ma->total_size);

  matrix_add<<<blocks, threads>>>(d_m1, d_m2, d_res, ma->total_size);

  gpuErrchk(cudaMemcpy(ma->result, d_res, ma->total_size * sizeof(float),
                       cudaMemcpyDeviceToHost));

  cudaFree(d_m1);
  cudaFree(d_m2);
  cudaFree(d_res);

  clock_gettime(CLOCK_REALTIME, &tid);
  unsigned long after = tid.tv_nsec;
  runtime = after - before;

  return 0;
}

int main(int argc, char **argv) {

  char *path1 = argv[argc - 2];
  char *path2 = argv[argc - 1];

  Matrices *ma = load_matrices(path1, path2);

  run_cuda(ma);

  /* printf("\n\n\n");
  print_matrix(ma->m1, cuda::std::sqrt(ma->total_size));
  printf("\n\n\n");
  print_matrix(ma->m2, cuda::std::sqrt(ma->total_size));
  printf("\n\n\n");
  print_matrix(ma->result, cuda::std::sqrt(ma->total_size)); */

  free_matrices(ma);
  printf("The runtime was: %lu ns\n", runtime);
  return 0;
}
