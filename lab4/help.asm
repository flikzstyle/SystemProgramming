; Функция выхода
exit:
    mov rax, 60
    xor rdi, rdi
    syscall
    ret

; Функция вывода строки
; rsi = указатель на строку
print_str:
    push rax
    push rdi
    push rdx
    push rcx

    ; Находим длину строки
    mov rdi, rsi
    xor rcx, rcx
    .find_length:
        cmp byte [rdi + rcx], 0
        je .print
        inc rcx
        jmp .find_length

    .print:
        mov rax, 1
        mov rdi, 1
        mov rdx, rcx
        syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; Функция вывода числа
; rax = число
print_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp

    mov rbp, rsp
    xor rbx, rbx

    test rax, rax
    jns .positive_number

    push rax
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    mov rsi, rsp
    mov byte [rsi], '-'
    syscall
    pop rax
    neg rax

    .positive_number:
        mov rcx, 10

    .digit_loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .digit_loop

    .print_loop:
        pop rax
        add al, '0'

        push rax
        mov rsi, rsp

        mov rax, 1
        mov rdi, 1
        mov rdx, 1
        syscall

        pop rax

        dec rbx
        jnz .print_loop

    .cleanup:
        mov rsp, rbp
        pop rbp
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

; Функция вывода новой строки
new_line:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

section '.data' writable
    newline db 10
