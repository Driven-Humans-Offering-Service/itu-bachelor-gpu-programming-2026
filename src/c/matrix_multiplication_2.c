#include "../utilities/utils.h"

#define IDX(i,j,size) (i * size + j)

void multiply_matrices(Matrices* ma);


int main(int argc, char** argv) {
    return shared_main(argc, argv, &multiply_matrices);
}

void multiply_matrices(Matrices* ma) {
    float* res = ma->result;
    float* m1 = ma->m1;
    float* m2 = ma->m2;
    int size = ma->size;
    for (int i = 0; i < size; i++) {
        float* tmp3 = &(res[i*size]);
        float* tmp = &(m1[i*size]);
        for (int k = 0; k < size; k++) {
            float val = tmp[k];
            float* tmp2 = &(m2[k*size]);
            for (int j = 0; j < size; j++) {
                tmp3[j] += val * tmp2[j];
            }
        }
    }
}
