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

; Arguments:
; rax:  string start offset
; rdx:  string end offset 
; Assumes that is inside the file
; Assumes there is nothing but numbers inside the specified range
; Return:
; rax:  the int encoded by the ascii string
parse_number:
        push    rbx
        push    rcx
        xor     rbx, rbx
        xor     rcx, rcx
        
.loop:  
        cmp     rax, rdx
        jge     .done

        mul     rbx, rbx, 10
        movzx   rcx, byte [input_contents + rax]
        sub     rcx, '0'
        add     rbx, rcx

        inc     rax
        jmp     .loop

.done:
        mov     rax, rbx
        pop     rcx
        pop     rbx
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

; 0. Find the segment of the file with the ingredients and use this as the end for range iteration
; 1. Find the minimum start and maximum end of all ranges
; 2. Iterate over all numbers between these values
; 3. For each number check if it is inside a range by iterating over all ranges
; 4. If it falls within a range, increment result and early return

find_extremes:
        mov     r9, 0x7FFFFFFF_FFFFFFFF ; Use r9 to store the minimum 
        mov     r10, 0                  ; Use r10 to store the maximum

        xor     rdx, rdx                ; Use rdx as the iterator

.loop:
        cmp     byte [input_contents + rdx], 0x0A
        je      .done
        jmp     find_range_start

.done:
        inc     rdx
        jmp     main_loop

find_range_start:
        mov     rax, rdx
.loop:
        cmp     byte [input_contents + rdx], '-'
        je      .done

        inc     rdx
        jmp     find_range_start.loop

.done:
        call    parse_number
        inc     rdx

        cmp     rax, r9
        jge     find_range_end
        mov     r9, rax
        
find_range_end:
        mov     rax, rdx
.loop:
        cmp     byte [input_contents + rdx], 0x0A 
        je      .done

        inc     rdx
        jmp     find_range_end.loop   ; Continue until reaching the newline

.done:
        call    parse_number
        inc     rdx

        cmp     rax, r10
        jle     find_extremes.loop
        mov     r10, rax
        jmp     find_extremes.loop 


; Now we have the search space, loop over all numbers between (inclusive) r9 and r10
; For each number search for a range that includes it
main_loop:
        mov     rax, r9
        call    print_result
        mov     rax, '-'
        call    print
        mov     rax, r10
        call    print_result
        mov     rax, 0x0A
        call    print

        dec     r9
.loop:
        inc     r9
        cmp     r9, r10
        jle     range_loop

.done:
        jmp     done

range_loop:
        xor     rdx, rdx
        dec     rdx
.loop:
        inc     rdx
        cmp     byte [input_contents + rdx], 0x0A
        je      main_loop.loop

        mov     rax, rdx
        jmp     check_range_start

.done:
        jmp     main_loop.loop        

check_range_start:
.loop:
        cmp     byte [input_contents + rdx], '-'
        je      .done

        inc     rdx
        jmp     .loop

.done:
        call    parse_number
        inc     rdx

        cmp     rax, r9
        jle     check_range_end

skip_range_end:                         ; If r9 < range_start, skip range end
        cmp     byte [input_contents + rdx], 0x0A
        je      range_loop.loop
        inc     rdx
        jmp     skip_range_end
        
check_range_end:
        mov     rax, rdx
.loop:
        cmp     byte [input_contents + rdx], 0x0A 
        je      .done

        inc     rdx
        jmp     .loop

.done:
        call    parse_number

        cmp     rax, r9
        jl      range_loop.loop

        inc     rdx

        inc     qword [result]
        mov     rax, r9
        call    print_result
        mov     rax, 0x0A
        call    print

        jmp     main_loop.loop
