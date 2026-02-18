#include <stdio.h>
#include "../utilities/matrix.h"
#include "../utilities/utils.h"

#define IDX(i,j,size) (((i) * (size)) + (j))
void inverse_matrix(float* res, float* a, int size, int small_size);


int main(int argc, char** argv) {
    char* path1 = argv[argc - 2];
    char* path2 = argv[argc - 1];
    int displayRuntime = contains_argument(argc, argv, "--time");
    int print_to_file = contains_argument(argc, argv, "--outputresult");
    int print_result = contains_argument(argc, argv, "--printresult");
    int load_time = contains_argument(argc, argv, "--loadtime");

    unsigned long before_load = get_time_nanoseconds();
    Matrices* ma = load_matrices(path1, path2);
    unsigned long after_load = get_time_nanoseconds();

    int total_size = ma->total_size;
    //printMatrix(matrix1, size);
    //printMatrix(matrix2, size);
    unsigned long before = get_time_nanoseconds();
    inverse_matrix(ma->result, ma->m1, total_size, ma->size);
    unsigned long after = get_time_nanoseconds();
    unsigned long runtime = after - before;
    //printMatrix(result, size);
    if(load_time) 
        printf("load time: %lu\n", after_load - before_load);

    if(displayRuntime) 
        printf("%lu\n", runtime);

    if (print_result) {
        print_matrix(ma->result, ma->size);
    }

    if(print_to_file){
        char* path = argv[print_to_file+1];
        output_matrix(ma, path);
    }
    free_matrices(ma);
    return 0;
}

void transpose_matrix(float* m, int N){
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < i; j++) {
                float tmp = m[IDX(i,j,N)];
                m[IDX(i,j,N)] = m[IDX(j,i,N)];
                m[IDX(j,i,N)] = tmp;
            }
        }
}

void LU_decompose(float* alpha, float* beta, float* a, int N){
        for (int i = 0; i < N; i++) {
            alpha[IDX(i, i, N)] = 1;
        }

        for (int j = 0; j < N; j++) {
            for (int i = 0; i <= j; i++) {
                float sum = 0.0f;
                for (int k = 0; k < i; k++) {
                    sum += alpha[IDX(i,k,N)] * beta[IDX(j,k,N)];
                }
                beta[IDX(j,i,N)] = a[IDX(i,j,N)] - sum;
            }
            for (int i = j + 1; i < N; i++) {
                float sum = 0;
                float* alpha_p = &alpha[IDX(i,0, N)];
                float* beta_p = &beta[IDX(j,0,N)];
                for (int k = 0; k < j; k++) {
                    sum += alpha_p[k] * beta_p[k];
                }
                alpha[IDX(i,j,N)] = (1 / beta[IDX(j,j,N)]) * (a[IDX(i,j,N)] - sum);
            }
        
        }

        transpose_matrix(beta, N);
}

void findY(float* y, float* alpha, float* b, int N){

    y[0] = b[0] / alpha[0];

    for (int i = 1; i < N; i++) {
        float sum = 0.0f;
        for (int j = 0; j < i; j++) {
            sum += alpha[IDX(i,j,N)] * y[j];
        }
        y[i] = (b[i] - sum) / alpha[IDX(i,i,N)];
    }
}


void findX(float* x, float* beta, float* y, int N){

    x[N - 1] = y[N - 1] / beta[IDX(N - 1,N - 1,N)];

    for (int i = N - 2; i >= 0; i--) {

        float sum = 0.0f;

        for (int j = i+1; j < N; j++) {
            sum += beta[IDX(i,j,N)] * x[j];
        }
        x[i] = (y[i] - sum) / beta[IDX(i,i,N)];
    }
}

void populate_identity_matrix(float* E, int N){
        for (int i = 0; i < N; i++) {
            E[IDX(i,i,N)] = 1;
        }
}

void print_float_pointer(char* name, float* p, int N){
        printf("%s:\n", name);
        for(int z = 0; z < N; z++) {
            printf("%f, ", p[z]);
        }
        printf("\n");
}

void inverse_matrix(float* res, float* a, int size, int small_size) {
    float* alpha = malloc(size*sizeof(float));
    float* beta = malloc(size*sizeof(float));
    float* E = calloc(size, sizeof(float));
    LU_decompose(alpha, beta, a, small_size);

    populate_identity_matrix(E, small_size);


    float* y = malloc(small_size * sizeof(float));
    float* x = malloc(small_size * sizeof(float));
    for (int i = 0; i < small_size; i++) {
        findY(y, alpha, &E[IDX(i, 0, small_size)], small_size);
        findX(x, beta, y, small_size);
        for (int j = 0; j < small_size; j++) {
            res[IDX(i, j, small_size)] = x[j];
        }
    }

    transpose_matrix(res, small_size);

    free(alpha);
    free(beta);
    free(E);
    free(y);
    free(x);

}
