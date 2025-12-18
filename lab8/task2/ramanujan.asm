format elf64

public _start

extrn printf
extrn scanf

section '.data' writable
    input_msg    db "Введите точность (например 0.000001): ", 0
    input_fmt    db "%lf", 0
    
    header       db "Погрешность     Члены ряда      Члены дроби     Значение", 0xA, 0
    table_row    db "%-15.8f %-15d %-15d %-15.10f", 0xA, 0
    
    res_msg      db 0xA, "========= Итоги расчета =========", 0xA, 0
    msg_series   db "Сумма ряда (S)      = %.10f", 0xA, 0
    msg_frac     db "Цепная дробь (F)    = %.10f", 0xA, 0
    msg_total    db "Результат (S + F)   = %.10f", 0xA, 0
    msg_target   db "Целевое значение    = %.10f", 0xA, 0
    
    const_1      dq 1.0
    const_2      dq 2.0
    target_val   dq 2.0663656770612  ; Точное значение для проверки

section '.bss' writable
    epsilon      rq 1
    
    ; переменные ряда
    series_sum   rq 1
    series_term  rq 1
    series_cnt   rq 1
    n_idx        rq 1
    
    ; переменные дроби
    frac_val     rq 1
    frac_prev    rq 1
    frac_cnt     rq 1
    k_depth      rq 1
    
    ; общее
    total_res    rq 1

section '.text' executable

; S = 1 + 1/3 + 1/15 + ...
compute_series:
    push rbp
    mov rbp, rsp
    
    finit
    fld1
    fst qword [series_sum]   ; sum = 1.0
    fstp qword [series_term] ; term = 1.0
    
    mov qword [series_cnt], 1
    mov qword [n_idx], 1
    
.loop:
    ; term = term / (2n + 1)
    fld qword [series_term]
    
    fild qword [n_idx]
    fadd st0, st0             ; 2n
    fld1
    faddp st1, st0            ; 2n + 1
    
    fdivp st1, st0            ; term / (2n+1)
    fst qword [series_term]
    
    ; sum += term
    fadd qword [series_sum]
    fstp qword [series_sum]
    
    inc qword [series_cnt]
    
    ; проверка: если term < epsilon, стоп
    fld qword [series_term]
    fld qword [epsilon]
    fcomip st1
    fstp st0
    
    ja .done
    
    inc qword [n_idx]
    jmp .loop

.done:
    leave
    ret

; вычисление цепной дроби
compute_fraction:
    push rbp
    mov rbp, rsp
    
    finit
    fldz
    fstp qword [frac_prev]
    
    mov qword [k_depth], 1
    
.outer_loop:
    ; считаем дробь снизу вверх для глубины k_depth
    fldz                      ; начинаем с 0
    
    mov rcx, [k_depth]        ; счетчик от K до 1
    
.inner_loop:
    ; val = a_i / (1 + val)
    ; знаменатель: 1 + val
    fld1
    faddp st1, st0
    
    ; числитель a_i:
    ; если i=1 (последний шаг), то числитель 1.
    ; иначе числитель = i-1.
    cmp rcx, 1
    jne .not_first
    fld1
    jmp .do_div
.not_first:
    mov rax, rcx
    dec rax
    push rax
    fild qword [rsp]
    add rsp, 8
    
.do_div:
    ; st0 = a_i, st1 = (1 + val)
    fdivrp st1, st0           ; результат = a_i / (1+val)
    
    loop .inner_loop
    
    fst qword [frac_val]
    
    ; сравнение с предыдущим значением
    fld qword [frac_prev]     ; st0 = prev, st1 = curr
    fsubp st1, st0            ; st0 = curr - prev
    fabs                      ; st0 = |diff|
    
    fld qword [epsilon]
    fcomip st1
    fstp st0
    
    ja .converged             ; если epsilon > |diff|, то сошлось
    
    ; обновляем prev и продолжаем
    mov rax, [frac_val]
    mov [frac_prev], rax
    
    inc qword [k_depth]
    
    ; лимит (на случай слишком малого epsilon)
    cmp qword [k_depth], 20000
    jl .outer_loop
    
.converged:
    mov rax, [k_depth]
    mov [frac_cnt], rax
    leave
    ret

_start:
    and rsp, -16
    
    ; ввод
    mov rdi, input_msg
    xor rax, rax
    call printf
    
    mov rdi, input_fmt
    mov rsi, epsilon
    xor rax, rax
    call scanf
    
    ; вычисления
    call compute_series
    call compute_fraction
    
    ; итоговая сумма
    finit
    fld qword [series_sum]
    fadd qword [frac_val]
    fstp qword [total_res]
    
    ; вывод таблицы
    mov rdi, header
    xor rax, rax
    call printf
    
    mov rdi, table_row
    movq xmm0, [epsilon]
    mov rsi, [series_cnt]
    mov rdx, [frac_cnt]
    movq xmm1, [total_res]
    mov rax, 2
    call printf
    
    ; вывод итогов
    mov rdi, res_msg
    xor rax, rax
    call printf
    
    mov rdi, msg_series
    movq xmm0, [series_sum]
    mov rax, 1
    call printf
    
    mov rdi, msg_frac
    movq xmm0, [frac_val]
    mov rax, 1
    call printf
    
    mov rdi, msg_total
    movq xmm0, [total_res]
    mov rax, 1
    call printf

    mov rdi, msg_target
    movq xmm0, [target_val]
    mov rax, 1
    call printf
    
    mov rax, 60
    xor rdi, rdi
    syscall