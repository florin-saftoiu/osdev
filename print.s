# print a null terminated string
# input:  %ds:%si - string address
# output: none
_print:
    lodsb
    or      %al, %al
    jz      1f
    mov     $0xe, %ah
    mov     $0x7, %bx
    int     $0x10
    jmp     _print
1:
    ret
