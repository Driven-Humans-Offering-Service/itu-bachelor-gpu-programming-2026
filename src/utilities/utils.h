#ifdef __cplusplus
extern "C" {
#endif

#include "./matrix.h"

#ifdef CUDA_CODE
extern unsigned long kernel_time;
#endif
int contains_argument(int argc, char **argv, const char *arg);
unsigned long get_time_nanoseconds();
int shared_main(int argc, char **argv, void (*fptr)(Matrices *));

#ifdef __cplusplus
}
#endif
