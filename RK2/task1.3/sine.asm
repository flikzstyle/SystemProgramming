format ELF64
public _start

extrn initscr
extrn endwin
extrn move
extrn addch
extrn refresh
extrn clear
extrn getmaxx
extrn getmaxy
extrn usleep
extrn curs_set
extrn sin
extrn exit

section '.data' writable
    omega       dq 0.1      ; Плавность волны
    factor_3    dq 3.0      ; Амплитуда (высота/3)
    factor_2    dq 2.0      ; Центр (высота/2)
    delay       dq 50000    
    
    cursor_char dq '#'      ; Символ курсора
    empty_char  dq ' '      

section '.bss' writable
    max_x       dq ?
    max_y       dq ?
    pos_x       dq 0
    pos_y       dq 0
    
    amplitude   dq ?
    center_y    dq ?
    win_ptr     dq ?

section '.text' executable

_start:
    and     rsp, -16

    call    initscr
    mov     [win_ptr], rax
    
    mov     rdi, 0
    call    curs_set

    mov     rdi, [win_ptr]
    call    getmaxx
    dec     rax
    mov     [max_x], rax

    mov     rdi, [win_ptr]
    call    getmaxy
    dec     rax
    mov     [max_y], rax
    
    ; Расчет геометрии
    cvtsi2sd xmm0, [max_y]
    divsd    xmm0, [factor_2]
    movsd    [center_y], xmm0
    
    cvtsi2sd xmm0, [max_y]
    divsd    xmm0, [factor_3]
    movsd    [amplitude], xmm0

    mov     qword [pos_x], 0

.loop:
    ; 1. вычисляем Y для текущего X
    cvtsi2sd xmm0, [pos_x]
    mulsd    xmm0, [omega]
    call    sin
    mulsd    xmm0, [amplitude]
    addsd    xmm0, [center_y]
    cvttsd2si rax, xmm0
    mov      [pos_y], rax

    ; 2.  отрисовка курсора
    mov     rdi, [pos_y]
    mov     rsi, [pos_x]
    call    move
    
    mov     rdi, [cursor_char]
    call    addch
    
    call    refresh

    ; 3. ждем (чтобы увидеть курсор в этой точке)
    mov     rdi, [delay]
    call    usleep

    ; 4. стираем курсор (в той же точке)
    mov     rdi, [pos_y]
    mov     rsi, [pos_x]
    call    move
    
    mov     rdi, [empty_char] 
    call    addch

    ; 5. двигаем координату X вперед
    inc     qword [pos_x]
    
    ; Проверка границ
    mov     rax, [pos_x]
    cmp     rax, [max_x]
    jl      .loop

    ; Если дошли до края экрана -> сброс X в 0
    mov     qword [pos_x], 0
    jmp     .loop

    call    endwin
    xor     rdi, rdi
    call    exit