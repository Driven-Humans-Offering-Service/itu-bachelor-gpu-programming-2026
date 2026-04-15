// naive implementation

#include "../utilities/utils.h"

int add_matrices(Matrices* ma);


int main(int argc, char** argv) {
    return shared_main(argc, argv, &add_matrices);
}

int add_matrices(Matrices* ma) {
    float* res = ma->result;
    float* m1 = ma->m1;
    float* m2 = ma->m2;
    int size = ma->total_size;
    for (int i = 0; i < size; i++) {
        res[i] = m1[i] + m2[i];
    }
    return 0;
}
