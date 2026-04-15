#include <string.h>
#include <time.h>
#include "matrix.h"
#ifdef __cplusplus
#endif

#ifdef CUDA_CODE
unsigned long kernel_time;
#endif


int contains_argument(int argc, char** argv, const char* arg){
    for (int i = 1; i < argc; i++) {
        if(strcmp(argv[i], arg) == 0) return i;
    }
    return 0;
}
struct timespec ts;
unsigned long get_time_nanoseconds() {
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000 + ts.tv_nsec;
}



int shared_main(int argc, char **argv, int (*fptr)(Matrices*)) {
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
    unsigned long before = get_time_nanoseconds();
    int res = fptr(ma);
    if(res != 0){
        fprintf(stderr, "Cant invert matrix");
        free_matrices(ma);
        return res;
    }
    unsigned long after = get_time_nanoseconds();
    unsigned long runtime = after - before;
    if(load_time) 
        printf("load time: %lu\n", after_load - before_load);

    if(displayRuntime) {
        printf("%lu\n", runtime);
        #ifdef CUDA_CODE
            printf("%lu\n", kernel_time);
        #endif
    }

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
