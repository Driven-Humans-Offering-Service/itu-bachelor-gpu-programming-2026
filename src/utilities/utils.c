#include <string.h>
int contains_argument(int argc, char** argv, const char* arg){
    for (int i = 1; i < argc; i++) {
        if(strcmp(argv[i], arg) == 0) return i;
    }
    return 0;
}
