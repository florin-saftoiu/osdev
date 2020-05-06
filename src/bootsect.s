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
    .set stage2_start, 0x8000

_0:
    ljmp    $0x0, $_start

_start:
    cli
    xor     %ax, %ax
    mov     %ax, %ds                        # useful for call to _print
    mov     %ax, %es                        # useful for call to int 0x13 for params and _readsec
    mov     $((stage2_start - 0x200) / 0x10), %ax
    mov     %ax, %ss                        # stack starts right after the boot sector
    mov     $0x200, %sp                     # stack length 512 bytes, will grow down from stage2_start
    sti
    mov     $msg_start, %si
    call    _print

    xor     %dh, %dh
    push    %dx                             # save drive number left by BIOS in %dl
    mov     $0x8, %ah
    xor     %di, %di
    int     $0x13
    inc     %dh                             # maximum head number = %dh, number of heads = %dh + 1
    mov     %dh, %dl
    xor     %dh, %dh
    mov     %dx, num_heads
    and     $0b00111111, %cl                # remove bits 8..9 of maximum cylinder number
    xor     %ch, %ch
    mov     %cx, secs_per_track             # maximum sector number = number of sectors per track = bits 0..5 of %cl
    pop     %dx                             # restore drive number left by BIOS in %dl into %dx
    push    %dx                             # save drive number left by BIOS in %dl

    mov     $3, %ch                         # load 3 sector(s)
    mov     %dl, %cl                        # from drive left by BIOS in %dl
    xor     %dx, %dx
    mov     $1, %ax                         # starting at sector 1 (%dx:%ax)
    mov     $stage2_start, %bx              # at stage2_start (%es:%bx)
    call    _readsec
    jnc     _read_pt

    mov     $msg_error, %si                 # if error print message and hang
    call    _print
    jmp     _hang

_read_pt:
    mov     $msg_ok, %si
    call    _print

    mov     $pt, %di
    mov     $4, %cx
1:
    movb    (%di), %al
    test    $0x80, %al
    jnz     _stage2
    add     $16, %di
    loop    1b
    mov     $msg_pt_error, %si              # no active partition found
    call    _print
    jmp     _hang

_stage2:
    pop     %cx                             # restore drive number left by BIOS in %dl into %cx
    movw    8(%di), %ax
    movw    10(%di), %dx                    # %dx:%ax = starting sector of active partition in LBA format

    mov     $stage2_start, %bx
    jmp     *%bx

_hang:
    jmp     _hang

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

# read %ch sectors from disk %cl starting at sector %dx:%ax (in LBA format)
# into buffer starting at %es:%bx
# input:  %ch - number of sectors to read
#         %cl - drive number
#         %dx:%ax - logical sector number of the start sector
#         %es:%bx - buffer address
# output: data from logical sector in %ds:%ax at memory location %es:%bx
#         CF - set on error
_readsec:

    push    %cx                             # put number of sectors to read and drive number on stack
    mov     %sp, %bp                        # save a stack pointer in %bp

    push    %bx                             # put buffer offset on stack
    push    %ax                             # save low bytes of start sector
    mov     %dx, %ax                        # load high bytes of start sector into %ax
    xor     %dx, %dx
    divw    secs_per_track
    mov     %ax, %bx                        # save high bytes of quotient in %bx
    pop     %ax                             # restore low bytes of start sector into %ax
    divw    secs_per_track
    mov     %dl, %cl
    inc     %cl                             # %cl = physical sector = LBA sector % sec_per_track + 1

    mov     %bx, %dx                        # load saved high bytes of quotient
    divw    num_heads
    mov     %al, %ch                        # %ch = bits 0..7 of cylinder = LBA sector / (num_heads * sec_per_track) = (LBA sector / sec_per_track) / num_heads
    shl     $6, %ah
    or      %ah, %cl                        # %cl = bits 8..9 of cylinder + physical sector

    mov     %dl, %dh                        # %dh = head = (LBA sector / sec_per_track) % num_heads
    
    pop     %bx                             # restore buffer offset into %bx
    movb    (%bp), %dl                      # %dl = drive number
    movb    1(%bp), %al                     # %al = number of sectors to read

    mov     $3, %di                         # retry counter
1:
    mov     $0x2, %ah
    int     $0x13
    jnc     2f                              # all went well, return

    dec     %di
    jz      2f                              # if retry count is 0 give up
    
    mov     $0x0, %ah                       # if error, reset disk system and try again
    int     $0x13
    jnc     1b
2:
    pop     %cx
    ret

# data
msg_start:
    .asciz "Loading 2nd stage..."
msg_ok:
    .asciz " OK."
msg_error:
    .asciz " failed."
msg_pt_error:
    .asciz "\r\nError reading partition table."
secs_per_track:
    .word 63
num_heads:
    .word 16

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
