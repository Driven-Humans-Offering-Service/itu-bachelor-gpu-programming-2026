#include "matrix.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef CUDA_CODE
#include <cuda_runtime.h>
#endif

#define IDX(i, j, size) (((i) * (size)) + (j))
#define checkScan(ans, msg)                                                         \
  {                                                                            \
    assertScan((ans), (msg), __FILE__, __LINE__);                                      \
  }
inline void assertScan(int code, const char*
         msg, const char *file, int line){

    if(code == 0) {
        fprintf(stderr, "%s\nDid not read anything, from: %s %d\n", msg, file, line) ;
        exit(code);
    }

}

#define checkErr(ans, msg)                                                         \
  {                                                                            \
    assertError((ans), (msg), __FILE__, __LINE__);                                      \
  }
inline void assertError(int code, const char*
         msg, const char *file, int line){

    if(code) {
        fprintf(stderr, "%s\nGot error, from: %s %d\n", msg, file, line) ;
        exit(code);
    }

}

#define checkPointer(ans, msg)                                                         \
  {                                                                            \
    assertPointerNotNull((ans), (msg), __FILE__, __LINE__);                                      \
  }
inline void assertPointerNotNull(void* ptr, const char*
         msg, const char *file, int line){

    if(!ptr) {
        fprintf(stderr, "%s\nfrom %s %d\n", msg, file, line) ;
        exit(1);
    }

}

Matrices* load_matrices(char *filename1, char* filename2) {

    FILE* file1 = fopen(filename1, "rb");
    FILE* file2 = fopen(filename2, "rb");


    checkPointer(file1, "No file1 provided");
    checkPointer(file2, "No file2 provided");

    int size = 0;
    checkScan(fread(&size, sizeof(int), 1, file1), "Failed to read size of first matrix");
    int totalsize = size*size;
    Matrices* ma = init_matrices(size, totalsize);
    read_matrix(file1, ma->m1, totalsize);
    checkScan(fread(&size, sizeof(int), 1, file2), "Failed to read size of second matrix");
    read_matrix(file2, ma->m2, totalsize);

    return ma;
}

void read_matrix(FILE* file, float* m, int size) {
    for (int i = 0; i < size; i++) {
        float x = 2;
        checkScan(fread(&x, sizeof(float), 1, file), "Failed to read int");
        m[i] = x;
    }
}

void print_matrix(float* m, int size) {
    for (int i = 0; i < size; i++) {
        printf("[ ");
        for (int j = 0; j < size; j++) {
            printf("%f, ", m[i * size + j]);
        }
        printf("]\n");
    }
}

void output_matrix(Matrices *ma, const char *path){
    FILE *file = fopen(path, "w");
    if(!file) {
        fprintf(stderr, "Failed to open file: %s\n", path);
        exit(1);
    }
    
    int size = sqrt(ma->total_size);

    float* result = ma->result;
    for(int i = 0; i < size; i++){
        for (int j = 0; j < size; j++) {
            int res = fprintf(file, "%f ", result[i * size + j]);
            if(res < 1) {
                fprintf(stderr, "Error trying to write to file");
                exit(1);
            }
        }
            int res = fprintf(file, "\n");
            if(res < 1) {
                fprintf(stderr, "Error trying to write to file");
                exit(1);
            }
    }


    checkErr(fclose(file), "Failed to close file, when outputting matrix");
}


Matrices* init_matrices(int size, int total_size) {
    Matrices* ma;
    real_malloc(ma, sizeof(Matrices));
    ma->size = size;
    ma->total_size = total_size;
    real_malloc(ma->m1, sizeof(float)*total_size);
    real_malloc(ma->m2, sizeof(float)*total_size);
    real_malloc(ma->result, sizeof(float)*total_size);
    return ma;
}

void real_malloc(void* ptr, int size) {
#ifdef CUDA_CODE
    cudaMallocHost(&ptr, size);
#else
    ptr = malloc(size);
#endif
}

void free_matrices(Matrices *ma) {
    free(ma->m1);
    free(ma->m2);
    free(ma->result);
    free(ma);
}


int isInvertible(float* beta, int n) {
    for (int i = 0; i < n; i++) {
        if(fabsf(beta[IDX(i,i,n)]) < 1e-6f) {
            return 1;
        }
    }
    return 0;
}
