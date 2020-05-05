# as bootsect.s -o bootsect.o
# ld -T NUL -Ttext=0x7c00 -o bootsect.tmp bootsect.o
# objcopy -O binary -j .text bootsect.tmp bootsect.bin
# qemu-system-x86_64.exe -drive file=bootsect.bin,format=raw
# qemu-system-x86_64.exe -s -S -drive file=bootsect.bin,format=raw
# gdb
# target remote :1234
# display/i $cs*16+$pc
# break *0x7c00
# continue
# dd if=/dev/zero of=drive.img bs=512 count=2
# dd if=bootsect.bin of=drive.img conv=notrunc
    .code16

    .set stage2_offset, 0x8000

_0:
    ljmp    $0x0, $_start

_start:
    cli

    xor     %ax, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     $((stage2_offset - 0x200) / 0x10), %ax
    mov     %ax, %ss                        # stack starts right after the boot sector
    mov     $0x200, %sp                     # stack length 512 bytes, will grow down from stage2_start

    sti

    mov     %sp, %bp                        # use %bp to point at the current stack top
    sub     $6, %sp                         # make room for 2 local variables, 1 uint16_t and 1 params (see _params)

    xor     %dh, %dh                        # make sure high byte of %dx is 0, because we can't just push %dl
    mov     %dx, -2(%bp)                    # save drive number left by bios in %dl in 1st local variable

    push    $msg_start
    call    _print
    add     $2, %sp

    lea     -6(%bp), %ax                    # load address of buffer for params into %ax
    push    %ax                             # push address of buffer for return value
    push    -2(%bp)                         # push drive number from 1st local variable for call to readsec
    call    _params
    add     $4, %sp                         # cleanup stack after return from params

    test    %ah, %ah                        # if params returned status 0 then
    jz      _load_stage2                    # load stage2

    push    $msg_error                      # else, push error message as param for call to print
    call    _print
    add     $2, %sp                         # cleanup stack after return from print
    jmp     _hang

_load_stage2:
    push    $stage2_offset                  # load stage2 at stage2_offset
    push    $3                              # read 3 sectors
    push    $1                              # low bytes of starting sector 1
    push    $0                              # high bytes of starting sector 1
    lea     -6(%bp), %ax                    # load address of params into %ax
    push    %ax                             # push address of params
    push    -2(%bp)                         # push drive number from 1st local variable
    call    _readsec
    add     $12, %sp                        # cleanup stack after return from readsec

    test    %ah, %ah                        # if readsec returned status 0 then
    jz      _read_pt                        # read partition table

    push    $msg_error                      # else, push error message as param for call to print
    call    _print
    add     $2, %sp                         # cleanup stack after return from print
    jmp     _hang

_read_pt:
    push    $msg_ok
    call    _print
    add     $2, %sp

    mov     $pt, %di
    mov     $4, %cx
1:
    movb    (%di), %al
    test    $0x80, %al                      # if active partition found, then
    jnz     _stage2                         # call stage2
    add     $16, %di
    loop    1b

    push    $msg_pt_error                   # no active partition found
    call    _print
    add     $2, %sp
    jmp     _hang

_stage2:
    mov     -2(%bp), %cx                    # drive number into %cx
    movw    8(%di), %ax
    movw    10(%di), %dx                    # %dx:%ax = starting sector of active partition in LBA format

    mov     $stage2_offset, %bx
    jmp     *%bx

_hang:
    jmp     _hang

# print a null terminated string
# input: string address
# output: none
# void _print(char* str)
_print:
    push    %bp                             # save caller's %bp
    mov     %sp, %bp                        # use %bp to point at the current stack top

    push    %bx                             # save %bx
    push    %si                             # save %si

    mov     $0xe, %ah                       # teletype output function code for int 0x10
    mov     $0x7, %bx                       # output on page 0 (0 in %bh) with white on black (0 << 4 + 7 in %bl)

    mov     4(%bp), %si                     # load string address into %si from parameter, right above caller's %bp and return address
1:                                          # loop through the string at %ds:%si
    lodsb                                   # loading each byte into %al
    or      %al, %al                        # if current byte is null
    jz      2f                              # exit loop
    int     $0x10                           # call int 0x10
    jmp     1b                              # loop around
2:

    pop     %si                             # restore %si
    pop     %bx                             # restore %bx

    mov     %bp, %sp                        # restore %sp
    pop     %bp                             # restore caller's %bp
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
    push    %bp                             # save caller's %bp
    mov     %sp, %bp                        # use %bp to point at the current stack top

    push    %di                             # save %di
    push    %bx                             # save %bx, because int 0x13, ah 0x8 trashes it

    mov     $0x8, %ah                       # get drive parameters function code for int 0x13
    mov     4(%bp), %dl                     # load drive number into %dl from parameter
    xor     %di, %di                        # %es:%di should be 0x0:0x0 for call to int 0x13 get drive params
    int     $0x13                           # call int 0x13, status is put in %ax and returned as is

    mov     6(%bp), %bx                     # load address of buffer from parameter
    mov     %ch, %ss:(%bx)                  # put low bits of max cylinder into low bits of params->cylinders
    mov     %cl, %ss:1(%bx)                 # isolate high bits of max cylinder
    shrb    $6, %ss:1(%bx)                  # into high bits of params->cylinders
    incw    %ss:(%bx)                       # get number of cylinders into params->cylinders
    mov     %dh, %ss:2(%bx)                 # put max head into params->heads
    incb    %ss:2(%bx)                      # get number of heads into params->heads
    
    mov     %cl, %ss:3(%bx)                 # put max sector into params->sector
    andb    $0b00111111, %ss:3(%bx)         # isolate max sector, same as number of sectors, since it starts at 1

    pop     %bx                             # restore %bx
    pop     %di                             # restore %di

    mov     %bp, %sp                        # restore %sp
    pop     %bp                             # restore caller's %bp
    ret

