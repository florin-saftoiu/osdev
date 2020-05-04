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

    mov     %sp, %bp                # use %bp to point at the current stack top
    sub     $6, %sp                 # make room for 2 local variables, 1 uint16_t and 1 params (see _params)

    xor     %dh, %dh                # make sure high byte of %dx is 0, because we can't just push %dl
    mov     %dx, -2(%bp)            # save drive number left by bios in %dl in 1st local variable

    push    $msg                    # push param for call to print
    call    _print
    add     $2, %sp                 # cleanup stack after return from print

    lea     -6(%bp), %ax            # load address of buffer for params into %ax
    push    %ax                     # push address of buffer for return value
    push    -2(%bp)                 # push drive number from 1st local variable for call to readsec
    call    _params
    add     $4, %sp                 # cleanup stack after return from params

    test    %ah, %ah                # if params returned status 0 then
    jz      1f                      # print params

    push    $err                    # else, push error message as param for call to print
    call    _print
    add     $2, %sp                 # cleanup stack after return from print
    jmp     2f

1:
    lea     -6(%bp), %si

    mov     $0xe, %ah               # teletype output function code for int 0x10
    mov     $0x7, %bx               # output on page 0 (0 in %bh) with white on black (0 << 4 + 7 in %bl)

    mov     $'C, %al
    int     $0x10

    push    %ax
    push    (%si)
    call    _print_nb
    add     $2, %sp
    pop     %ax

    mov     $',, %al
    int     $0x10
    mov     $' , %al
    int     $0x10
    mov     $'H, %al
    int     $0x10
    
    push    %ax
    movzbw  2(%si), %ax
    push    %ax
    call    _print_nb
    add     $2, %sp
    pop     %ax

    mov     $',, %al
    int     $0x10
    mov     $' , %al
    int     $0x10
    mov     $'S, %al
    int     $0x10

    push    %ax
    movzbw  3(%si), %ax
    push    %ax
    call    _print_nb
    add     $2, %sp
    pop     %ax

    mov     $'\r, %al
    int     $0x10
    mov     $'\n, %al
    int     $0x10

2:

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

# print a number as decimal
# input: number
# output: none
# void _print(unit16_t nb)
_print_nb:
    push    %bp                     # save caller's %bp
    mov     %sp, %bp                # use %bp to point at the current stack top

    push    %bx                     # save %bx

    mov     4(%bp), %ax             # load number into %ax from parameter, right above caller's %bp and return address
    mov     $10, %cl
    div     %cl

    test    %al, %al                # if i / 10 == 0
    jz      1f                      # then print i % 10

    push    %ax                     # else _print_nb(i / 10)
    xor     %ah, %ah
    push    %ax
    call    _print_nb
    add     $2, %sp
    pop     %ax

1:
    mov     %ah, %al
    add     $'0, %al
    mov     $0xe, %ah               # teletype output function code for int 0x10
    mov     $0x7, %bx               # output on page 0 (0 in %bh) with white on black (0 << 4 + 7 in %bl)
    int     $0x10                   # call int 0x10

    pop     %bx                     # restore %bx

    mov     %bp, %sp                # restore %sp
    pop     %bp                     # restore caller's %bp
    ret

# read drive params
# input: drive - drive number
# output: return value - structure with status, number of cylinders, number of heads, number of sectors
# typedef struct {
#     uint16_t cylinders;
#     uint8_t heads;
#     uint8_t sectors;
# } params;
# uint16_t _params(uint16_t drive, params* params)
_params:
    push    %bp                     # save caller's %bp
    mov     %sp, %bp                # use %bp to point at the current stack top

    push    %di                     # save %di
    push    %bx                     # save %bx, because int 0x13, ah 0x8 trashes it

    mov     $0x8, %ah               # get drive parameters function code for int 0x13
    mov     4(%bp), %dl             # load drive number into %dl from parameter
    xor     %di, %di                # %es:%di should be 0x0:0x0 for call to int 0x13 get drive params
    int     $0x13                   # call int 0x13, status is put in %ax and returned as is

    mov     6(%bp), %bx             # load address of buffer from parameter
    mov     %ch, 1(%bx)             # put low bits of max cylinder into low bits of params->cylinders
    mov     %cl, (%bx)              # isolate high bits of max cylinder
    shrb    $6, (%bx)               # into high bits of params->cylinders
    incw    (%bx)                   # get number of cylinders into params->cylinders
    mov     %dh, 2(%bx)             # put max head into params->heads
    incb    2(%bx)                  # get number of heads into params->heads
    
    mov     %cl, 3(%bx)             # put max sector into params->sector
    andb    $0b00111111, 3(%bx)     # isolate max sector, same as number of sectors, since it starts at 1

    pop     %bx                     # restore %bx
    pop     %di                     # restore %di

    mov     %bp, %sp                # restore %sp
    pop     %bp                     # restore caller's %bp
    ret

# data
msg:
    .asciz "Hello, world !\r\n"
err:
    .asciz "Error\r\n"

# fill up the sector
    .fill 510 - (. - _0), 1, 0

# boot identifier
    .word 0xaa55
