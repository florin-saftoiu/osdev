# as boot.s -o boot_gas.o
# ld -T NUL -Ttext=0x7c00 -o boot_gas.tmp boot_gas.o
# objcopy -O binary -j .text boot_gas.tmp boot_gas.bin
# qemu-system-x86_64.exe -drive file=boot_gas.bin,format=raw
# qemu-system-x86_64.exe -s -S -drive file=boot_gas.bin,format=raw
# gdb
# target remote localhost:1234
# break *0x7c00
# continue
.code16

Start:
    xor     %ax, %ax
    mov     %ax, %ds
    mov     $msg_start, %si
Print:
    lodsb
    or      %al, %al
    jz      End
    mov     $0xe, %ah
    mov     $0x7, %bx
    int     $0x10
    jmp     Print
End:
    jmp     End

msg_start:
    .asciz "booted_gas"

.fill 510 - (. - Start), 1, 0
.word 0xaa55
