format ELF
public _start
msg db "Yakushev", 0xA, "Pavel", 0xA, "Alekseevich", 0xA, 0

_start:
    mov rax, 4
    mov rbx, 1
    mov rcx, msg
    mov rdx, 28
    int 0x80

    mov rax, 1
    mov rbx, 0
    int 0x80
