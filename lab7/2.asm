format elf64
public _start

include 'func.asm'

COUNT = 20              

section '.bss' writable
    array_ptr rq 1      
    freq_buf  rd 10     

section '.data' writable
    dev_urandom db "/dev/urandom", 0
    space_char  db " ", 0
    
    msg_gen     db "Сгенерированный массив (0-99): ", 10, 0
    
    msg_t1      db "1. Числа, кратные 5: ", 0
    msg_t1_res  db 10, "   Количество: ", 0
    
    msg_t2      db "2. Сумма цифр кратна 3 (числа): ", 0
    msg_t2_res  db 10, "   Количество: ", 0
    
    msg_t3      db "3. Третье максимальное число (уникальное): ", 0
    msg_t4      db "4. Наиболее частая цифра: ", 0

section '.text' executable
_start:
    ; 1. Выделение памяти
    mov rax, 9          ; sys_mmap
    mov rdi, 0
    mov rsi, COUNT * 4
    mov rdx, 3          ; PROT_READ | PROT_WRITE
    mov r10, 34         ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    syscall
    mov [array_ptr], rax

    ; 2. Заполнение массива
    call fill_random_array

    ; 3. Вывод массива
    mov rsi, msg_gen
    call print_string
    call print_array

    ; Задача 1
    mov rax, 57         ; fork
    syscall
    cmp rax, 0
    je do_task1
    call wait_child

    ; Задача 2
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task2
    call wait_child

    ; Задача 3
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task3
    call wait_child

    ; Задача 4
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task4
    call wait_child

    call exit


wait_child:
    push rax
    push rdi
    push rsi
    push rdx
    push r10
    mov rax, 61         ; sys_wait4
    mov rdi, -1
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall
    pop r10
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

fill_random_array:
    mov rax, 2          ; open
    mov rdi, dev_urandom
    mov rsi, 0
    syscall
    mov rbx, rax        ; fd

    mov rax, 0          ; read
    mov rdi, rbx
    mov rsi, [array_ptr]
    mov rdx, COUNT * 4
    syscall

    mov rax, 3          ; close
    mov rdi, rbx
    syscall

    ; Нормализация (0-99)
    mov rcx, COUNT
    mov rbx, [array_ptr]
.norm_loop:
    mov eax, [rbx]
    and eax, 0x7FFFFFFF ; abs
    xor edx, edx
    mov edi, 100
    div edi
    mov [rbx], edx
    add rbx, 4
    loop .norm_loop
    ret

print_array:
    mov rcx, COUNT
    mov rbx, [array_ptr]
.p_loop:
    mov eax, [rbx]
    call print_number
    mov rsi, space_char
    call print_string
    add rbx, 4
    loop .p_loop
    call print_newline
    call print_newline
    ret

; ЗАДАЧИ
; 1: кратные 5 
do_task1:
    mov rsi, msg_t1
    call print_string

    xor r12, r12        ; Счетчик
    mov rcx, COUNT
    mov rbx, [array_ptr]
.loop:
    mov eax, [rbx]      ; Загружаем число
    mov r15d, eax       ; СОХРАНЯЕМ число во временный регистр

    xor edx, edx
    mov edi, 5
    div edi             ; EAX = частное, EDX = остаток
    
    test edx, edx       ; Проверяем остаток
    jnz .skip

    ; Число подходит
    inc r12
    mov eax, r15d       ; ВОССТАНАВЛИВАЕМ исходное число для печати
    call print_number
    mov rsi, space_char
    call print_string

.skip:
    add rbx, 4
    dec rcx
    jnz .loop

    mov rsi, msg_t1_res
    call print_string
    mov rax, r12
    call print_number
    call print_newline
    call print_newline
    call exit

; 2: сумма цифр кратна 3 
do_task2:
    mov rsi, msg_t2
    call print_string

    xor r12, r12
    mov rcx, COUNT
    mov rbx, [array_ptr]
.loop:
    mov eax, [rbx]
    mov r15d, eax       ; сохраняем исходное число
    
    ; считаем сумму цифр
    xor r9d, r9d        ; r9d = сумма
    mov edi, 10
.digits_sum:
    xor edx, edx
    div edi
    add r9d, edx
    test eax, eax
    jnz .digits_sum
    
    ; проверяем сумму на кратность 3
    mov eax, r9d
    xor edx, edx
    mov edi, 3
    div edi
    
    test edx, edx
    jnz .skip

    inc r12
    mov eax, r15d       ; восстанавливаем число для вывода
    call print_number
    mov rsi, space_char
    call print_string

.skip:
    add rbx, 4
    dec rcx
    jnz .loop

    mov rsi, msg_t2_res
    call print_string
    mov rax, r12
    call print_number
    call print_newline
    call print_newline
    call exit

; 3: третье максимальное 
do_task3:
    mov rsi, msg_t3
    call print_string

    ; используем r8d, r9d, r10d как 32-битные регистры для значений 0-99
    mov r8d, -1         ; Max1
    mov r9d, -1         ; Max2
    mov r10d, -1        ; Max3

    mov rcx, COUNT
    mov rbx, [array_ptr]
.loop:
    mov eax, [rbx]      ; читаем как 32-битное число

    ; пропускаем дубликаты
    cmp eax, r8d
    je .next
    cmp eax, r9d
    je .next
    cmp eax, r10d
    je .next

    ; сравнение с Max1 (r8d)
    cmp eax, r8d
    jle .chk2
    ; New Max1
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, eax
    jmp .next

.chk2:
    ; сравнение с Max2 (r9d)
    cmp eax, r9d
    jle .chk3
    ; New Max2
    mov r10d, r9d
    mov r9d, eax
    jmp .next

.chk3:
    ; сравнение с Max3 (r10d)
    cmp eax, r10d
    jle .next
    ; New Max3
    mov r10d, eax

.next:
    add rbx, 4
    dec rcx
    jnz .loop

    ; если третье число не найдено (массив слишком мал или одинаков)
    cmp r10d, -1
    je .not_found
    
    mov eax, r10d
    call print_number
    jmp .done
.not_found:
    mov rax, 0
    call print_number
.done:
    call print_newline
    call print_newline
    call exit

; 4: частая цифра 
do_task4:
    mov rsi, msg_t4
    call print_string

    ; очистка буфера
    mov rdi, freq_buf
    xor rax, rax
    mov rcx, 10
    rep stosd

    mov rcx, COUNT
    mov rbx, [array_ptr]
.loop_nums:
    mov eax, [rbx]
    
    mov edi, 10
.digits:
    xor edx, edx
    div edi
    
    lea rsi, [freq_buf]
    inc dword [rsi + rdx*4]
    
    test eax, eax
    jnz .digits

    add rbx, 4
    dec rcx
    jnz .loop_nums

    xor r12, r12        ; Самая частая цифра
    xor r13, r13        ; Количество повторений
    
    xor rcx, rcx
.find_max:
    mov rsi, freq_buf
    mov eax, [rsi + rcx*4]
    
    cmp eax, r13d
    jle .skip_update
    mov r13d, eax
    mov r12, rcx
.skip_update:
    inc rcx
    cmp rcx, 10
    jl .find_max

    mov rax, r12
    call print_number
    
    call print_newline
    call exit