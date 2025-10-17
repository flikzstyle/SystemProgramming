format elf64
public _start

include '../../funcnew.asm'

section '.data' writable
    msg_usage db "Usage: ./program <file1> <file2> <output>", 10, 0
    msg_error db "Error: Cannot open file", 10, 0
    msg_success db "Success: Common symbols written to output file", 10, 0

section '.bss' writable
    chars1 rb 256    ; символы первого файла
    chars2 rb 256    ; символы второго файла
    result rb 256    ; результат - общие символы
    buffer rb 1024   ; буфер для чтения файлов
    output_buffer rb 256 ; буфер для вывода

section '.text' executable

_start:
    pop rcx         ; количество аргументов
    cmp rcx, 4
    jne show_usage

    pop rsi         ; argv[0] - имя программы
    pop rdi         ; argv[1] - file1
    mov r12, rdi
    pop rdi         ; argv[2] - file2  
    mov r13, rdi
    pop rdi         ; argv[3] - output
    mov r14, rdi

   
    mov rdi, r12 ; обработка первого файла
    lea rsi, [chars1]
    call process_file
    test rax, rax
    js error_exit

    
    mov rdi, r13 ;  второй файл
    lea rsi, [chars2]  
    call process_file
    test rax, rax
    js error_exit

    call find_common_chars

    
    mov rdi, r14
    call write_result ; запись результата
    test rax, rax
    js error_exit

    mov rsi, msg_success
    call print_str
    jmp exit

show_usage:
    mov rsi, msg_usage
    call print_str
    jmp exit

error_exit:
    mov rsi, msg_error
    call print_str
    jmp exit


; rdi - имя файла
; rsi - буфер для множества символов (256 байт)
process_file: ; Обрабатывает файл и заполняет множество символов
    push r12
    push r13
    push r14
    
    mov r14, rdi    ;  имя файла
    mov r12, rsi    ;  указатель на множество
    
   
    mov rdi, r12
    mov rcx, 32
    xor rax, rax ; пустое множество
    rep stosq
    
    mov rax, 2
    mov rdi, r14
    xor rsi, rsi    ; O_RDONLY
    syscall
    cmp rax, 0
    jl .error
    mov r13, rax    ; fd
    
.read_loop:
    mov rax, 0
    mov rdi, r13
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .close
    
    mov rcx, rax    ; количество прочитанных байт
    mov rsi, buffer
    mov rdi, r12    ; множество символов
    
.process_buffer:
    mov al, [rsi]
    mov byte [rdi + rax], 1
    inc rsi
    dec rcx
    jnz .process_buffer
    
    jmp .read_loop

.close:
    mov rax, 3
    mov rdi, r13
    syscall
    xor rax, rax    ; успех
    jmp .done

.error:
    mov rax, -1     ; ошибка

.done:
    pop r14
    pop r13
    pop r12
    ret

find_common_chars:; Находит общие символы
    push rcx
    push rsi
    push rdi
    
    mov rcx, 256
    mov rsi, chars1
    mov rdi, chars2
    lea r8, [result]
    
.loop:
    mov al, [rsi]
    and al, [rdi]
    mov [r8], al
    
    inc rsi
    inc rdi  
    inc r8
    dec rcx
    jnz .loop
    
    pop rdi
    pop rsi
    pop rcx
    ret

write_result:; Записывает результат в файл rdi - имя файла
    push r12
    push r13
    push r14
    
    mov r14, rdi    
    
    lea r12, [result] ;  строка из общих символов
    lea r13, [output_buffer] ; отдельный буфер для вывода
    
    mov rcx, 0      ; текущий символ (ASCII код)
    mov rdx, 0      ; позиция в буфере
    
.build_string:
    cmp rcx, 256
    jge .write_file
    
    cmp byte [r12 + rcx], 0 ; проверка если есть ли символ в обоих файлах
    je .next_char
    
    mov [r13 + rdx], cl  ; Символ есть - добавляем в строку как читаемый символ
    inc rdx
    
.next_char:
    inc rcx
    jmp .build_string
    
.write_file:
    test rdx, rdx ; Проверяем, есть ли общие символы
    jz .empty_result
    
    mov rax, 2
    mov rdi, r14
    mov rsi, 0x241  ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error
    mov r8, rax     ; fd
    
   
    mov rax, 1
    mov rdi, r8
    mov rsi, output_buffer ; Запись результата (только нужные байты)
    ; rdx уже содержит длину строки
    syscall
    
    mov rax, 3
    mov rdi, r8
    syscall
    
    xor rax, rax    ; успех
    jmp .done

.empty_result: ;создание пустого фалйа
    mov rax, 2
    mov rdi, r14
    mov rsi, 0x241
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error
    mov r8, rax
    
    mov rax, 3
    mov rdi, r8
    syscall
    
    xor rax, rax
    jmp .done

.error:
    mov rax, -1     ; ошибка

.done:
    pop r14
    pop r13
    pop r12
    ret