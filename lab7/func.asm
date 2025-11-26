; func.asm
print_string:
    ; rsi - адрес строки (заканчивается нулем)
    push rax
    push rdi
    push rdx
    push rcx
    
    xor rdx, rdx
    mov rcx, rsi
.len_loop:
    cmp byte [rcx], 0
    je .print
    inc rcx
    inc rdx
    jmp .len_loop
.print:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 1
    mov rdi, 1
    mov rsi, newline_char
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_number:
    ; rax - положительное число для вывода
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    
    mov rcx, 0
    mov rbx, 10
    sub rsp, 32     ; буфер на стеке
    mov rdi, rsp
    
.loop:
    xor rdx, rdx
    div rbx
    add rdx, '0'
    mov [rdi+rcx], dl
    inc rcx
    test rax, rax
    jnz .loop
    
.print_loop:
    dec rcx
    lea rsi, [rdi+rcx]
    mov rax, 1
    push rcx
    mov rdi, 1      ; stdout
    mov rdx, 1
    syscall
    pop rcx
    cmp rcx, 0
    jg .print_loop
    
    add rsp, 32
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

input_keyboard:
    ; rsi - буфер
    ; Читаем до 255 байт
    push rax
    push rdi
    push rdx
    
    mov rax, 0      ; sys_read
    mov rdi, 0      ; stdin
    mov rdx, 255
    syscall
    
    ; Заменяем \n на 0
    cmp rax, 0
    jle .done
    mov rcx, rax
    dec rcx
    cmp byte [rsi+rcx], 10
    jne .done
    mov byte [rsi+rcx], 0
    
.done:
    pop rdx
    pop rdi
    pop rax
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

section '.data'
    newline_char db 10