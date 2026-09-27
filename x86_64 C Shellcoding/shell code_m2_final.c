/* shellcode_m2.c — Method 2: libc through function-pointer placeholders */
typedef unsigned long u64;

int main(void)
{
    /* execv's real signature: int execv(const char *path, char *const argv[]); */
    typedef int *(*execv_t)(const char *, char *const *);
    execv_t my_execv = (execv_t)0x7ff80c62a967;   /* placeholder — patched with the real one below */

    volatile u64 s_sh = 0x0068732f6e69622fUL;   /* "/bin/sh\0" */
    volatile u64 s_c  = 0x000000000000632dUL;   /* "-c\0"      */

    /* "echo \"W00tW00t\" > /tmp/Pwned.txt\0" — same chunks as Method 1 */
    volatile char cmd[33];
    *(volatile u64 *)&cmd[0]  = 0x305722206f686365UL;
    *(volatile u64 *)&cmd[8]  = 0x2022743030577430UL;
    *(volatile u64 *)&cmd[16] = 0x502f706d742f203eUL;
    *(volatile u64 *)&cmd[24] = 0x7478742e64656e77UL;
    cmd[32] = 0;

    char *argv[4];
    argv[0] = (char *)&s_sh;   /* argv[0] must be the same path */
    argv[1] = (char *)&s_c;
    argv[2] = cmd;
    argv[3] = 0;               /* NULL-terminated */

    my_execv((char *)&s_sh, argv);
    return 0;
}
