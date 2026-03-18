//no transpose of beta or result which results in bad locality

#include "../utilities/utils.h"

#define IDX(i,j,size) (((i) * (size)) + (j))
void inverse_matrix(Matrices* ma);


int main(int argc, char** argv) {
    return shared_main(argc, argv, &inverse_matrix);
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
            beta[IDX(i,j,N)] = a[IDX(i,j,N)] - sum;
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

void inverse_matrix(Matrices* ma) {
    float* res = ma->result;
    float* a = ma->m1;
    int size = ma->total_size;
    int small_size = ma->size;
    
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
    free(alpha);
    free(beta);
    free(E);
    free(y);
    free(x);

}
