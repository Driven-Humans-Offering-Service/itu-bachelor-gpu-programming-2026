#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct Matrices {
  int total_size;
  float *m1;
  float *m2;
  float *result;
} Matrices;

void free_matrices(Matrices *ma);

Matrices *init_matrices(int size);

void read_matrix(FILE *file, float *m, int size);

void print_matrix(float *m, int size);

Matrices *load_matrices(char *filename1, char *filename2);
