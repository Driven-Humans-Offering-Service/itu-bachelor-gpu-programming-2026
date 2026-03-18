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
        for (int j = 0; j < size; j++) {
            for (int k = 0; k < size; k++) {
                res[IDX(i,j,size)] += m1[IDX(i,k,size)] * m2[IDX(k,j,size)];
            }
        }
    }
}
