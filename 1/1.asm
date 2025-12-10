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
        add     rax, r9                 ; Add the (poss. negated) accumulated value to the wheel

reduce:                                 ; Now we need to reduce the number to 0-99
        xor     rdx, rdx                ; Prepare the registers for division
        cqo
        mov     rcx, 100
        idiv     rcx                     ; rax / rcx -> quotient in rax, remainder in rdx

        cmp     rdx, 0                  ; And test if the number is 0
        jge     .skip_adjust
        add     rdx, 100
.skip_adjust:
        mov     rax, rdx

        cmp     rax, 0
        jne     .skip_increment
        inc     qword [result]

.skip_increment:
        jmp     loop

done:
        mov     rax, qword [result]     ; Read the result from [result]
        call    print_result

        ; Exit system call
        mov     rax, 60                 ; System call number for sys_exit
        xor     rdi, rdi                ; Exit code 0
        syscall                         ; Call the kernel to exit

print_result:
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
        ret
