.code16

.set secs_per_track, 63
.set num_heads, 16

_0:
    ljmp     $0x0, $_start          # bios may load boot sector at 0x0:0x7c00 or at 0x7c0:0x0

_start:
    cli                             # make sure no interrupt messes with the stack
    
    xor     %ax, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %ss                # https://wiki.osdev.org/Memory_Map_(x86)
    mov     $0x7bfe, %sp            # stack grows down from the boot sector

    sti                             # interrupts can work again from here

    push    $msg                    # push param for call to print
    call    _print
    add     $2, %sp                 # cleanup stack after return from print

    push    $0x7e00                 # push buffer address for call to readsec
    push    $1                      # push number of sectors to read for call to readsec
    push    $1                      # push low byte of start sector for call to readsec
    push    $0                      # push high byte of start sector for call to readsec
    xor     %dh, %dh
    push    %dx                     # push drive number left by bios in %dl for call to readsec
    call    _readsec
    add     $10, %sp                # cleanup stack after call to print

    push    $0x7e00
    call    _print
    add     $2, %sp

_hang:
    jmp     _hang

# print a null terminated string
# input: string address
# output: none
# void _print(char* str)
_print:
    push    %bp                     # save caller's %bp
    mov     %sp, %bp                # use bp to point at the current stack top

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

# read sectors from a disk starting at a given sector (in LBA format) into a buffer
# input: drive - drive number
#        start - logical sector number of the start sector
#        nb - number of sectors to read
#        buffer - buffer address
# output: data from logical sector in start at memory location in buffer
# void _readsec(uint16_t drive, uint32_t start, uint16_t nb, void* buffer)
_readsec:
    push    %bp
    mov     %sp, %bp

    push    %bx                     # save %bx
    push    %di                     # save %di

    mov     8(%bp), %ax             # load low byte of start into %ax from parameter
    mov     6(%bp), %dx             # load high byte of start into %dx from parameter
    divw    secs_per_track
    mov     %dl, %cl
    inc     %cl                     # %cl = physical sector = LBA sector % sec_per_track + 1

    xor     %dx, %dx
    divw    num_heads
    mov     %al, %ch                # %ch = bits 0..7 of cylinder = LBA sector / (num_heads * sec_per_track) = (LBA sector / sec_per_track) / num_heads
    shl     $6, %ah
    add     %ah, %cl                # %cl = bits 8..9 of cylinder + physical sector

    mov     %dl, %dh                # %dh = head = (LBA sector / sec_per_track) % num_heads
    
    movb    4(%bp), %dl             # load drive number into %dl from parameter
    movb    10(%bp), %al            # load number of sectors to read into %al from paramter

    mov     12(%bp), %bx            # load address of buffer into %bx from parameter

    mov     $3, %di                 # retry counter
1:
    mov     $0x2, %ah               # read sectors function code for int 0x13
    int     $0x13                   # call int 0x13
    jnc     2f                      # all went well, return

    dec     %di
    jz      2f                      # if retry count is 0 give up

    mov     $0x0, %ah               # if error, reset disk system function code for int 0x13
    int     $0x13                   # call int 0x13
    jnc     1b                      # try again
2:

    pop     %di                     # restore %di
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

# more sectors
sector2:
    .asciz "sector 2"
    .fill 499 - (. - sector2), 1, 0
    .asciz "end sector 2"

sector3:
    .asciz "sector 3"
    .fill 499 - (. - sector3), 1, 0
    .asciz "end sector 3"

sector4:
    .asciz "sector 4"
    .fill 499 - (. - sector4), 1, 0
    .asciz "end sector 4"

sector5:
    .asciz "sector 5"
    .fill 499 - (. - sector5), 1, 0
    .asciz "end sector 5"

sector6:
    .asciz "sector 6"
    .fill 499 - (. - sector6), 1, 0
    .asciz "end sector 6"

sector7:
    .asciz "sector 7"
    .fill 499 - (. - sector7), 1, 0
    .asciz "end sector 7"

sector8:
    .asciz "sector 8"
    .fill 499 - (. - sector8), 1, 0
    .asciz "end sector 8"
