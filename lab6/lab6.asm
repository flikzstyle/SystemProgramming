format ELF64
public _start

; --- Внешние функции ---
extrn initscr
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn printw
extrn noecho
extrn keypad
extrn stdscr
extrn move
extrn getch
extrn clear
extrn addch
extrn refresh
extrn endwin
extrn exit
extrn color_pair
extrn insch
extrn cbreak
extrn timeout
extrn setrnd
extrn get_random
extrn usleep

; --- Секция неинициализированных данных ---
section '.bss' writable
    max_x           dq 1
    max_y           dq 1
    max_border_x    dq 1
    max_border_y    dq 1
    min_border_x    dq 1
    min_border_y    dq 1
    pos_x           dq 0
    pos_y           dq 0
    flag            dq 1
    color_flag      dq 0
    palette         dq 1
    delay           dq ?
    speed_mode      dq 0

; --- Секция кода ---
section '.text' executable
_start:
.initialize:
    call    initscr
    
    ; Включаем необходимые режимы ncurses
    call    cbreak
    call    noecho
    
    ; Включаем обработку специальных клавиш
    mov     rdi, [stdscr]
    mov     rsi, 1
    call    keypad

    mov     rdi, [stdscr]
    call    getmaxx
    dec     rax
    mov     [max_x], rax

    mov     rdi, [stdscr]
    call    getmaxy
    dec     rax
    mov     [max_y], rax
    
    ; Инициализация границ спирали
    xor     rdx, rdx
    mov     rax, [max_y]
    mov     rbx, 2
    div     rbx
    mov     [min_border_y], rax
    mov     [min_border_x], rax
    mov     [max_border_y], rax

    mov     rax, [max_x]
    mov     rbx, [min_border_x]
    sub     rax, rbx
    mov     [max_border_x], rax

    inc     [max_border_x]
    inc     [max_border_y]
    dec     [min_border_x]
    dec     [min_border_y]

    call    start_color
    mov     rdi, 1
    mov     rsi, 2
    mov     rdx, 2
    call    init_pair
    mov     rdi, 2
    mov     rsi, 4
    mov     rdx, 4
    call    init_pair

    mov     rax, ' '
    or      rax, 0x100
    mov     [palette], rax
    
    ; Начальная скорость - стандартная
    mov     qword [delay], 80000
    mov     qword [speed_mode], 0

    call    refresh
    
    ; Начальная позиция - центр
    mov     rax, [min_border_y]
    mov     [pos_y], rax
    mov     rax, [min_border_x]
    mov     [pos_x], rax
    
    ; НАЧИНАЕМ СРАЗУ ДВИЖЕНИЕ ВПРАВО
    mov     qword [flag], 2  ; 2 = right
    
    ; Сразу рисуем первую точку
    mov     rdi, [pos_y]
    mov     rsi, [pos_x]
    call    move
    mov     rdi, [palette]
    call    addch
    call    refresh
    
    jmp     .mloop

; --- Главный цикл программы ---
.mloop:
    ; Задержка в зависимости от режима скорости
    mov     rdi, [delay]
    call    usleep

    ; НЕБЛОКИРУЮЩИЙ ВВОД - КЛЮЧЕВОЙ МОМЕНТ!
    mov     rdi, 0
    call    timeout
    call    getch

    ; Проверяем ввод (должно быть сравнение с БЕЗЗНАКОВЫМ значением)
    cmp     rax, -1         ; -1 означает отсутствие ввода
    je      .no_input
    
    cmp     rax, 117        ; 'u' в ASCII
    je      .all_exit
    cmp     rax, 101        ; 'e' в ASCII  
    je      .change_speed

.no_input:
    ; Основная логика движения
    cmp     [flag], 1
    je      .down
    cmp     [flag], 2
    je      .right
    cmp     [flag], 3
    je      .up
    cmp     [flag], 4
    je      .left

.after_move:
    ; Устанавливаем позицию и рисуем
    mov     rdi, [pos_y]
    mov     rsi, [pos_x]
    call    move
    mov     rdi, [palette]
    call    addch
    call    refresh

    ; Проверка границ
    jmp     .check_borders

; --- Проверка границ для смены направления ---
.check_borders:
    cmp     [flag], 2      ; right -> check if hit right border
    je      .check_right
    cmp     [flag], 1      ; down -> check if hit bottom border  
    je      .check_down
    cmp     [flag], 4      ; left -> check if hit left border
    je      .check_left
    cmp     [flag], 3      ; up -> check if hit top border
    je      .check_up
    jmp     .check_screen

