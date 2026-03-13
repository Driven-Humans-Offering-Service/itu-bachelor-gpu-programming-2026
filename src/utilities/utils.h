#ifdef __cplusplus
extern "C" {
#endif

#include "./matrix.h"

int contains_argument(int argc, char **argv, const char *arg);
unsigned long get_time_nanoseconds();
int shared_main(int argc, char **argv, int (*fptr)(Matrices*));

#ifdef __cplusplus
}
#endif
