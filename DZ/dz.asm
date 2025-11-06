format elf64

extrn malloc
extrn free

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

queue_create:
    ; Выделяем память под саму структуру очереди
    push rdi
    mov rdi, queue_struct_size
    call malloc
    pop rsi ; rsi = capacity
    
    xor rcx, rcx
    mov [rax], rcx   ; head = 0
    mov [rax+8], rcx     ; tail = 0
    mov [rax+16], rcx    ; size = 0
    mov [rax+24], rsi        ; capacity = rsi
    
    ; Выделяем память под буфер элементов очереди
    mov rdi, rsi             ; rdi = capacity
    shl rdi, 3               ; rdi = capacity * 8 (размер)

    mov rsi, rdi             ; Копируем размер из RDI в RSI
    xor rdi, rdi             ; Обнуляем RDI для адреса (addr = 0)

    push rax ; Сохраняем указатель на структуру

    mov rdx, 0x3
    mov r10,0x22
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
        
    pop rdi                  ; rdi = указатель на структуру
    mov [rdi+32], rax        ; Сохраняем указатель на буфер
    
    mov rax, rdi             ; Возвращаем указатель на структуру
    ret

; rdi: queue_pointer
queue_destroy:
    mov rsi, [rdi+24]        ; rsi = capacity
    shl rsi, 3               ; capacity * 8
    mov rdx, rdi             ; Сохраняем указатель на структуру
    mov rdi, [rdi+32]        ; rdi = buffer_pointer
    mov rax, 11              ; syscall munmap
    syscall
    
    mov rdi, rdx             ; rdi = указатель на структуру
    call free                ; Освобождаем память структуры
    ret


; enqueue(queue_pointer, value) -> rax: 1 (success) or 0 (full) - добавляет элемент в конец очереди.
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

; dequeue(queue_pointer, value_pointer) -> rax: 1 (success) or 0 (empty) - извлекает элемент из начала очереди.
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
    mov rax, 2 
    mov rsi, 0
    syscall 

    mov r8, rax

    mov rax, 0 
    mov rdi, r8
    mov rsi, random_number
    mov rdx, 8
    syscall
    
    mov rax, 3
    mov rdi, r8
    syscall
    
	mov rax, [random_number]
	pop r8
	pop rdx
	pop rsi
	pop rdi
	ret

; queue_fill_random(queue_pointer) - заполняет очередь случайными числами до фулла
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
; Находит все нечетные числа и копирует их в предоставленный массив.
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
    jz .not_odd              ; Если четное (zero flag = 1), переходим к след. элементу

    ; Число нечетное, копируем его в выходной массив
    mov [rsi + r13 * 8], r12
    inc r13                  ; Увеличиваем счетчик нечетных чисел

.not_odd:
    inc r9                   ; Двигаем голову очереди вперед
    cmp r9, r11
    jne .no_wrap
    xor r9, r9               ; Возвращаемся в начало буфера, если дошли до конца
.no_wrap:
    inc rcx
    jmp .loop
.done:
    mov rax, r13             ; Возвращаем количество найденных нечетных чисел
    ret
    
free_memory:
	mov rax, 11              ; syscall munmap
	syscall
	ret