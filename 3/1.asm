default abs

        section .data

input_contents:
        incbin  "input.txt"
input_end:

        section .bss

result: resb    8                       ; Place where we will put the result
buffer: resb    16                      ; Print buffer

        global  _start                  ; Entry point for the program
        section .text

print_result:
        push    rbx
        push    rdi
        push    rcx
        push    rdx
        push    rsi

        ; RAX = number to print
        mov     rbx, 10
        lea     rdi, [buffer+15]
        mov     rcx, 0                  ; digit count

        test    rax, rax
        jnz     .convert_loop

        mov     byte [rdi], '0'
        inc     rcx
        jmp     .print_number

.convert_loop:
        xor     rdx, rdx
        idiv    rbx                     ; divide RAX by 10 -> quotient in RAX, remainder in RDX
        add     dl, '0'                 ; convert remainder to ASCII
        dec     rdi
        mov     [rdi], dl
        inc     rcx
        test    rax, rax
        jnz     .convert_loop

.print_number:                          ; System call to write text to stdout
        mov     r8, rdi

        mov     rax, 1                  ; System call number for sys_write
        mov     rdi, 1                  ; File descriptor 1 (stdout)
        mov     rsi, r8                 ; Message to display
        mov     rdx, rcx                ; Length of message
        syscall                         ; Call the kernel
        
        pop     rsi
        pop     rdx
        pop     rcx
        pop     rdi
        pop     rbx

        ret

print_newline:
        push    rax
        push    rdi
        push    rsi
        push    rdx

        mov     byte [buffer], 0x0A

        mov     rax, 1                  ; System call number for sys_write
        mov     rdi, 1                  ; File descriptor 1 (stdout)
        mov     rsi, buffer             ; Message to display
        mov     rdx, 1                  ; Length of message
        syscall                         ; Call the kernel
        
        pop     rdx
        pop     rsi
        pop     rdi
        pop     rax

        ret

done:
        mov     rax, qword [result]     ; Read the result from [result]
        call    print_result
        call    print_newline

        ; Exit system call
        mov     rax, 60                 ; System call number for sys_exit
        xor     rdi, rdi                ; Exit code 0
        syscall                         ; Call the kernel to exit

_start:
        mov     [result], 0             ; Initialize the result to 0
        mov     rsi, input_contents     ; rsi holds address to input file

; Every loop we:
; 1. Find the largest digit that is not the last digit
; 2. Find the largest digit to the right of the first digit
; 3. Multiply the first digit by 10 and add to the second digit
; 4. Add this to the result
main_loop:
        cmp     rsi, input_end          ; Check if we are reading past the file end
        jge     done

        xor     r8, r8                  ; Running max
        xor     r9, r9                  ; Pos. of max

        mov     r10, rsi                ; Line start

find_first:

.loop:
        cmp     r10, input_end - 1      ; Don't read past end of file
        jge     find_second

        mov     r15b, byte [r10 + 1]    ; Look 2 places ahead to find newline
        cmp     r15, 0x0A               
        je      find_second

        mov     r15b, byte [r10]
        cmp     r15b, r8b               ; See if current digit is bigger than max
        jg      .found_bigger

.back:
        inc     r10
        jmp     .loop

.found_bigger:
        mov     r8, r15
        mov     r9, r10
        jmp     .back

find_second:
        mov     r10, r9                 ; Start searching at the right of the first digit
        inc     r10
        xor     r9, r9                  ; Running max

.loop:
        cmp     r10, input_end          ; Don't read past end of file
        jge     combine

        mov     r15b, byte [r10]        ; Search until end of line
        cmp     r15, 0x0A               
        je      combine

        mov     r15b, byte [r10]
        cmp     r15b, r9b               ; See if current digit is bigger than max
        jg      .found_bigger

.back:
        inc     r10
        jmp     .loop

.found_bigger:
        mov     r9, r15
        jmp     .back

combine:
        sub     r9, '0'
        sub     r8, '0'

        imul    r8, r8, 10
        add     r9, r8

        add     qword [result], r9

        ; Print the resulting number
        mov     rax, r9
        call    print_result
        call    print_newline
        
next_line:
        mov     rsi, r10
        inc     rsi
        jmp     main_loop
                                        
