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

; 1. Find the width of the input
; 2. Loop over all positions in the grid
; 3. If it is a @, count the number of @'s around it
; 4. If the amount is fewer than 4, increment the result

        mov     r8, 0
find_width: 
        cmp     byte [input_contents + r8], 0x0A              ; Check if it is a newline
        je      .done
        
        inc     r8
        jmp     find_width
.done:
        inc     r8

        mov     r9, 0
        mov     r10, rsi
find_height: 
        cmp     r10, input_end
        jge     .done

        inc     r9
        add     r10, r8
        jmp     find_height
.done:

        ; Here: 
        ;       r8 = width + 1
        ;       r9 = height + 1
        ;       r10 = x
        ;       r11 = y
        ;       r12 = index_offset (from input_contents)

        mov     r10, 0
        mov     r11, 0

vertical_loop:
        cmp     r11, r9
        jge     vertical_loop_done

        mov     r10, 0

horizontal_loop:
        cmp     r10, r8
        jge     horizontal_loop_done

        xor     rdx, rdx
        mov     rax, r11
        mul     r8
        add     rax, r10

        cmp     byte [input_contents + rax], '@'
        jne     middle_left.skip

        xor     r13, r13

top_left:
        mov     r12, rax                        ; Calculate index top-left of rax
        sub     r12, r8
        dec     r12

        ; Start top-left
        cmp     r11, 0                          ; Check if against top edge
        je      top_center

        cmp     r10, 0                          ; Check if against left edge
        je      top_center
        
        cmp     byte [input_contents + r12], '@'
        jne     top_center      
        inc     r13

top_center:
        inc     r12

        cmp     r11, 0                          ; Check if against top edge
        je      top_right

        cmp     byte [input_contents + r12], '@'
        jne     top_right
        inc     r13

top_right:
        inc     r12

        cmp     r11, 0                          ; Check if against top edge
        je      middle_right

        cmp     r10, r8                         ; Check if against right edge
        je      middle_right

        cmp     byte [input_contents + r12], '@'
        jne     middle_right
        inc     r13

middle_right:
        add     r12, r8

        cmp     r10, r8                         ; Check if against right edge
        je      bottom_right

        cmp     byte [input_contents + r12], '@'
        jne     bottom_right
        inc     r13

bottom_right:
        add     r12, r8

        cmp     r11, r9                         ; Check if against bottom edge
        je      bottom_center

        cmp     r10, r8                         ; Check if against right edge
        je      bottom_center

        cmp     byte [input_contents + r12], '@'
        jne     bottom_center
        inc     r13

bottom_center:
        dec     r12

        cmp     r11, r9                         ; Check if against bottom edge
        je      bottom_left

        cmp     byte [input_contents + r12], '@'
        jne     bottom_left
        inc     r13

bottom_left:
        dec     r12

        cmp     r11, r9                         ; Check if against bottom edge
        je      middle_left

        cmp     r10, 0                          ; Check if against left edge
        je      middle_left

        cmp     byte [input_contents + r12], '@'
        jne     middle_left
        inc     r13

middle_left:
        sub     r12, r8

        cmp     r10, 0                          ; Check if against left edge
        je      .next

        cmp     byte [input_contents + r12], '@'
        jne     .next
        inc     r13
        
.next:
        cmp     r13, 4
        jge     .skip

        inc     qword [result]

.skip:
        inc     r10
        jmp     horizontal_loop

horizontal_loop_done:
        inc     r11
        jmp     vertical_loop

vertical_loop_done:
        jmp     done
