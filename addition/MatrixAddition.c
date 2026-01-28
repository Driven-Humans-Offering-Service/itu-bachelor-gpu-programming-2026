#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void readMatrix(FILE* file, float* m, int size);

void addMatrices(float* res, float* m1, float* m2, int size);

void printMatrix(float* m, int size);

struct timespec tid;
unsigned long runtime;

int main(int argc, char** argv) {
    char* path1 = argv[argc - 2];
    char* path2 = argv[argc - 1];
    FILE* file1 = fopen(path1, "r");
    FILE* file2 = fopen(path2, "r");

    char* error_message = "";
    if (!file1) {
        sprintf(error_message, "No file with that name %s\n", path1);
        printf("%s",error_message);
        return 1;
    } else if (!file2) {
        sprintf(error_message, "No file with that name %s\n", path2);
        printf("%s",error_message);
        return 1;
    }

    int size = 0;
    fscanf(file1, "%d", &size);
    int totalsize = size*size;
    float* matrix1 = malloc(sizeof(float) * totalsize);
    float* matrix2 = malloc(sizeof(float) * totalsize);
    readMatrix(file1, matrix1, totalsize);
    fscanf(file2, "%d", &size);
    readMatrix(file2, matrix2, totalsize);
    //printMatrix(matrix1, size);
    //printMatrix(matrix2, size);
    float* result = malloc(sizeof(float) * totalsize);
    addMatrices(result, matrix1, matrix2, totalsize);
    //printMatrix(result, size);
    free(matrix1);
    free(matrix2);

    printf("The runtime was: %lu ns\n", runtime);
    return 0;
}

void readMatrix(FILE* file, float* m, int size) {
    for (int i = 0; i < size; i++) {
        float x = 2;
        fscanf(file, "%f, ", &x);
        m[i] = x;
    }
}

void printMatrix(float* m, int size) {
    for (int i = 0; i < size; i++) {
        printf("[ ");
        for (int j = 0; j < size; j++) {
            printf("%f, ", m[i * size + j]);
        }
        printf("]\n");
    }
}

void addMatrices(float* res, float* m1, float* m2, int size) {
    clock_gettime(CLOCK_REALTIME,&tid);
    unsigned long before = tid.tv_nsec;
    for (int i = 0; i < size; i++) {
        res[i] = m1[i] + m2[i];
    }
    clock_gettime(CLOCK_REALTIME,&tid);
    unsigned long after = tid.tv_nsec;
    runtime = after - before;
}
