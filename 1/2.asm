default abs

        section .data

input_contents:
        incbin  "input.txt"
input_end:

        section .bss

result: resb    8                       ; Place where we will put the result
buffer: resb    16 

        global  _start                  ; Entry point for the program
        section .text

_start:
        mov     rax, 50                 ; Initialize the wheel to 50
        mov     [result], 0             ; Initialize the result to 0
        mov     rsi, input_contents     ; rsi holds address to input file

loop:                                   ; Read all of the input file
        cmp     rsi, input_end          ; Check if we are reading past the file end
        jge     done

parse_letter:                           ; Parse the letter
        movzx   rbx, byte [rsi]         ; Read the first letter of the line
        cmp     bl, 'R'                 ; Test if the first symbol is a 'R'
        setz    r11b                    ; If 'R' set r11 for use later
        movzx   r11, r11b
        inc     rsi

parse_number:                           ; Parse the number after the first letter
        xor     r9, r9                  ; Initialize the accumulator to 0

.parse_number_loop:
        movzx   r10, byte [rsi]         ; Get the first byte of the number
        inc     rsi

        cmp     r10, 0x0A               ; Check if it is a newline
        je      .apply

        sub     r10, '0'                ; Get the numerical value of the ascii byte
        imul    r9, r9, 10              ; Multiply the accumulator by 10 
        add     r9, r10                 ; Add the current value to the accumulator
        jmp     .parse_number_loop      ; Continue until reaching the newline

.apply:
        test    r11, r11
        jne     .r
        neg     r9                      ; Letter is 'L': Negate the parsed number
.r:

; R9 contains the delta, RAX the old wheel position
        mov     r10, rax                ; r10 = old
        add     rax, r9                 ; rax = new = old + delta
        
        mov     rcx, 100
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rcx                     ; rax = new / 100, rdx = new % 100

        cmp     rdx, 0
        jge     .normalized
        add     rdx, 100                ; Normalize the truncated quotient to 0-99
        dec     rax                     ; This is needed for some reason

.normalized:
        mov     r11, rax
        cmp     r11, 0
        jge     .positive_wrap
        neg     r11

.positive_wrap:
        add     [result], r11           ; Accumulate number of 0-crossings

        cmp     r9, 0
        jge     .skip_zero_case
        cmp     rdx, 0                  ; If the wheel ends on 0
        jne     .check_start
        inc     [result]

.check_start:
        cmp     r10, 0
        jne     .skip_zero_case
        dec     [result]

.skip_zero_case:
        mov     rax, rdx
        jmp     loop

; Print the result and exit
done:
        mov     rax, qword [result]     ; Read the result from [result]
        call    print_result            ; Print the result

        ; Exit system call
        mov     rax, 60                 ; System call number for sys_exit
        xor     rdi, rdi                ; Exit code 0
        syscall                         ; Call the kernel to exit

; Print the result stored in RAX
print_result:
        mov     rbx, 10                 ; Base
        lea     rdi, [buffer+15]        ; Reversed Ascii string
        mov     rcx, 0                  ; Digit count

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
        ret
