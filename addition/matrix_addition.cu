#include "../utilities/matrix.h"
#include <cuda/cmath>
#include <cuda/std/__cuda/cmath_nvfp16.h>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>

__global__ void matrix_add(const float *m1, const float *m2, float *res,
                           int size) {

  int index = blockDim.x * blockIdx.x + threadIdx.x;

  if (index < size) {
    res[index] = m1[index] + m2[index];
  }
}

int run_cuda(Matrices *ma) {

  float *d_m1, *d_m2, *d_res;
  cudaMalloc(&d_m1, ma->total_size);
  cudaMalloc(&d_m2, ma->total_size);
  cudaMalloc(&d_res, ma->total_size);

  cudaMemcpy(d_m1, ma->m1, ma->total_size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_m2, ma->m2, ma->total_size, cudaMemcpyHostToDevice);

  int threads = 256;
  int blocks = cuda::ceil_div(ma->total_size, threads);

  matrix_add<<<blocks, threads>>>(d_m1, d_m2, d_res, ma->total_size);

  cudaMemcpy(ma->result, d_res, ma->total_size, cudaMemcpyDeviceToHost);

  return 0;
}

int main(int argc, char **argv) {

  char *path1 = argv[argc - 2];
  char *path2 = argv[argc - 1];

  Matrices *ma = load_matrices(path1, path2);

  run_cuda(ma);

  print_matrix(ma->result, cuda::std::sqrt(ma->total_size));

  return 0;
}
