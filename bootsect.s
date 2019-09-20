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
.set kernel_start, 0x8000
.set idt_start, 0x7400                      # IDT offset

_start:
    cli
    xor     %ax, %ax
    mov     %ax, %ds                        # useful for call to _print
    mov     %ax, %es                        # useful for call to _readsec
    mov     $((kernel_start - 0x200) / 0x10), %ax
    mov     %ax, %ss                        # stack starts right after the boot sector
    mov     $0x1fe, %sp                     # stack length 512 bytes, will grow down from kernel_start
    sti
    mov     $msg_start, %si
    call    _print

    mov     $1, %ax                         # starting at sector 1
    mov     $1, %si                         # load 1 sector(s)
    mov     $kernel_start, %bx              # at kernel_start
    call    _readsec
    jnc     _pm

    mov     $msg_error, %si                 # if error print message and hang
    call    _print
    jmp     _hang

_pm:
    mov     $msg_ok, %si
    call    _print
    cli

    call    _check_a20
    jne     1f
    mov     $msg_wraps, %si
    call    _print
    jmp     2f
1:
    mov     $msg_not_wraps, %si
    call    _print
    jmp     5f
2:
    in      $0x92, %al
    or      $0x2, %al
    out     %al, $0x92                      # enable A20 line

    call    _check_a20
    jne     4f
    mov     $msg_wraps, %si
    call    _print
    jmp     _hang
4:
    mov     $msg_not_wraps, %si
    call    _print
5:

    lgdt    gdt_desc

    mov     $idt_start, %di
    mov     $2048, %cx
    rep     stosb                           # setup empty IDT starting at 0x7400, right up to 0x7c00
    lidt    idt_desc

    mov     %cr0, %ax
    or      $1, %ax
    mov     %ax, %cr0                       # switch to protected mode
    ljmp    $0x8, $_start32                 # far jump into the code segment (offset 0x8 in the GDT) to reset %cs

.code32
_start32:
    mov     $0x10, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %fs
    mov     %ax, %gs
    mov     %ax, %ss                        # point all data segment registers to the data segment (offset 0x10 in the GDT)
    mov     $0x7fffc, %esp                  # stack will grow down from 0x80000, extended BIOS data area is mapped after that address
    
    movb    $'P', 0xb8000                   # write a P in the first cell of video memory
    movb    $0x1b, 0xb8001                  # with light cyan color on blue background

    mov     $kernel_start, %ax              # jump to kernel
    jmp     *%ax
_hang32:
    jmp     _hang32

.code16
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

# check if memory wraps, if it does than A20 is disabled, otherwise it is enabled
# write 0x00 at 0x0000:0x0500
# write 0xff at 0xffff:0x0510
# compare 0xff with value at 0x0000:0x0500
# if equal (ZF=1) than memory wraps else (ZF=0) memory does not wrap
# input: none
# ouput: ZF - set if memory wraps, clear if memory does not wrap
#        %ax, %es, %di, %ds, %si are left as they were before call
_check_a20:
    push    %es
    push    %ds
    xor     %ax, %ax
    mov     %ax, %es
    mov     $0x500, %di
    mov     %es:(%di), %al
    push    %ax
    movb    $0x00, %es:(%di)
    mov     $0xffff, %ax
    mov     %ax, %ds
    mov     $0x510, %si
    mov     %ds:(%si), %al
    push    %ax
    movb    $0xff, %ds:(%si)
    cmpb    $0xff, %es:(%di)
    pop     %ax
    mov     %al, %ds:(%si)
    pop     %ax
    mov     %al, %es:(%di)
    pop     %ds
    pop     %es
    ret

# data
msg_start:
    .asciz "Loading kernel ..."
msg_ok:
    .asciz " OK."
msg_error:
    .asciz " failed."
msg_wraps:
    .asciz "\r\nA20 line disabled."
msg_not_wraps:
    .asciz "\r\nA20 line enabled."
sec_per_track:
    .byte 18
num_heads:
    .byte 2

# global descriptor table
gdt_start:
gdt_null:                                   # null segment
    .quad 0 
gdt_code:                                   # code segment (selector (offset from gdt_start) = 0x8)
    .word 0xFFFF                            # limit 4Gb, bits 0..15
    .word 0                                 # base 0x0, bits 0..15
    .byte 0                                 # base 0x0, bits 16..23
    .byte 0b10011010                        # [ present flag = 1 | privilege level = 00 (OS) | type = 1 (code or data) | type = 1 (code) | conforming = 0 (non-conforming) | readable = 1 | access flag = 0 (set by cpu) ]
    .byte 0b11001111                        # [ granularity = 1 (multiply by 4k) | size = 1 (32bit) | intel reserved = 0 | ignored = 0 ] + limit 4Gb, bits 16..19
    .byte 0                                 # base 0x0, bits 24..31
gdt_data:                                   # data segment (selector (offset from gdt_start) = 0x10)
    .word 0xFFFF                            # limit 4Gb, bits 0..15
    .word 0                                 # base 0x0, bits 0..15
    .byte 0                                 # base 0x0, bits 16..23
    .byte 0b10010010                        # [ present flag = 1 | privilege level = 00 (OS) | type = 1 (code or data) | type = 0 (data) | expand = 0 (expand down) | writable = 1 | access flag = 0 (set by cpu) ]
    .byte 0b11001111                        # [ granularity = 1 (multiply by 4k) | big = 1 (allow 4Gb) | intel reserved = 0 | ignored = 0 ] + limit 4Gb, bits 16..19
    .byte 0                                 # base 0x0, bits 24..31
gdt_end:
gdt_desc:
    .word gdt_end - gdt_start - 1           # limit is (gdt_end - gdt_start - 1), size is (gdt_end - gdt_start), LGDT expects the limit, not the size
    .long gdt_start

# interrupt descriptor table descriptor
idt_desc:
    .word 2047                              # limit is 2047, size is 2048
    .long idt_start

# fill up the sector
.fill 510 - (. - _start), 1, 0

# boot identifier
.word 0xaa55
