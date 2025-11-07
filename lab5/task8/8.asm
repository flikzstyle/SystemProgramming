format elf64
public _start

include '../../funcnew.asm'

section '.data' writable
    msg_usage db "Как запускать: ./program <file1> <file2> <output>", 10, 0
    msg_error db "ошибка: не удается открыть файл", 10, 0
    msg_success db "отлично, общие символы были записаны", 10, 0

section '.bss' writable
    chars1 rb 256    ; символы первого файла
    chars2 rb 256    ; символы второго файла
    result rb 256    ; результат - общие символы
    buffer rb 1024   ; буфер для чтения файлов
    output_buffer rb 256 ; буфер для вывода
    space db "", 0

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

write_result:
    push r12
    push r13
    push r14
    push r15

    mov r14, rdi    ; сохраняем имя выходного файла

    ; СОЗДАЕМ ФАЙЛ
    mov rax, 2
    mov rdi, r14
    mov rsi, 0x241  ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error
    mov r15, rax    ; сохраняем fd

    lea r12, [result] ; битовая маска

    mov r13, 32      ; текущий символ

.write_loop:
    cmp r13, 127    
    jge .close

    ; ПРОВЕРКА СИМВОЛА
    cmp byte [r12 + r13], 0
    je .next_char

    ; ЗАПИСЫВАЕТ СИМВОЛ НАПРЯМУЮ
    push r13        ; сохраняем символ в стек
    mov rax, 1      ; sys_write
    mov rdi, r15    ; fd
    mov rsi, rsp    ; указатель на символ в стеке
    mov rdx, 1      ; 1 байт
    syscall
    pop r13         ; восстанавливаем стек

    ; ЗАПИСЫВАЕМ ПРОБЕЛ
    mov rax, 1
    mov rdi, r15
    mov rsi, space
    mov rdx, 1
    syscall

.next_char:
    inc r13
    jmp .write_loop

.close:
    mov rax, 3
    mov rdi, r15
    syscall
    xor rax, rax
    jmp .done

.error:
    mov rax, -1

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret
