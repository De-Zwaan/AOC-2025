default abs

        section .data

input_contents:
        incbin  "input.txt"
        ; incbin  "input.txt"
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
        cmp     rsi, input_end - 12     ; Check if we are reading past the file end
        jge     done

        mov     r10, rsi
        inc     r10

        mov     r9, rsi
        dec     r9

        mov     r11, 11

        xor     r13, r13 

find_digit:
        inc     r9                      ; Pos. of max
        xor     r8, r8
        mov     r8b, byte [r9]          ; Running max
        mov     r10, r9
        inc     r10

        cmp     r11, 0
        jl      combine

.loop:
        ; Calculate the number of digits to keep away from the end
        mov     r12, r11
        add     r12, r10

        cmp     r12, input_end          ; Don't read past end of file
        jg      .found_biggest

        mov     r15b, byte [r12]        ; Look n + 1 places ahead to find newline
        cmp     r15, 0x0A               
        je      .found_biggest

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

.found_biggest:
        sub     r8, '0'
        imul    r13, r13, 10
        add     r13, r8
        dec     r11
        jmp     find_digit

combine:
        add     qword [result], r13

        ; Print the resulting number
        mov     rax, r13
        call    print_result
        call    print_newline

        mov     r10, rsi
        inc     r10
find_newline:
        cmp     r10, input_end
        jge     .found_newline

        mov     r8b, byte [r10]
        cmp     r8b, 0x0a
        je      .found_newline

        inc     r10
        jmp     find_newline

.found_newline:
        mov     rsi, r10
        jmp     main_loop
