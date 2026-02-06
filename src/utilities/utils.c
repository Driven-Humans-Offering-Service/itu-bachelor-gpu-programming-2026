#include <string.h>
#include <time.h>
int contains_argument(int argc, char** argv, const char* arg){
    for (int i = 1; i < argc; i++) {
        if(strcmp(argv[i], arg) == 0) return i;
    }
    return 0;
}
struct timespec ts;
unsigned long get_time_nanoseconds() {
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_nsec;
}
