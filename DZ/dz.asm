format elf64

public queue_create
public queue_destroy
public enqueue
public dequeue
public queue_fill_random
public queue_count_even
public queue_get_odd_numbers
public queue_count_ending_in_1
public free_memory

include 'func.asm'

section '.data' writable
    f  db "/dev/urandom", 0

section '.bss' writable
    random_number rq 1
    queue_struct_size equ 40 
    
    heap_start rq 1
    initial_brk rq 1

section '.text' executable

; queue_create(capacity) -> queue_pointer
; rdi: capacity
queue_create:
    push rbx
    push r12
    push rdi          ; Сохраняем capacity

    ; 1. Получаем текущий адрес конца кучи (program break)
    mov rax, 12       ; sys_brk
    xor rdi, rdi      ; 0
    syscall
    
    ; Сохраняем указатель на начало выделяемого блока
    mov r12, rax      
    
    ; Если initial_brk еще не установлен (равен 0), сохраняем его
    mov rbx, [initial_brk]
    test rbx, rbx
    jnz .calc_size
    mov [initial_brk], rax ; Запоминаем точку старта, чтобы потом сделать free
    
.calc_size:
    ; 2. Вычисляем требуемый размер
    ; Нам нужно 40 байт под структуру + (capacity * 8) под буфер
    pop rdi           ; Восстанавливаем capacity из стека в rdi (текущее значение)
    push rdi          ; И кладем обратно, так как оно нужно для записи в структуру
    
    shl rdi, 3        ; rdi = capacity * 8 (размер буфера)
    add rdi, 40       ; добавляем размер самой структуры (40 байт)
    
    ; 3. Выделяем память (увеличиваем brk)
    add rdi, r12      ; rdi = новый адрес конца кучи (старый + размер)
    mov rax, 12       ; sys_brk
    syscall
    
    ; Теперь r12 указывает на начало нашей памяти.
    ; Структура лежит по адресу [r12]
    ; Буфер будет лежать по адресу [r12 + 40]
    
    ; 4. Инициализируем поля структуры очереди
    pop rsi           ; rsi = capacity
    
    xor rcx, rcx
    mov [r12], rcx       ; head = 0
    mov [r12+8], rcx     ; tail = 0
    mov [r12+16], rcx    ; size = 0
    mov [r12+24], rsi    ; capacity = rsi
    
    ; Устанавливаем указатель на буфер
    mov rax, r12
    add rax, 40          ; Смещаемся на размер структуры
    mov [r12+32], rax    ; buffer_pointer = адрес сразу за структурой
    
    mov rax, r12         ; Возвращаем указатель на структуру
    
    pop r12
    pop rbx
    ret

; queue_destroy(queue_pointer)
; rdi: queue_pointer
queue_destroy:
    mov rax, 12             ; sys_brk
    mov rdi, [initial_brk]  ; Возвращаем break point в начало
    syscall
    
    mov qword [initial_brk], 0
    
    ret

; enqueue(queue_pointer, value) -> rax: 1 (success) or 0 (full)
; rdi: queue_pointer, rsi: value
enqueue:
    mov r8, [rdi+16]         ; r8 = size
    mov r9, [rdi+24]         ; r9 = capacity
    cmp r8, r9
    je .full                 ; Если size == capacity, очередь полна

    mov r10, [rdi+32]        ; r10 = buffer
    mov r11, [rdi+8]         ; r11 = tail
    
    mov [r10 + r11 * 8], rsi ; buffer[tail] = value
    
    inc r11                  ; tail++
    cmp r11, r9
    jne .no_wrap
    xor r11, r11             ; tail = 0 (wrap around)
.no_wrap:
    mov [rdi+8], r11         ; Сохраняем новый tail
    
    inc qword [rdi+16]       ; size++
    
    mov rax, 1
    ret
.full:
    mov rax, 0
    ret

; dequeue(queue_pointer, value_pointer) -> rax: 1 (success) or 0 (empty)
; rdi: queue_pointer, rsi: value_pointer
dequeue:
    mov r8, [rdi+16]         ; r8 = size
    cmp r8, 0
    je .empty                ; Если size == 0, очередь пуста
    
    mov r9, [rdi+32]         ; r9 = buffer
    mov r10, [rdi]           ; r10 = head
    mov r11, [r9 + r10 * 8]  ; r11 = buffer[head]
    
    mov [rsi], r11           ; *value_pointer = r11
    
    inc r10                  ; head++
    mov r12, [rdi+24]        ; r12 = capacity
    cmp r10, r12
    jne .no_wrap
    xor r10, r10             ; head = 0 (wrap around)
