format ELF64
public _start

include '../../help.asm'
include '../../func.asm'

section '.data' writable
    msg_n db 'Введите n: ', 0
    msg_k db 'Введите k: ', 0
    msg_result db 'Сумма чисел с суммой цифр k: ', 0

section '.bss' writable
    buffer rb 256
    n dq 0
    k dq 0
    sum dq 0

section '.text' executable
sum_of_digits:
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    xor rcx, rcx    ; сумма цифр

.calculate:
    xor rdx, rdx
    div rbx         ; rdx = последняя цифра
    add rcx, rdx    ; к сумме добавляется цифра
    test rax, rax
    jnz .calculate

    mov rax, rcx   

    pop rdx
    pop rcx
    pop rbx
    ret

_start:
    mov rsi, msg_n
    call print_str

    mov rsi, buffer
    call input_keyboard
    call atoi
    mov [n], rax

    mov rsi, msg_k
    call print_str

    mov rsi, buffer
    call input_keyboard
    call atoi
    mov [k], rax

    mov rcx, 1      ;суммирование чисел от 1 до n с суммой k, начинаем с 1

.loop:
    cmp rcx, [n]
    jg .end_loop    ; если прошли все числа до n

    mov rax, rcx
    call sum_of_digits  ; сумма цифр текущего числа

    cmp rax, [k]
    jne .next_number    ; если сумма цифр не равна k, то скип

    add [sum], rcx

.next_number:
    inc rcx
    jmp .loop

.end_loop:
    mov rsi, msg_result
    call print_str

    mov rax, [sum]
    call print_int
    call new_line

    call exit
