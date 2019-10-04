# as kernel.s -o kernel.o
# ld -T NUL -Ttext=0x8a00 -o kernel.tmp kernel.o
# objcopy -O binary -j .text kernel.tmp kernel.bin
# dd if=kernel.bin of=drive.img seek=3 bs=512 conv=notrunc
.code64

_kstart:
    mov     $0xb8000, %rdi
    xor     %rax, %rax
    mov     $500, %rcx
    rep     stosq                           # clear screen by writing 0 in all 2000 cells of the video memory at 0xb8000
    mov     $0x2f592f412f4b2f4f, %rax
    mov     %rax, 0xb8000                   # write OKAY in white on light green background

_kend:
    jmp     _kend

# fill up more than 1 cluster
.fill 1200, 4, 0x6e72656b
