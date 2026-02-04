#include "matrix.h"
#include <stdlib.h>


Matrices* load_matrices(char *filename1, char* filename2) {

    FILE* file1 = fopen(filename1, "r");
    FILE* file2 = fopen(filename2, "r");

    char* error_message = "";
    if (!file1) {
        sprintf(error_message, "No file with that name %s\n", filename1);
        printf("%s",error_message);
        exit(1);
    } else if (!file2) {
        sprintf(error_message, "No file with that name %s\n", filename2);
        printf("%s",error_message);
        exit(1);
    }

    int size = 0;
    fscanf(file1, "%d", &size);
    int totalsize = size*size;
    Matrices* ma = init_matrices(totalsize);
    read_matrix(file1, ma->m1, totalsize);
    fscanf(file2, "%d", &size);
    read_matrix(file2, ma->m2, totalsize);

    return ma;
}

void read_matrix(FILE* file, float* m, int size) {
    for (int i = 0; i < size; i++) {
        float x = 2;
        fscanf(file, "%f, ", &x);
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
    return ma;
}

void free_matrices(Matrices *ma) {
    free(ma->m1);
    free(ma->m2);
    free(ma);
}
