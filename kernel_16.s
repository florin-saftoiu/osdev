# as kernel_16.s -o kernel_16.o
# ld -T NUL -Ttext=0x8000 -o kernel_16.tmp kernel_16.o
# objcopy -O binary -j .text kernel_16.tmp kernel_16.bin
# dd if=kernel_16.bin of=drive.img seek=1 bs=512
.code16

_kstart:
    mov     $k_msg_start, %si
    call    _print

_kend:
    jmp     _kend

.include "print.s"

k_msg_start:
    .asciz "Kernel started ...\r\n"
