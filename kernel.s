# as kernel.s -o kernel.o
# ld -T NUL -Ttext=0x8000 -o kernel.tmp kernel.o
# objcopy -O binary -j .text kernel.tmp kernel.bin
# dd if=kernel.bin of=drive.img seek=1 bs=512
.code16

_kstart:
    mov     $k_msg_start, %si
    call    _print

_kend:
    jmp     _kend

.include "print.s"

k_msg_start:
    .asciz "Kernel started ...\r\n"
