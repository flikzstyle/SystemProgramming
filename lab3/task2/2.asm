format ELF64
public _start

section '.data'
    newline db 10

section '.bss' writable
    buf db 0
    a dq 0
    b dq 0

section '.text' executable
_start:
    pop rax             
    cmp rax, 3         
    jl exit
    
    pop rax          
    
    pop rdi
    call atoi
    mov [a], rax
    
    pop rdi
    call atoi
    mov [b], rax
    
    ; ((((b*b)+a)-b)*b)*b
    
    ; b * b
    mov rax, [b]
    mov rbx, [b]
    mul rbx             ; rax = b * b
    
    ; (b*b) + a
    add rax, [a]        ; rax = (b*b) + a
    
    ; ((b*b)+a) - b
    sub rax, [b]        ; rax = ((b*b)+a) - b
    
    ; (((b*b)+a)-b) * b
    mov rbx, [b]
    mul rbx             ; rax = (((b*b)+a)-b) * b
    
    ; ((((b*b)+a)-b)*b) * b
    mov rbx, [b]
    mul rbx             ; rax = ((((b*b)+a)-b)*b) * b
    
    call print_number
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    call exit

; Процедура преобразования строки в число
atoi:
    xor rax, rax        
    xor rcx, rcx        
    
.convert_loop:
    mov bl, [rdi + rcx] 
    test bl, bl         
    jz .done
    
    sub bl, '0'        
    imul rax, 10       
    add rax, rbx       
    
    inc rcx             
    jmp .convert_loop

.done:
    ret

print_number:
    mov rbx, 10        
    xor rcx, rcx       
    
.divide:
    xor rdx, rdx        
    div rbx            
    push rdx            
    inc rcx             
    test rax, rax       
    jnz .divide         
    
.print:
    pop rax             
    add al, '0'         
    mov [buf], al      
    
    push rcx            
    mov rax, 1          
    mov rdi, 1         
    mov rsi, buf        
    mov rdx, 1          
    syscall
    pop rcx             
    
    loop .print         ; уменьшает rcx и прыгает если не ноль
    
    ret

exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код 0
    syscall

