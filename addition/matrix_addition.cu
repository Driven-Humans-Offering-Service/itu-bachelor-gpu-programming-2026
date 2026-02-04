#include "../utilities/matrix.h"
#include <cstdio>
#include <cuda/cmath>
#include <cuda/std/__cuda/cmath_nvfp16.h>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>
#include <stdlib.h>

Matrices *load_matrices(char *filename1, char *filename2) {

  FILE *file1 = fopen(filename1, "r");
  FILE *file2 = fopen(filename2, "r");

  char *error_message = "";
  if (!file1) {
    sprintf(error_message, "No file with that name %s\n", filename1);
    printf("%s", error_message);
    exit(1);
  } else if (!file2) {
    sprintf(error_message, "No file with that name %s\n", filename2);
    printf("%s", error_message);
    exit(1);
  }

  int size = 0;
  fscanf(file1, "%d", &size);
  int totalsize = size * size;
  Matrices *ma = init_matrices(totalsize);
  read_matrix(file1, ma->m1, totalsize);
  fscanf(file2, "%d", &size);
  read_matrix(file2, ma->m2, totalsize);

  return ma;
}

void read_matrix(FILE *file, float *m, int size) {
  for (int i = 0; i < size; i++) {
    float x = 2;
    fscanf(file, "%f, ", &x);
    m[i] = x;
  }
}

void print_matrix(float *m, int size) {
  for (int i = 0; i < size; i++) {
    printf("[ ");
    for (int j = 0; j < size; j++) {
      printf("%f, ", m[i * size + j]);
    }
    printf("]\n");
  }
}

Matrices *init_matrices(int total_size) {
  Matrices *ma = (Matrices *)malloc(sizeof(Matrices));
  ma->total_size = total_size;
  ma->m1 = (float *)malloc(sizeof(float) * total_size);
  ma->m2 = (float *)malloc(sizeof(float) * total_size);
  ma->result = (float *)malloc(sizeof(float) * total_size);
  return ma;
}

void free_matrices(Matrices *ma) {
  free(ma->m1);
  free(ma->m2);
  free(ma->result);
  free(ma);
}

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

__global__ void matrix_add(const float *m1, const float *m2, float *res,
                           int size) {

  int index = blockDim.x * blockIdx.x + threadIdx.x;

  if (index < size) {
    res[index] = m1[index] + m2[index];
  }
}

int run_cuda(Matrices *ma) {

  float *d_m1, *d_m2, *d_res;
  gpuErrchk(cudaMalloc(&d_m1, ma->total_size));
  gpuErrchk(cudaMalloc(&d_m2, ma->total_size));
  gpuErrchk(cudaMalloc(&d_res, ma->total_size));

  gpuErrchk(cudaMemcpy(d_m1, ma->m1, ma->total_size, cudaMemcpyHostToDevice));
  gpuErrchk(cudaMemcpy(d_m2, ma->m2, ma->total_size, cudaMemcpyHostToDevice));

  int threads = 256;
  int blocks = cuda::ceil_div(ma->total_size, threads);

  printf("threads: %d\n", threads);
  printf("blocks: %d\n", blocks);
  printf("size: %d\n", ma->total_size);

  matrix_add<<<blocks, threads>>>(d_m1, d_m2, d_res, ma->total_size);

  gpuErrchk(
      cudaMemcpy(ma->result, d_res, ma->total_size, cudaMemcpyDeviceToHost));

  return 0;
}

int main(int argc, char **argv) {

  char *path1 = argv[argc - 2];
  char *path2 = argv[argc - 1];

  Matrices *ma = load_matrices(path1, path2);

  run_cuda(ma);

  printf("\n\n\n");
  print_matrix(ma->m1, cuda::std::sqrt(ma->total_size));
  printf("\n\n\n");
  print_matrix(ma->m2, cuda::std::sqrt(ma->total_size));
  printf("\n\n\n");
  print_matrix(ma->result, cuda::std::sqrt(ma->total_size));

  free_matrices(ma);
  return 0;
}
