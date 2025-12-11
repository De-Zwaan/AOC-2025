default abs

        section .data

input_contents:
        incbin  "input.txt"
input_end:

        section .bss

result: resb    8                       ; Place where we will put the result
number: resb    16                      ; Number buffer
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
; 1. Parse the range
; 2. Find the invalid IDs
; 3. Add the invalid IDs to the accumulator
main_loop:
        cmp     rsi, input_end          ; Check if we are reading past the file end
        jge     done

parse_range_start:                      ; Parse the number after the first letter
        xor     r9, r9                  ; Initialize the accumulator to 0

.parse_range_start_loop:
        movzx   r10, byte [rsi]         ; Get the first byte of the number
        inc     rsi

        cmp     r10, '-'                ; Check if it is a newline
        je      parse_range_end
        
        sub     r10, '0'                ; Get the numerical value of the ascii byte
        imul    r9, r9, 10              ; Multiply the accumulator by 10 
        add     r9, r10                 ; Add the current value to the accumulator
        jmp     .parse_range_start_loop ; Continue until reaching the newline

parse_range_end:
        xor     r10, r10

.parse_range_end_loop:
        movzx   r11, byte [rsi]         ; Get the first byte of the number
        inc     rsi

        cmp     r11, ','                ; Check if it is a newline
        je      find_invalid
        cmp     rsi, input_end          ; Check if we reached the end
        jge     find_invalid

        sub     r11, '0'                ; Get the numerical value of the ascii byte
        imul    r10, r10, 10            ; Multiply the accumulator by 10 
        add     r10, r11                ; Add the current value to the accumulator
        jmp     .parse_range_end_loop   ; Continue until reaching the newline

debug:                                  ; Print the results
        mov     rax, r9
        call    print_result
        mov     rax, r10
        call    print_result
        call    print_newline
        ret

; Find the invalid ids in the range specified by r9-r10
find_invalid:
        call    debug
        mov     r11, r9

; Loop over every integer in the range r9-r10
.integer_loop:
        cmp     r11, r10
        jg      .integer_loop_done

; For every integer, translate it back to BCD or ascii representation and determine the length
.ascii_integer:
        mov     rax, r11
        mov     rbx, 10
        lea     rdi, [number]
        mov     rcx, 0                  ; digit count

.convert_loop:
        xor     rdx, rdx
        idiv    rbx                     ; divide RAX by 10 -> quotient in RAX, remainder in RDX
        add     dl, '0'                 ; convert remainder to ASCII
        mov     [rdi], dl
        inc     rdi
        inc     rcx
        test    rax, rax
        jnz     .convert_loop

; The length of the sequence must be len/2
; First check if the length is divisible by 2 (rcx % 2 == 0)
        push    rcx                     ; Make sure to save rcx (on the stack)
        mov     rax, rcx
        mov     rcx, 2
        cqo
        idiv    rcx                     ; rax / rcx, rdx = remainder, rax = quotient
        pop     rcx                     ; restore rcx

        cmp     rdx, 0                  ; Check if remainder is 0
        je      .check_match

        inc     r11
        jmp     .integer_loop

; Make sure every nth byte is the same in the integer, if it is not, increment i
; Iterate over 1..i and check for every jth byte if they are the same
; len = rcx, i = r12, 
.check_match:
        xor     r12, r12

.check_loop:
        cmp     r12, rax
        jge     .matched

        mov     r13, rax
        add     r13, r12

        push    rdx
        push    rcx

        mov     dl, [number + r12]
        mov     cl, [number + r13]

        cmp     dl, cl
        pop     rcx
        pop     rdx

        jne     .check_loop_done

        inc     r12
        jmp     .check_loop

.matched:
        add     qword [result], r11

.check_loop_done:

        inc     r11
        jmp     .integer_loop 

.integer_loop_done:
        jmp     main_loop
