format ELF64
public _start

include '../../help.asm'
include '../../func.asm'

section '.data' writable
    msg_enter db 'Введите число: ', 0
    msg_result db 'Результат: ', 0

section '.bss' writable
    buffer rb 256
    result_buffer rb 256

section '.text' executable
_start:
    mov rsi, msg_enter
    call print_str

    mov rsi, buffer
    call input_keyboard

    call atoi ; строку в число

    mov rdi, result_buffer
    mov rbx, 10
    xor rcx, rcx

.extract_digits:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .extract_digits

.build_string:
    pop rax
    add al, '0'
    mov [rdi], al
    inc rdi
    mov byte [rdi], '0'
    inc rdi
    loop .build_string

    mov rsi, msg_result
    call print_str

    mov rsi, result_buffer
    call print_str
    call new_line

    call exit
