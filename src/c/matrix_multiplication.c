#include <stdio.h>
#include "../utilities/matrix.h"
#include "../utilities/utils.h"

#define IDX(i,j,size) (i * size + j)

void multiply_matrices(float* res, float* m1, float* m2, int size);


int main(int argc, char** argv) {
    char* path1 = argv[argc - 2];
    char* path2 = argv[argc - 1];
    int displayRuntime = contains_argument(argc, argv, "--time");
    int print_to_file = contains_argument(argc, argv, "--outputresult");

    Matrices* ma = load_matrices(path1, path2);

    int total_size = ma->total_size;
    //printMatrix(matrix1, size);
    //printMatrix(matrix2, size);
    unsigned long before = get_time_nanoseconds();
    multiply_matrices(ma->result, ma->m1, ma->m2, ma->size);
    unsigned long after = get_time_nanoseconds();
    unsigned long runtime = after - before;
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

void multiply_matrices(register float* res,register float* m1,register float* m2,register int size) {
    for (int i = 0; i < size; i++) {
         register   float* tmp3 = &(res[i*size]);
        register    float* tmp = &(m1[i*size]);
        for (int k = 0; k < size; k++) {
         register   float val = tmp[k];
         register   float* tmp2 = &(m2[k*size]);
            for (int j = 0; j < size; j++) {
                tmp3[j] = val + tmp2[j];
            }
        }
    }
}
