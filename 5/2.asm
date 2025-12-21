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

; Loop:
; 1. Find the range with a start below or equel to the current 
; 2. Take the maximum between the current value and the range start
; 3. Check if the current value is lower than the range end, if not, mark the range and skip
; 4. Determine the distance between the current value and the end of the range and add it to the result
; 5. Mark the range to be skipped in the next loop
; 6. Set the range end as the current value

main_loop:
        mov     r10, 0x0                ; Use r10 to store the current value
        mov     r9, 0x7FFFFFFF_FFFFFFFF ; Use r9 to store the minimum 
        jmp     find_smallest_start

.done:
        jmp     done

.next:
        cmp     r9, r10
        jle     .loop
        mov     r10, r9

.loop:
        mov     r9, 0x7FFFFFFF_FFFFFFFF ; Use r9 to store the minimum 
        cmp     r10, r9
        je      .done

find_smallest_start:
        xor     rdx, rdx                ; Use rdx as the iterator
.loop:
        ; cmp     r9, r10                 ; If these values are the same, 0x7FFFFFFF_FFFFFFFF, then we're done
        ; je      main_loop.done

        cmp     byte [input_contents + rdx], "*"
        je      .skip_range

        cmp     byte [input_contents + rdx], 0x0A
        je      .done
        jmp     find_range_start

.skip_range:
        inc     rdx
        cmp     byte [input_contents + rdx], 0x0A
        jne     .skip_range
        inc     rdx
        jmp     .loop

.done:
        inc     rdx
        jmp     main_loop.next

find_range_start:
        mov     rax, rdx
.loop:
        cmp     byte [input_contents + rdx], "-"
        je      .done

        inc     rdx
        jmp     find_range_start.loop

.done:
        mov     rcx, rax                ; Keep track of the start of the line
        call    parse_number
        inc     rdx

        cmp     rax, r9                 ; Check if the range start is smaller than the min
        jg      find_smallest_start.skip_range ; If it is larger, just go to the next range

        mov     r9, rax                 ; Update the min
        
        cmp     rax, r10                ; Check if the range start is equal to the current value
        jg      find_smallest_start.skip_range ; If not, skip the range
        
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

        cmp     rax, r10                ; Check if the range end is smaller than the current value
        jge     .skip
        mov     byte [input_contents + rcx], "*" 
        jmp     main_loop.next

.skip:
        push    rax
        sub     rax, r10                ; Get the distance between the range end and the current value
        add     qword [result], rax     ; Add the distance to the result
        inc     qword [result]

        mov     byte [input_contents + rcx], "*" ; Mark the range as finished

        pop     rax
        inc     rax
        mov     r10, rax                ; Save the range end as current value
        jmp     main_loop.next 
