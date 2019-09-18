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
# dd if=bootsect.bin of=drive.img
.code16

_start:
    xor     %ax, %ax
    mov     %ax, %ds                        # useful for call to _print
    mov     %ax, %es                        # useful for call to _readsec
    mov     $0x7e00, %ax
    mov     %ax, %ss                        # stack starts right after the boot sector
    mov     $0x200, %sp                     # stack length 512 bytes
    mov     $msg_start, %si
    call    _print

    mov     $1, %ax                         # starting at sector 1
    mov     $1, %si                         # load 1 sector(s)
    mov     $0x8000, %bx                    # at 0x8000
    call    _readsec
    jnc     _kernel_loaded

    mov     $msg_error, %si                 # if error print message and hang
    call    _print
    jmp     _hang

_kernel_loaded:
                                            # TODO - enter protected mode

    mov     $0x8000, %ax                    # jump to kernel
    jmp     *%ax

_hang:
    jmp     _hang

.include "print.s"

# read from disk into buffer starting at a sector in LBA format
# input:  %ax - logical sector number of the start sector
#         %dl - drive number
#         %si - number of sectors to read
#         %es:%bx - buffer address
# output: data from logical sector in %ax at memory location %es:%bx
#         CF - set on error
#         %ax, %dl, %si, %es, %bx are left as they were before call
_readsec:
    push    %ax
    push    %dx
    mov     $3, %di                         # retry counter
1:
    push    %bx
    mov     (sec_per_track), %bh
    div     %bh
    mov     %ah, %cl
    inc     %cl                             # %cl = physical sector = LBA sector % sec_per_track + 1

    xor     %ah, %ah
    mov     (num_heads), %bh
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
    pop     %dx
    pop     %ax
    ret

msg_start:
    .asciz "Loading kernel ...\r\n"
msg_error:
    .asciz "Failed to load kernel.\r\n"
sec_per_track:
    .word 18
num_heads:
    .word 2

.fill 510 - (. - _start), 1, 0
.word 0xaa55