.check_right:
    mov     rax, [max_border_x]
    cmp     [pos_x], rax
    jge     .set_down
    jmp     .check_screen

.check_down:
    mov     rax, [max_border_y]
    cmp     [pos_y], rax
    jge     .set_left
    jmp     .check_screen

.check_left:
    mov     rax, [min_border_x]
    cmp     [pos_x], rax
    jle     .set_up
    jmp     .check_screen

.check_up:
    mov     rax, [min_border_y]
    cmp     [pos_y], rax
    jle     .set_right
    jmp     .check_screen

; --- Проверка выхода за пределы экрана ---
.check_screen:
    mov     rax, [max_y]
    cmp     [pos_y], rax
    jge     .reset_and_change_color
    cmp     qword [pos_y], 0
    jle     .reset_and_change_color
    mov     rax, [max_x]
    cmp     [pos_x], rax
    jge     .reset_and_change_color
    cmp     qword [pos_x], 0
    jle     .reset_and_change_color
    jmp     .mloop

; --- Сброс спирали и смена цвета ---
.reset_and_change_color:
    ; Пересчет границ
    xor     rdx, rdx
    mov     rax, [max_y]
    mov     rbx, 2
    div     rbx
    mov     [min_border_y], rax
    mov     [min_border_x], rax
    mov     [max_border_y], rax

    mov     rax, [max_x]
    mov     rbx, [min_border_x]
    sub     rax, rbx
    mov     [max_border_x], rax

    inc     [max_border_x]
    inc     [max_border_y]
    dec     [min_border_x]
    dec     [min_border_y]

    ; Смена цвета
    cmp     [color_flag], 0
    je      .white
    jmp     .orange

.white:
    mov     [color_flag], 1
    mov     rax, [palette]
    and     rax, 0xff
    or      rax, 0x200  ; зеленый
    mov     [palette], rax
    jmp     .reset_position

.orange:
    mov     [color_flag], 0
    mov     rax, [palette]
    and     rax, 0xff
    or      rax, 0x100  ; красный
    mov     [palette], rax

.reset_position:
    ; Сброс позиции и начинаем движение ВПРАВО
    mov     rax, [min_border_y]
    mov     [pos_y], rax
    mov     rax, [min_border_x]
    mov     [pos_x], rax
    mov     qword [flag], 2  ; начинаем с движения вправо
    
    ; Сразу рисуем точку в начальной позиции
    mov     rdi, [pos_y]
    mov     rsi, [pos_x]
    call    move
    mov     rdi, [palette]
    call    addch
    call    refresh
    
    jmp     .mloop

.all_exit:
    call    endwin
    xor     rdi, rdi
    call    exit

; --- Логика смены скорости (4 режима) ---
.change_speed:
    cmp     [speed_mode], 0
    je      .set_fast
    cmp     [speed_mode], 1
    je      .set_very_fast
    cmp     [speed_mode], 2
    je      .set_max_fast
    jmp     .set_normal

.set_normal:
    ; Стандартная скорость
    mov     qword [delay], 80000
    mov     qword [speed_mode], 0
    jmp     .mloop

.set_fast:
    ; Быстрая скорость
    mov     qword [delay], 40000
    mov     qword [speed_mode], 1
    jmp     .mloop

.set_very_fast:
    ; Очень быстрая скорость
    mov     qword [delay], 15000
    mov     qword [speed_mode], 2
    jmp     .mloop

.set_max_fast:
    ; Максимальная скорость
    mov     qword [delay], 3000
    mov     qword [speed_mode], 3
    jmp     .mloop

; --- Блоки движения ---
.down:
    inc     [pos_y]
    jmp     .after_move
.right:
    inc     [pos_x]
    jmp     .after_move
.up:
    dec     [pos_y]
    jmp     .after_move
.left:
    dec     [pos_x]
    jmp     .after_move

; --- Смена направления ---
.set_right:
    mov     qword [flag], 2
    jmp     .mloop

.set_down:
    mov     qword [flag], 1
    ; Расширяем границы для следующего витка спирали
    inc     [max_border_x]
    inc     [max_border_y]
    dec     [min_border_x]
    dec     [min_border_y]
    jmp     .mloop

.set_left:
    mov     qword [flag], 4
    jmp     .mloop

.set_up:
    mov     qword [flag], 3
    jmp     .mloop