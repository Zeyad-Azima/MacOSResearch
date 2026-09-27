/* bad_shellcode.c — the naive attempt: looks like normal C, breaks as shellcode */
#include <unistd.h>

int main(void) {
    char *argv[] = {"/bin/sh", "-c", "echo \"W00tW00t\" > /tmp/Pwned.txt", NULL};
    char *envp[] = {NULL};

    execve(argv[0], argv, envp);
    return 0;
}
