section .data
    hello_msg db "Hello World!", 0xA   ; Define message with a newline at the end

section .text
    global _start                     ; Entry point for the program

_start:
    ; System call to write text to stdout
    mov eax, 4                        ; System call number for sys_write
    mov ebx, 1                        ; File descriptor 1 (stdout)
    mov ecx, hello_msg                ; Message to display
    mov edx, 13                       ; Length of message (including newline)
    int 0x80                          ; Call the kernel

    ; Exit system call
    mov eax, 1                        ; System call number for sys_exit
    xor ebx, ebx                      ; Exit code 0
    int 0x80                          ; Call the kernel to exit
