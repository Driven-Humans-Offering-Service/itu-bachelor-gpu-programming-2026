#include "matrix.h"
#include <stdio.h>
#include <stdlib.h>

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

    FILE* file1 = fopen(filename1, "r");
    FILE* file2 = fopen(filename2, "r");


    checkPointer(file1, "No file1 provided");
    checkPointer(file2, "No file2 provided");

    int size = 0;
    checkScan(fscanf(file1, "%d", &size), "Failed to read size of first matrix");
    int totalsize = size*size;
    Matrices* ma = init_matrices(totalsize);
    read_matrix(file1, ma->m1, totalsize);
    checkScan(fscanf(file2, "%d", &size), "Failed to read size of second matrix");
    read_matrix(file2, ma->m2, totalsize);

    return ma;
}

void read_matrix(FILE* file, float* m, int size) {
    for (int i = 0; i < size; i++) {
        float x = 2;
        checkScan(fscanf(file, "%f ", &x), "Failed to read int");
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


Matrices* init_matrices(int total_size) {
    Matrices* ma = malloc(sizeof(Matrices));
    ma->total_size = total_size;
    ma->m1 = malloc(sizeof(float)*total_size);
    ma->m2 = malloc(sizeof(float)*total_size);
    ma->result = malloc(sizeof(float)*total_size);
    return ma;
}

void free_matrices(Matrices *ma) {
    free(ma->m1);
    free(ma->m2);
    free(ma->result);
    free(ma);
}
