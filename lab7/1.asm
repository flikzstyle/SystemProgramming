format elf64
public _start

include 'func.asm'

section '.bss' writable
    buffer rb 256
    status rd 1
    args rq 2
    env_ptr rq 1
    term_env rb 32
    envs rq 2            ; указатели на переменные окружения

section '.data' writable
    prompt db "> Введите команду (например ./2.out): ", 0
    err_msg db "Ошибка: не удалось запустить файл.", 10, 0
    term_var db "TERM=xterm-256color", 0
    path_var db "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 0

section '.text' executable
_start: 
    mov rax, [rsp]          ; argc
    mov rbx, [rsp+8]        ; argv
    mov rcx, [rsp+16]       ; envp
    
    test rcx, rcx
    jnz .env_exists
    
    ; cоздаем свои переменные окружения
    mov qword [envs], term_var
    mov qword [envs+8], path_var
    mov qword [envs+16], 0  ; NULL терминируем
    mov rcx, envs
    
.env_exists:
    mov [env_ptr], rcx

main_loop:
    mov rsi, prompt
    call print_string

    mov rsi, buffer
    call input_keyboard

    cmp byte [buffer], 0
    je main_loop

    mov rdi, buffer
.find_end:
    cmp byte [rdi], 0
    je .end_found
    cmp byte [rdi], 10     ; \n
    je .replace_newline
    inc rdi
    jmp .find_end

.replace_newline:
    mov byte [rdi], 0

.end_found:
    mov rax, 57         ; sys_fork
    syscall
    
    cmp rax, 0
    jl .fork_error      
    je child_process    
    
    ; Родитель
    mov rdi, rax        
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    mov rax, 61         ; sys_wait4
    syscall
    
    jmp main_loop

.fork_error:
    ; Ошибка fork - просто продолжаем
    jmp main_loop

child_process:
    mov rax, buffer
    mov [args], rax
    mov qword [args+8], 0

    ;проверяем, нужно ли устанавливать TERM
    mov rdi, [env_ptr]
    mov rsi, term_var
    call find_env_var
    test rax, rax
    jnz .exec_with_env
    
    ; TERM не найден, создаем минимальное окружение
    mov qword [envs], term_var
    mov qword [envs+8], 0
    mov rdx, envs
    jmp .do_execve
    
.exec_with_env:
    mov rdx, [env_ptr]  ; используем оригинальное окружение
    
.do_execve:
    mov rax, 59         ; sys_execve
    mov rdi, buffer     
    mov rsi, args       
    ; rdx уже содержит envp
    syscall

    ; Если execve вернулся, значит ошибка
    mov rsi, err_msg
    call print_string
    call exit

; rdi = envp, rsi = искомая переменная (без значения)
; возвращает rax = указатель на найденную переменную или 0
find_env_var:
    push rbp
    mov rbp, rsp
    
    test rdi, rdi
    jz .not_found
    
.search_loop:
    mov rax, [rdi]      ; текущая переменная окружения
    test rax, rax
    jz .not_found
    
    ; сравниваем начало строки
    push rdi
    push rsi
    mov rdi, rax
    mov rcx, rsi
.compare:
    mov al, [rdi]
    mov bl, [rcx]
    test bl, bl
    jz .found_prefix    ; если дошли до конца искомой строки
    cmp al, bl
    jne .next_var
    inc rdi
    inc rcx
    jmp .compare
    
.next_var:
    pop rsi
    pop rdi
    add rdi, 8
    jmp .search_loop
    
.found_prefix:
    pop rsi
    pop rdi
    mov rax, [rdi]      ; возвращаем указатель на переменную
    jmp .done
    
.not_found:
    xor rax, rax
    
.done:
    leave
    ret