.no_wrap:
    mov [rdi], r10           ; Сохраняем новый head
    
    dec qword [rdi+16]       ; size--
    
    mov rax, 1
    ret
.empty:
    mov rax, 0
    ret

; ranint() -> rax: random number
ranint:
    push rdi
    push rsi
    push rdx
    push r8
    
    mov rdi, f
    mov rax, 2       ; sys_open
    mov rsi, 0
    syscall 

    mov r8, rax      ; fd

    mov rax, 0       ; sys_read
    mov rdi, r8
    mov rsi, random_number
    mov rdx, 8
    syscall
    
    mov rax, 3       ; sys_close
    mov rdi, r8
    syscall
    
    mov rax, [random_number]
    pop r8
    pop rdx
    pop rsi
    pop rdi
    ret

; queue_fill_random(queue_pointer)
; rdi: queue_pointer
queue_fill_random:
    .loop:
        mov r8, [rdi+16]
        mov r9, [rdi+24]
        cmp r8, r9
        je .done

        call ranint
        push rdi
        mov rsi, rax
        call enqueue
        pop rdi
        jmp .loop
    .done:
        ret

; queue_count_even(queue_pointer) -> rax: count
; rdi: queue_pointer
queue_count_even:
    xor rax, rax             ; rax = count = 0
    mov r8, [rdi+16]         ; r8 = size
    cmp r8, 0
    je .done

    mov r9, [rdi]            ; r9 = head
    mov r10, [rdi+32]        ; r10 = buffer
    mov r11, [rdi+24]        ; r11 = capacity
    
    xor rcx, rcx             ; rcx = i = 0
.loop:
    cmp rcx, r8
    jge .done
    
    mov r12, [r10 + r9 * 8]  ; r12 = buffer[head]
    test r12, 1
    jnz .not_even
    inc rax
.not_even:
    inc r9
    cmp r9, r11
    jne .no_wrap
    xor r9, r9
.no_wrap:
    inc rcx
    jmp .loop
.done:
    ret

; queue_count_ending_in_1(queue_pointer) -> rax: count
; rdi: queue_pointer
queue_count_ending_in_1:
    xor rax, rax             ; rax = count = 0
    mov r8, [rdi+16]         ; r8 = size
    cmp r8, 0
    je .done

    mov r9, [rdi]            ; r9 = head
    mov r10, [rdi+32]        ; r10 = buffer
    mov r11, [rdi+24]        ; r11 = capacity
    mov r12, 10              ; Делитель
    
    xor rcx, rcx             ; rcx = i = 0
.loop:
    cmp rcx, r8
    jge .done
    
    push rax
    mov rax, [r10 + r9 * 8]
    xor rdx, rdx
    div r12                  ; rax = rax / 10, rdx = rax % 10
    cmp rdx, 1
    pop rax
    jne .not_ends_in_1
    inc rax
.not_ends_in_1:
    inc r9
    cmp r9, r11
    jne .no_wrap
    xor r9, r9
.no_wrap:
    inc rcx
    jmp .loop
.done:
    ret

; queue_get_odd_numbers(queue_pointer, output_array_pointer) -> rax: count
; rdi: queue_pointer, rsi: output_array_pointer
queue_get_odd_numbers:
    xor r13, r13             ; r13 = счетчик найденных нечетных чисел = 0
    mov r8, [rdi+16]         ; r8 = size
    cmp r8, 0
    je .done                 ; Если очередь пуста, выходим

    mov r9, [rdi]            ; r9 = head
    mov r10, [rdi+32]        ; r10 = buffer
    mov r11, [rdi+24]        ; r11 = capacity
    
    xor rcx, rcx             ; rcx = i = 0 (счетчик цикла)
.loop:
    cmp rcx, r8
    jge .done
    
    mov r12, [r10 + r9 * 8]  ; r12 = текущий элемент buffer[head]
    test r12, 1              ; Проверяем, является ли число нечетным
    jz .not_odd              ; Если четное, пропускаем

    ; Число нечетное, копируем его в выходной массив
    mov [rsi + r13 * 8], r12
    inc r13                  ; Увеличиваем счетчик

.not_odd:
    inc r9                   ; Двигаем голову очереди вперед
    cmp r9, r11
    jne .no_wrap
    xor r9, r9               ; Wrap around
.no_wrap:
    inc rcx
    jmp .loop
.done:
    mov rax, r13             ; Возвращаем count
    ret
    
free_memory:
    ret