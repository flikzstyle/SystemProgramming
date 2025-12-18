section '.text' executable

public print_string
public print_newline
public print_number
public input_keyboard
public exit

; print_string: Вывод строки
; RSI - адрес строки
print_string:
    push rax
    push rdi
    push rdx
    push rcx
    push rsi

    xor rdx, rdx
    mov rcx, rsi
.len_loop:
    cmp byte [rcx], 0
    je .do_print
    inc rcx
    inc rdx
    jmp .len_loop

.do_print:
    mov rax, 1
    mov rdi, 1
    syscall

    pop rsi
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; print_newline: Перевод строки
print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline_sym
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; print_number: Вывод числа из RAX
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp

    mov rbp, rsp
    sub rsp, 32         ; Буфер
    
    mov rbx, 10
    mov rcx, 0
    lea rsi, [rbp - 1]  ; Начало буфера (растем вниз)

    test rax, rax
    jnz .convert_loop
    
    mov byte [rsi], '0'
    mov rdx, 1
    jmp .write

.convert_loop:
    xor rdx, rdx
    div rbx             ; RAX / 10
    add dl, '0'
    mov [rsi], dl
    dec rsi
    inc rcx
    test rax, rax
    jnz .convert_loop
    
    inc rsi             ; Корректируем указатель на начало строки
    mov rdx, rcx        ; Длина

.write:
    mov rax, 1
    mov rdi, 1
    syscall

    add rsp, 32
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; input_keyboard: Ввод
; RSI - буфер
input_keyboard:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall

    cmp rax, 1
    jl .done
    
    mov rcx, rax
    dec rcx
    cmp byte [rsi + rcx], 10
    jne .done
    mov byte [rsi + rcx], 0

.done:
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

section '.data' writable
    newline_sym db 10