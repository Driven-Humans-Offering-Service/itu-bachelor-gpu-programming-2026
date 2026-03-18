#include <string.h>
#include <time.h>
#include "matrix.h"
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
int shared_main(int argc, char **argv, void (*fptr)(Matrices*)) {
    char* path1 = argv[argc - 2];
    char* path2 = argv[argc - 1];
    int displayRuntime = contains_argument(argc, argv, "--time");
    int print_to_file = contains_argument(argc, argv, "--outputresult");
    int load_time = contains_argument(argc, argv, "--loadtime");

    unsigned long before_load = get_time_nanoseconds();
    Matrices* ma = load_matrices(path1, path2);
    unsigned long after_load = get_time_nanoseconds();

    int total_size = ma->total_size;
    unsigned long before = get_time_nanoseconds();
    fptr(ma);
    unsigned long after = get_time_nanoseconds();
    unsigned long runtime = after - before;
    if(load_time) 
        printf("load time: %lu\n", after_load - before_load);

    if(displayRuntime) 
        printf("%lu\n", runtime);

    if(print_to_file){
        char* path = argv[print_to_file+1];
        output_matrix(ma, path);
    }
    free_matrices(ma);
    return 0;
}
