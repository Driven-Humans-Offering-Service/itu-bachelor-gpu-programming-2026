#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "../utilities/matrix.h"
#include "../utilities/utils.h"

void add_matrices(float* res, float* m1, float* m2, int size);

struct timespec tid;
unsigned long runtime;

int main(int argc, char** argv) {
    char* path1 = argv[argc - 2];
    char* path2 = argv[argc - 1];
    int displayRuntime = contains_argument(argc, argv, "--time");
    int print_to_file = contains_argument(argc, argv, "--outputresult");

    Matrices* ma = load_matrices(path1, path2);

    int total_size = ma->total_size;
    //printMatrix(matrix1, size);
    //printMatrix(matrix2, size);
    add_matrices(ma->result, ma->m1, ma->m2, total_size);
    //printMatrix(result, size);

    if(displayRuntime) 
        printf("%lu\n", runtime);

    if(print_to_file){
        char* path = argv[print_to_file+1];
        output_matrix(ma, path);
    }
    free_matrices(ma);
    return 0;
}

void add_matrices(float* res, float* m1, float* m2, int size) {
    clock_gettime(CLOCK_REALTIME,&tid);
    unsigned long before = tid.tv_nsec;
    for (int i = 0; i < size; i++) {
        res[i] = m1[i] + m2[i];
    }
    clock_gettime(CLOCK_REALTIME,&tid);
    unsigned long after = tid.tv_nsec;
    runtime = after - before;
}