# read sectors from a disk starting at a given sector (in LBA format) into a buffer
# input: drive - drive number
#        params - drive params
#        start - logical sector number of the start sector
#        nb - number of sectors to read
#        buffer - buffer address
# output: data from logical sector in start at memory location in buffer
#         high byte of return value - status, 0 if no error
#         low byte of return value - number of sectors actually read
# uint16_t _readsec(uint16_t drive, params* params, uint32_t start, uint16_t nb, void* buffer)
_readsec:
    push    %bp                             # save caller's %bp
    mov     %sp, %bp                        # use %bp to point at the current stack top

    sub     $6, %sp                         # make room for 3 local variable

    push    %bx                             # save %bx
    push    %di                             # save %di

    mov     6(%bp), %bx                     # load address of params from parameter
    movzbw  %ss:2(%bx), %ax                 # zero-expand params->heads into %ax
    mov     %cx, -2(%bp)                    # move zero-expanded params->heads into -2(%bp)
    movzbw  %ss:3(%bx), %ax                 # zero-expand params->sectors into %ax
    mov     %cx, -4(%bp)                    # move zero-expanded params->sectors into -4(%bp)
    xor     %dx, %dx
    mov     8(%bp), %ax                     # load high bytes of start into %ax from parameter
    divw    -4(%bp)                         # divide by params->sectors
    mov     %ax, -6(%bp)                    # save high bytes of quotient in 3rd local variable
    mov     10(%bp), %ax                    # load low bytes of start into %ax from parameter
    divw    -4(%bp)                         # divide by params->sectors
    mov     %dl, %cl                        # %cl = LBA sector % secs_per_track
    inc     %cl                             # %cl = physical sector = LBA sector % secs_per_track + 1

    mov     -6(%bp), %dx                    # load saved high bytes of quotient from 3rd local variable
    divw    -2(%bp)                         # divide by params->heads
    mov     %al, %ch                        # %ch = bits 0..7 of cylinder = LBA sector / (num_heads * secs_per_track) = (LBA sector / secs_per_track) / num_heads
    shl     $6, %ah
    or      %ah, %cl                        # %cl = bits 8..9 of cylinder | physical sector

    mov     %dl, %dh                        # %dh = head = (LBA sector / secs_per_track) % num_heads
    
    movb    4(%bp), %dl                     # load drive number into %dl from parameter
    movb    12(%bp), %al                    # load number of sectors to read into %al from paramter

    mov     14(%bp), %bx                    # load address of buffer into %bx from parameter

    mov     $3, %di                         # retry counter
1:
    mov     $0x2, %ah                       # read sectors function code for int 0x13
    int     $0x13                           # call int 0x13
    jnc     2f                              # all went well, return status 0 in %ah and nb of sectors in %al

    dec     %di
    jz      2f                              # if retry count is 0 give up, return status != 0 in %ah and nb of sectors in %al

    mov     $0x0, %ah                       # if error, reset disk system function code for int 0x13
    int     $0x13                           # call int 0x13
    jnc     1b                              # try again
2:

    pop     %di                             # restore %di
    pop     %bx                             # restore %bx

    mov     %bp, %sp                        # restore %sp
    pop     %bp                             # restore caller's %bp
    ret

# data
msg_start:
    .asciz "OSDEV\r\nLoading 2nd stage..."
msg_ok:
    .asciz " OK."
msg_error:
    .asciz " failed."
msg_pt_error:
    .asciz "\r\nError reading partition table."

# fill up the sector
    .fill 440 - (. - _0), 1, 0

unique_disk_id:
    .long 0xf41aa958
reserved:
    .word 0x0

# partition table
pt:
    .byte 0x80                              # active
    .byte 0x2                               # starting head
    .byte 0x3                               # starting cylinder, bits 8..9 + starting sector
    .byte 0x0                               # starting cylinder, bits 0..7
    .byte 0x7                               # type = exFAT
    .byte 0xe5                              # ending head
    .byte 0x25                              # ending cylinder, bits 8..9 + ending sector
    .byte 0x0                               # ending cylinder, bits 0..7
    .long 0x80                              # relative sector, starting LBA
    .long 0x3800                            # total sectors in partition
    .fill 16, 1, 0                          # partition 2
    .fill 16, 1, 0                          # partition 3
    .fill 16, 1, 0                          # partition 4

# boot identifier
    .word 0xaa55
