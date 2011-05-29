#include <stdio.h>
#include <dlfcn.h>

int main(int argc, char **argv) {
    void *datahandle = dlopen("./libmy-data.so", RTLD_LAZY);
    char* message = *(char **)dlsym(datahandle, "my_message");
    printf("%s", message);
    return(0);
}
