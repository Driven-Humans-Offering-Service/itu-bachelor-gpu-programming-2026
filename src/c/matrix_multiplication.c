#include "../utilities/utils.h"

#define IDX(i,j,size) (i * size + j)

void multiply_matrices(Matrices* ma);


int main(int argc, char** argv) {
    return shared_main(argc, argv, &multiply_matrices);
}

void multiply_matrices(Matrices* ma) {
    register float* res = ma->result;
    register float* m1 = ma->m1;
    register float* m2 = ma->m2;
    register int size = ma->size;
    for (int i = 0; i < size; i++) {
        register float* tmp3 = &(res[i*size]);
        register float* tmp = &(m1[i*size]);
        for (int k = 0; k < size; k++) {
            register float val = tmp[k];
            register float* tmp2 = &(m2[k*size]);
            for (int j = 0; j < size; j++) {
                tmp3[j] += val * tmp2[j];
            }
        }
    }
}
