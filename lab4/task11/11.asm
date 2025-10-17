format ELF64
public _start

include '../../help.asm'
include '../../func.asm'

section '.data' writable
    msg_judges db 'Введите количество судей: ', 0
    msg_votes db 'Введите голоса (1-Да, 0-Нет): ', 0
    msg_yes db 'Решение: ДА', 10, 0
    msg_no db 'Решение: НЕТ', 10, 0
    msg_draw db 'Решение: НИЧЬЯ', 10, 0

section '.bss' writable
    buffer rb 256
    votes_buffer rb 256
    judges_count dq 0

section '.text' executable
_start:
    mov rsi, msg_judges
    call print_str

    mov rsi, buffer
    call input_keyboard
    call atoi
    mov [judges_count], rax

    mov rsi, msg_votes
    call print_str

    mov rsi, votes_buffer
    call input_keyboard

    mov rsi, votes_buffer
    xor rax, rax    ; счетчик За
    xor rbx, rbx    ; счетчик Против
    mov rcx, [judges_count]

.count_votes:
    mov dl, [rsi]
    cmp dl, '1'
    je .vote_yes
    cmp dl, '0'
    je .vote_no
    jmp .next_vote

.vote_yes:
    inc rax
    jmp .next_vote

.vote_no:
    inc rbx

.next_vote:
    inc rsi
    loop .count_votes

    cmp rax, rbx
    jg .decision_yes
    jl .decision_no

    mov rsi, msg_draw
    jmp .print_result

.decision_yes:
    mov rsi, msg_yes
    jmp .print_result

.decision_no:
    mov rsi, msg_no

.print_result:
    call print_str
    call exit
