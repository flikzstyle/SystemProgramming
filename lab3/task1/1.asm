format ELF64
public _start

section '.bss' writable
    buf db 0            
    newline db 10       

section '.text' executable
_start:
    pop rax             
    cmp rax, 2          
    jl exit            
    
    pop rdi             
    pop rdi             
    
    movzx rax, byte [rdi] 
    call print_number    
    
    mov rax, 1         
    mov rdi, 1          
    mov rsi, newline    
    mov rdx, 1         
    syscall
    
    call exit           

print_number:
    mov rcx, 10         
    mov rbx, 0          
    
    .divide_loop:
        xor rdx, rdx    
        div rcx         
        push rdx        
        inc rbx         
        test rax, rax   
        jnz .divide_loop 
    
    .print_loop:
        pop rax         
        add al, '0'     
        mov [buf], al   
        
        push rbx        
        mov rax, 1      
        mov rdi, 1      
        mov rsi, buf    
        mov rdx, 1      
        syscall
        pop rbx         
        
        dec rbx         
        jnz .print_loop 
    
    ret                 ;


exit:
    mov rax, 60         
    xor rdi, rdi        
    syscall