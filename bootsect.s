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
_start:
    cli
    xor     %ax, %ax
    mov     %ax, %ds                        # useful for call to _print
    mov     %ax, %es                        # useful for call to _readsec
    mov     $((stage2_start - 0x200) / 0x10), %ax
    mov     %ax, %ss                        # stack starts right after the boot sector
    mov     $0x1fe, %sp                     # stack length 512 bytes, will grow down from stage2_start
    sti
    mov     $msg_start, %si
    call    _print

    mov     $1, %ax                         # starting at sector 1
    mov     $2, %si                         # load 2 sector(s)
    mov     $stage2_start, %bx              # at stage2_start
    call    _readsec
    jnc     _stage2

    mov     $msg_error, %si                 # if error print message and hang
    call    _print
    jmp     _hang

_stage2:
    mov     $msg_ok, %si
    call    _print

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

# read from disk into buffer starting at a sector in LBA format
# input:  %ax - logical sector number of the start sector
#         %dl - drive number
#         %si - number of sectors to read
#         %es:%bx - buffer address
# output: data from logical sector in %ax at memory location %es:%bx
#         CF - set on error
_readsec:
    mov     $3, %di                         # retry counter
1:
    push    %bx
    mov     sec_per_track, %bh
    div     %bh
    mov     %ah, %cl
    inc     %cl                             # %cl = physical sector = LBA sector % sec_per_track + 1

    xor     %ah, %ah
    mov     num_heads, %bh
    div     %bh
    mov     %al, %ch                        # %ch = cylinder = LBA sector / (num_heads * sec_per_track) = (LBA sector / sec_per_track) / num_heads

    mov     %ah, %dh                        # %dh = head = (LBA sector / sec_per_track) % num_heads

    mov     %si, %ax                        # %al = number of sectors to read

    mov     $0x2, %ah
    pop     %bx                             # %es:%bx = destination buffer
    int     $0x13
    jnc     2f
    
    dec     %di
    jz      2f                              # if retry count is 0 give up
    
    mov     $0x0, %ah                       # if error, reset disk system and try again
    int     $0x13
    jnc     1b
2:
    ret

# data
msg_start:
    .asciz "Loading 2nd stage..."           # loading kernel
msg_ok:
    .asciz " OK."                           # loaded ok
msg_error:
    .asciz " failed."                       # error loading
sec_per_track:
    .byte 18
num_heads:
    .byte 2

# fill up the sector
.fill 510 - (. - _start), 1, 0

# boot identifier
.word 0xaa55
