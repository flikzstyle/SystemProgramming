format elf64
public _start

include '../../funcnew.asm'

section '.data' writable
    msg_n db "Введите n: ", 0
    msg_input_file db "Файл куда запишутся все простые числа: ", 0
    msg_output_file db "Файл куда запишутся простые числа оканчивающиеся на 1: ", 0
    msg_error db "Ошибка", 10, 0
    msg_success db "Успешно", 10, 0
    newline db 10, 0
    space db " ", 0
    
section '.bss' writable
    n dq 0
    input_filename rb 256
    output_filename rb 256
    buffer rb 1024
    number_buffer rb 32
    current_number dq 0

section '.text' executable
input_keyboard:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall

    mov rcx, rax
    dec rcx
    mov byte [rsi + rcx], 0

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

_start:
    mov rsi, msg_n
    call print_str
    mov rsi, buffer
    call input_keyboard
    mov rsi, buffer
    call str_number
    mov [n], rax

    mov rsi, msg_input_file
    call print_str
    mov rsi, input_filename
    call input_keyboard

    mov rsi, msg_output_file
    call print_str
    mov rsi, output_filename
    call input_keyboard

    call write_primes_to_file
    test rax, rax
    js error_exit

    call filter_primes_ending_with_one
    test rax, rax
    js error_exit

    mov rsi, msg_success
    call print_str
    jmp exit

error_exit:
    mov rsi, msg_error
    call print_str
    jmp exit

write_primes_to_file:
    push r12
    push r13
    push r14

    mov rax, 2
    mov rdi, input_filename
    mov rsi, 0x241  ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error
    mov r12, rax    ; fd

    mov r13, 2      ; с 2 до n
    mov r14, [n]   

.write_loop:
    cmp r13, r14
    jg .close

    mov rdi, r13
    call is_prime
    test rax, rax
    jz .next_number

    mov rdi, r13
    call number_to_string  ; запись простого числа в файл
    mov rsi, number_buffer
    call str_len
    mov rdx, rax    ; длина строки

    mov rax, 1
    mov rdi, r12
    mov rsi, number_buffer
    syscall

    mov rax, 1
    mov rdi, r12
    mov rsi, space
    mov rdx, 1
    syscall

.next_number:
    inc r13
    jmp .write_loop

.close:
    mov rax, 3
    mov rdi, r12
    syscall
    xor rax, rax
    jmp .done

.error:
    mov rax, -1

.done:
    pop r14
    pop r13
    pop r12
    ret

filter_primes_ending_with_one:
    push r12
    push r13
    push r14
    push r15

    mov rax, 2
    mov rdi, input_filename
    xor rsi, rsi    ; O_RDONLY
    syscall
    cmp rax, 0
    jl .error
    mov r12, rax    ; fd входного файла

    ; открытие выходного файла для записи
    mov rax, 2
    mov rdi, output_filename
    mov rsi, 0x241  ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error
    mov r13, rax    ; fd выходного файла

.read_loop:
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .close
    mov r15, rax    

    mov r14, buffer 

.process_byte:
    dec r15
    js .read_loop

    mov al, [r14]
    inc r14

    
    cmp al, ' ' ; пропуск пробелов и переводов строк
    je .process_byte
    cmp al, 10
    je .process_byte
    test al, al
    jz .read_loop

    dec r14
    mov rsi, r14
    call parse_number
    test rax, rax
    jz .skip_number

    mov [current_number], rax

.skip_digits:
    mov al, [r14]
    cmp al, ' '
    je .check_number
    cmp al, 10
    je .check_number
    test al, al
    jz .check_number
    inc r14
    dec r15
    jns .skip_digits

.check_number:
    mov rdi, [current_number]
    call ends_with_one
    test rax, rax
    jz .process_byte

    mov rdi, [current_number]
    call number_to_string
    mov rsi, number_buffer
    call str_len
    mov rdx, rax

    mov rax, 1
    mov rdi, r13
    mov rsi, number_buffer
    syscall

    mov rax, 1
    mov rdi, r13
    mov rsi, space
    mov rdx, 1
    syscall

    jmp .process_byte

.skip_number:
    mov al, [r14]
    cmp al, ' '
    je .process_byte
    cmp al, 10
    je .process_byte
    test al, al
    jz .read_loop
    inc r14
    dec r15
    jns .skip_number
    jmp .read_loop

.close:
    mov rax, 3
    mov rdi, r12
    syscall
    mov rax, 3
    mov rdi, r13
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

is_prime: ; возвращает rax = 1 если простое, 0 если нет
    push rbx
    push rcx

    cmp rdi, 2
    jl .not_prime
    je .prime

    test rdi, 1
    jz .not_prime

    mov rbx, 3      
    mov rax, rdi
    xor rdx, rdx
    div rbx
    mov rcx, rax    ; верхняя граница для проверки

.check_loop:
    cmp rbx, rcx
    jg .prime

    mov rax, rdi
    xor rdx, rdx
    div rbx
    test rdx, rdx
    jz .not_prime

    add rbx, 2      ; проверка только нечетные
    jmp .check_loop

.prime:
    mov rax, 1
    jmp .done

.not_prime:
    xor rax, rax

.done:
    pop rcx
    pop rbx
    ret

ends_with_one: ; возвращает rax = 1 если оканчивается на 1, 0 если нет
    mov rax, rdi
    mov rbx, 10
    xor rdx, rdx
    div rbx
    cmp rdx, 1
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

number_to_string:
    push rbx
    push rcx
    push rdx

    lea rsi, [number_buffer + 31] ; конец буфера
    mov byte [rsi], 0
    mov rax, rdi
    mov rbx, 10

.convert_loop:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .convert_loop

    mov rdi, number_buffer
    mov rcx, 32
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .copy_loop

    pop rdx
    pop rcx
    pop rbx
    ret

str_len: ; Вычисляет длину строки
    push rcx
    mov rcx, rsi
    xor rax, rax
.loop:
    cmp byte [rcx + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    pop rcx
    ret


parse_number: ; возвращает rax - число, 0 если ошибка    Парсит число из строки
    push rbx
    push rcx

    xor rax, rax
    xor rcx, rcx

.loop:
    mov bl, byte [rsi + rcx]
    cmp bl, ' '
    je .done
    cmp bl, 0
    je .done
    cmp bl, 10
    je .done

    cmp bl, '0'
    jl .error
    cmp bl, '9'
    jg .error

    sub bl, '0'
    imul rax, 10
    add rax, rbx

    inc rcx
    jmp .loop

.done:
    jmp .exit

.error:
    xor rax, rax

.exit:
    pop rcx
    pop rbx
    ret

