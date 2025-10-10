format ELF64
public _start

include '../help.asm'
include '../func.asm'

section '.data' writable
    msg_enter db 'Введите число: ', 0
    msg_true db 'Цифры в неубывающем порядке', 10, 0
    msg_false db 'Цифры убывающем порядке', 10, 0

section '.bss' writable
    buffer rb 256

section '.text' executable
_start:
    mov rsi, msg_enter
    call print_str

    mov rsi, buffer
    call input_keyboard
    call atoi

    mov rbx, 10     ; проверяю порядок цифр , тут справа налево
    mov rcx, 10     ; предыдущая цифра (начинаем с максимальной)

.check_loop:
    xor rdx, rdx
    div rbx         ; rax = число/10, rdx = последняя цифра

    cmp rdx, rcx
    jg .false       ; если текущая цифра > предыдущей - false

    mov rcx, rdx    ; сохраняю как предыдущую
    test rax, rax
    jnz .check_loop

    mov rsi, msg_true
    jmp .print_result

.false:
    mov rsi, msg_false

.print_result:
    call print_str
    call exit
