default abs

        section .data

input_contents:
        incbin  "input.txt"
input_end:
input_len equ input_end - input_contents

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
        push    r8
        mov     r8, rdi

        mov     rax, 1                  ; System call number for sys_write
        mov     rdi, 1                  ; File descriptor 1 (stdout)
        mov     rsi, r8                 ; Message to display
        mov     rdx, rcx                ; Length of message
        syscall                         ; Call the kernel
        
        pop     r8
        pop     rsi
        pop     rdx
        pop     rcx
        pop     rdi
        pop     rbx

        ret

print:
        push    rdi
        push    rsi
        push    rdx

        mov     qword [buffer], rax

        mov     rax, 1                  ; System call number for sys_write
        mov     rdi, 1                  ; File descriptor 1 (stdout)
        mov     rsi, buffer             ; Message to display
        mov     rdx, 8                  ; Length of message
        syscall                         ; Call the kernel
        
        pop     rdx
        pop     rsi
        pop     rdi

        ret

done:
        mov     rax, qword [result]     ; Read the result from [result]
        call    print_result
        mov     rax, 0x0A
        call    print

        ; Exit system call
        mov     rax, 60                 ; System call number for sys_exit
        xor     rdi, rdi                ; Exit code 0
        syscall                         ; Call the kernel to exit

_start:
        mov     [result], 0             ; Initialize the result to 0
        mov     rsi, input_contents     ; rsi holds address to input file

; 0. Find the segment of the file with the ingredients
; 1. Iterate over all ranges
; 2. For each range, iterate over all ingredients
; 3. For each ingredient, check if it is within the range
; 4. If it is within the range, increment result and delete the ingredient somehow

        xor     r8, r8
find_ingredient_start:
        cmp     word [input_contents + r8], 0x0A0A
        je      .found_ingredient_start

        inc     r8
        jmp     find_ingredient_start

.found_ingredient_start:
        add     r8, 2
        mov     r12, r8
        dec     r12

        xor     r8, r8
main_loop:
        cmp     r8, r12
        jge     done

parse_range_start:                      ; Parse the number after the first letter
        xor     r9, r9                  ; Initialize the accumulator to 0

.parse_range_start_loop:
        movzx   r10, byte [input_contents + r8] ; Get the first byte of the number

        cmp     r10, '-'                ; Check if it is a newline
        je      parse_range_end
        
        sub     r10, '0'                ; Get the numerical value of the ascii byte
        mul     r9, r9, 10              ; Multiply the accumulator by 10 
        add     r9, r10                 ; Add the current value to the accumulator

        inc     r8
        jmp     .parse_range_start_loop ; Continue until reaching the newline

parse_range_end:
        inc     r8
        xor     r10, r10

.parse_range_end_loop:
        movzx   r11, byte [input_contents + r8] ; Get the first byte of the number

        cmp     r11, 0x0A               ; Check if it is a newline
        je      .done

        sub     r11, '0'                ; Get the numerical value of the ascii byte
        mul     r10, r10, 10            ; Multiply the accumulator by 10 
        add     r10, r11                ; Add the current value to the accumulator

        inc     r8
        jmp     .parse_range_end_loop   ; Continue until reaching the newline

; input_contents + r12: start of list of ingredients
; input_contents + r8 : start of next range line
; r9 : range start
; r10: range end
.done:
        mov     r13, r12

check_ingredients:
        xor     rax, rax
        mov     r14, r13
.loop:
        cmp     r13, input_len - 1
        jge     .check_in_range

        movzx   r11, byte [input_contents + r13]

        cmp     r11, '*'                ; Check if this ingredient was already counted
        je      .skip_ingredient

        cmp     r11, 0x0A
        je      .check_in_range

.parse_ingredient:
        sub     r11, '0'                ; Get the numerical value of the ascii byte
        mul     rax, rax, 10            ; Multiply the accumulator by 10 
        add     rax, r11                ; Add the current value to the accumulator

        inc     r13
        jmp     .loop

.skip_ingredient:
        inc     r13

        cmp     r13, input_len - 1
        je      .done

        cmp     byte [input_contents + r13], 0x0A
        je      .done

        jmp     .skip_ingredient

.check_in_range:
        cmp     rax, r9
        jl      .done

        cmp     rax, r10
        jg      .done

.in_range:                              ; It is within the range
        inc     qword [result]
        mov     byte [input_contents + r14], '*'

; debug:                                  ; Print the results
        push    rax
        mov     rax, r9
        call    print_result
        mov     rax, '-'
        call    print
        mov     rax, r10
        call    print_result
        mov     rax, ': '
        call    print
        pop     rax
        call    print_result
        mov     rax, 0x0A
        call    print
        
.done:
        cmp     r13, input_len - 1
        jge     ingredient_loop_done

        inc     r13
        jmp     check_ingredients

ingredient_loop_done:
        inc     r8
        jmp     main_loop
