format elf64
public _start
include 'func.asm'

section '.bss' writable
    buffer rb 256
    pid rq 1
    status rd 1
    args rq 2           ; Аргументы для execve

section '.data'
    prompt db "> Введите команду (например ./lab7_2): ", 0
    err_msg db "Ошибка: не удалось запустить файл.", 10, 0
    exit_msg db "Завершение работы.", 10, 0

section '.text' executable
_start: 
main_loop:
    ; Вывод приглашения
    mov rsi, prompt
    call print_string

    ; Ввод с клавиатуры
    mov rsi, buffer
    call input_keyboard

    ; Если введена пустая строка (просто Enter) - повтор
    cmp byte [buffer], 0
    je main_loop

    ; Fork - создание процесса
    mov rax, 57         ; sys_fork
    syscall
    
    cmp rax, 0
    jl main_loop        ; Ошибка fork
    je child_process    ; Дочерний процесс
    
    ; --- Родительский процесс ---
    ; Ждем завершения запущенной программы
    mov rdi, rax        ; PID ребенка
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    mov rax, 61         ; sys_wait4
    syscall
    
    jmp main_loop       ; Повторяем цикл

child_process:
    ; Настройка аргументов: argv = {имя_файла, NULL}
    mov rax, buffer
    mov [args], rax
    mov qword [args+8], 0

    ; Запуск программы
    mov rax, 59         ; sys_execve
    mov rdi, buffer     ; filename
    mov rsi, args       ; argv
    mov rdx, 0          ; envp (NULL)
    syscall

    ; Если мы здесь, execve не сработал (неверное имя файла)
    mov rsi, err_msg
    call print_string
    call exit