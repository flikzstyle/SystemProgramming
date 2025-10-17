; Функция ввода с клавиатуры
; rsi = буфер для ввода
input_keyboard:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall

    ; Заменяем перевод строки на нуль-терминатор
    xor rcx, rcx
    .find_end:
        mov al, [rsi + rcx]
        cmp al, 10
        je .replace
        cmp al, 0
        je .done
        inc rcx
        jmp .find_end

    .replace:
        mov byte [rsi + rcx], 0

    .done:
        pop rcx
        pop rdx
        pop rdi
        pop rax
        ret

; Функция преобразования строки в число
; rsi = строка
; возвращает rax = число
atoi:
    push rcx
    push rbx

    xor rax, rax
    xor rcx, rcx
    .loop:
        xor rbx, rbx
        mov bl, byte [rsi + rcx]
        cmp bl, 0
        je .finished
        cmp bl, 48
        jl .finished
        cmp bl, 57
        jg .finished

        sub bl, 48
        add rax, rbx
        mov rbx, 10
        mul rbx
        inc rcx
        jmp .loop

    .finished:
        cmp rcx, 0
        je .restore
        mov rbx, 10
        div rbx

    .restore:
        pop rbx
        pop rcx
        ret
