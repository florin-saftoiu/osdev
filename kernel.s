# as kernel.s -o kernel.o
# ld -T NUL -Ttext=0x8000 -o kernel.tmp kernel.o
# objcopy -O binary -j .text kernel.tmp kernel.bin
# dd if=kernel.bin of=drive.img seek=1 bs=512
.code64

_kstart:
    movb    $'K', 0xb8000                   # write a K in the first cell of video memory
    movb    $0x6a, 0xb8001                  # with light green color on brown background

_kend:
    jmp     _kend
