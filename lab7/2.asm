format elf64
public _start
include 'func.asm'

; Константы
COUNT = 20              ; Размер массива

section '.bss' writable
    array_ptr rq 1      ; Указатель на массив
    freq_buf  rd 10     ; Для 4-й задачи

section '.data'
    dev_urandom db "/dev/urandom", 0
    space_char  db " ", 0
    comma       db ", ", 0
    msg_gen     db "Сгенерированный массив (0-99): ", 10, 0
    
    msg_task1 db "1. Числа, кратные 5: ", 0
    msg_t1_cnt db 10, "   -> Всего: ", 0
    
    msg_task2 db "2. Сумма цифр кратна 3 (числа): ", 0
    msg_t2_cnt db 10, "   -> Всего: ", 0
    
    msg_task3 db "3. Третье максимальное число: ", 0
    msg_task4 db "4. Наиболее частая цифра: ", 0

section '.text' executable
_start:
    ; 1. Выделение памяти
    mov rax, 9          ; sys_mmap
    mov rdi, 0
    mov rsi, COUNT * 4
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    mov r9, 0
    syscall
    mov [array_ptr], rax

    ; 2. Заполнение случайными числами
    mov rax, 2          ; sys_open
    mov rdi, dev_urandom
    mov rsi, 0
    syscall
    mov rbx, rax

    mov rax, 0          ; sys_read
    mov rdi, rbx
    mov rsi, [array_ptr]
    mov rdx, COUNT * 4
    syscall

    mov rax, 3          ; close
    mov rdi, rbx
    syscall

    ; --- НОРМАЛИЗАЦИЯ (0-99) ---
    ; Превращаем случайные биты в числа от 0 до 99 для наглядности
    mov rcx, COUNT
    mov rbx, [array_ptr]
mod_loop:
    mov eax, [rbx]
    and eax, 0x7FFFFFFF ; убираем знак
    xor edx, edx
    mov edi, 100
    div edi             ; edx = eax % 100
    mov [rbx], edx      ; сохраняем остаток
    add rbx, 4
    loop mod_loop

    ; --- ВЫВОД МАССИВА ---
    mov rsi, msg_gen
    call print_string

    mov rcx, COUNT
    mov rbx, [array_ptr]
print_arr:
    mov eax, [rbx]
    push rcx
    push rbx
    call print_number
    mov rsi, space_char
    call print_string
    pop rbx
    pop rcx
    add rbx, 4
    loop print_arr
    
    call print_newline
    call print_newline

    ; --- FORK ПРОЦЕССОВ ---
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task1
    
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task2
    
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task3
    
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task4

    ; --- РОДИТЕЛЬ ЖДЕТ ---
wait_loop:
    mov rax, 61
    mov rdi, -1
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall
    cmp rax, 0
    jg wait_loop

    call print_newline
    call exit

; =============================================
; ЗАДАЧИ
; =============================================

do_task1: ; Кратные 5
    mov rsi, msg_task1
    call print_string
    
    xor rbx, rbx        ; счетчик
    mov rcx, COUNT
    mov r8, [array_ptr]
.loop:
    mov eax, [r8]
    xor rdx, rdx
    mov rdi, 5
    div rdi
    cmp rdx, 0
    jne .next
    
    ; Нашли число! Выводим его
    inc rbx
    mov eax, [r8]
    push rcx
    push rbx
    push r8
    call print_number
    mov rsi, space_char
    call print_string
    pop r8
    pop rbx
    pop rcx
    
.next:
    add r8, 4
    loop .loop
    
    ; Вывод общего количества
    mov rsi, msg_t1_cnt
    call print_string
    mov rax, rbx
    call print_number
    call print_newline
    call exit

do_task2: ; Сумма цифр кратна 3
    mov rsi, msg_task2
    call print_string
    
    xor rbx, rbx
    mov rcx, COUNT
    mov r8, [array_ptr]
.loop:
    mov eax, [r8]
    xor r9, r9          ; сумма цифр
    push rcx
    push rax
    
    mov ecx, 10
.digits:
    xor edx, edx
    div ecx
    add r9d, edx
    test eax, eax
    jnz .digits
    
    ; Проверка суммы
    mov eax, r9d
    xor edx, edx
    mov ecx, 3
    div ecx
    
    pop rax
    pop rcx
    
    cmp edx, 0
    jne .next
    
    ; Подходит! Выводим число
    inc rbx
    push rcx
    push rbx
    push r8
    mov eax, [r8]
    call print_number
    mov rsi, space_char
    call print_string
    pop r8
    pop rbx
    pop rcx
    
.next:
    add r8, 4
    loop .loop
    
    mov rsi, msg_t2_cnt
    call print_string
    mov rax, rbx
    call print_number
    call print_newline
    call exit

do_task3: ; Третье максимальное (уникальное)
    mov rsi, msg_task3
    call print_string
    
    xor r8, r8  ; max1
    xor r9, r9  ; max2
    xor r10, r10 ; max3
    
    mov rcx, COUNT
    mov rsi, [array_ptr]
.loop:
    mov eax, [rsi]
    
    cmp eax, r8d
    je .next        ; Пропускаем дубликаты max1
    cmp eax, r8d
    jbe .chk2
    ; > max1
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, eax
    jmp .next
.chk2:
    cmp eax, r9d
    je .next        ; Пропускаем дубликаты max2
    cmp eax, r9d
    jbe .chk3
    ; > max2
    mov r10d, r9d
    mov r9d, eax
    jmp .next
.chk3:
    cmp eax, r10d
    je .next        ; Пропускаем дубликаты max3
    cmp eax, r10d
    jbe .next
    ; > max3
    mov r10d, eax
.next:
    add rsi, 4
    loop .loop
    
    mov rax, r10
    call print_number
    call print_newline
    call exit

do_task4: ; Частая цифра
    mov rsi, msg_task4
    call print_string
    
    mov rdi, freq_buf
    xor rax, rax
    mov rcx, 10
    rep stosd
    
    mov rcx, COUNT
    mov rsi, [array_ptr]
.outer:
    mov eax, [rsi]
    push rcx
    mov ecx, 10
.digits:
    xor edx, edx
    div ecx
    mov r11, freq_buf
    inc dword [r11 + rdx*4]
    test eax, eax
    jnz .digits
    pop rcx
    add rsi, 4
    loop .outer
    
    xor rbx, rbx
    mov r11, freq_buf
    mov eax, [r11]
    mov rcx, 1
.find_max:
    mov edx, [r11 + rcx*4]
    cmp edx, eax
    jle .skip
    mov eax, edx
    mov rbx, rcx
.skip:
    inc rcx
    cmp rcx, 10
    jl .find_max
    
    mov rax, rbx
    call print_number
    call print_newline
    call exit