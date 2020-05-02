    .code16

_0:
    ljmp     $0x0, $_start          # bios may load boot sector at 0x0:0x7c00 or at 0x7c0:0x0

_start:
    cli                             # make sure no interrupt messes with the stack
    
    xor     %ax, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %ss                # https://wiki.osdev.org/Memory_Map_(x86)
    mov     $0x7c00, %sp            # stack grows down from the boot sector

    sti                             # interrupts can work again from here

    push    $msg                    # push param for call to print
    call    _print
    add     $2, %sp                 # cleanup stack after return from print

_hang:
    jmp     _hang

# print a null terminated string
# input: string address
# output: none
# void _print(char* str)
_print:
    push    %bp                     # save caller's %bp
    mov     %sp, %bp                # use %bp to point at the current stack top

    push    %bx                     # save %bx
    push    %si                     # save %si

    mov     $0xe, %ah               # teletype output function code for int 0x10
    mov     $0x7, %bx               # output on page 0 (0 in %bh) with white on black (0 << 4 + 7 in %bl)

    mov     4(%bp), %si             # load string address into %si from parameter, right above caller's %bp and return address
1:                                  # loop through the string at %ds:%si
    lodsb                           # loading each byte into %al
    or      %al, %al                # if current byte is null
    jz      2f                      # exit loop
    int     $0x10                   # call int 0x10
    jmp     1b                      # loop around
2:

    pop     %si                     # restore %si
    pop     %bx                     # restore %bx

    mov     %bp, %sp                # restore %sp
    pop     %bp                     # restore caller's %bp
    ret

# data
msg:
    .asciz "Hello, world !"

# fill up the sector
    .fill 510 - (. - _0), 1, 0

# boot identifier
    .word 0xaa55
