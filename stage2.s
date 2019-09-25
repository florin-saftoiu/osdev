# as stage2.s -o stage2.o
# ld -T NUL -Ttext=0x8000 -o stage2.tmp stage2.o
# objcopy -O binary -j .text stage2.tmp stage2.bin
# dd if=stage2.bin of=drive.img seek=1 bs=512 conv=notrunc
.code16
.set pml4t_start, 0x2000                    # paging tables, aligned to 4096 bytes
.set pdpt_start, 0x3000
.set pdt_start, 0x4000
.set pt_start, 0x5000
.set idt64_start, 0x6400
.set idt_start, 0x7400
.set stage2_start, 0x8000
.set kernel_start, 0x8400
_start:
    mov     $msg_start, %si
    call    _print

    mov     $3, %ax
    mov     $1, %si
    mov     $kernel_start, %bx
    call    _readsec
    jnc     _pm

    mov     $msg_error, %si
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

    mov     %cr0, %eax
    or      $1, %ax
    mov     %eax, %cr0                      # switch to protected mode
    ljmp    $0x8, $_start32                 # far jump into the code segment (offset 0x8 in the GDT) to reset %cs

.code32
_start32:
    mov     $0x10, %ax
    mov     %ax, %es                        # we need %es for all the stos instructions, but we have no need for %ds, %fs, %gs
    mov     %ax, %ss                        # point all data segment registers to the data segment (offset 0x10 in the GDT)
    mov     $(stage2_start - 4), %esp       # stack will grow down from stage2_start, same as in real mode
    
    movl    $pml4t_start, %edi
    mov     %edi, %cr3                      # point %cr3 to pml4t
    xor     %eax, %eax
    mov     $4096, %ecx
    rep     stosl                           # clear pml4t + pdpt + pdt + pt (stosl writes 4 bytes at a time, so all 4 tables get cleared)

    mov     %cr3, %edi                      # restore %edi from %cr3, since it was modified by stosl
    movl    $(pdpt_start + 3), (%edi)       # pml4t[0] -> pdpt[0] + set bits for page is present and writable
    add     $0x1000, %edi
    movl    $(pdt_start + 3), (%edi)        # pdpt[0] -> pdt[0] + set bits for page is present and writable
    add     $0x1000, %edi
    movl    $(pt_start + 3), (%edi)         # pdt[0] -> pt[0] + set bits for page is present and writable
    add     $0x1000, %edi
    mov     $0x3, %ebx
    mov     $512, %ecx
1:
    mov     %ebx, (%edi)                    # pt[i] -> 0x0 + (0x1000 * i) + set bits for page is present and writable
    add     $0x1000, %ebx
    add     $8, %edi
    loop    1b

    mov     %cr4, %eax
    or      $(1 << 5), %eax
    mov     %eax, %cr4                      # enable PAE

    mov     $0xc0000080, %ecx
    rdmsr
    or      $(1 << 8), %eax
    wrmsr                                   # set long mode bit

    mov     %cr0, %eax
    or      $(1 << 31), %eax
    mov     %eax, %cr0                      # enable paging and get into long mode - compatibility submode

    lgdt    gdt64_desc
    ljmp    $0x8, $_start64                 # far jump into the code segment (offset 0x8 in the GDT64) to reset %cs and get into long mode - 64bit submode

.code64
_start64:
    mov     $idt64_start, %rdi
    mov     $4096, %rcx
    rep     stosb                           # setup empty IDT starting at 0x6400, right up to 0x7400
    lidt    idt64_desc

    mov     $(stage2_start - 4), %rsp       # stack will grow down from stage2_start, same as in real and protected mode

    mov     $kernel_start, %rax
    jmp     *%rax

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
    .asciz "\r\nLoading kernel..."          # loading kernel
msg_ok:
    .asciz " OK."                           # loaded ok
msg_error:
    .asciz " failed."                       # error loading
msg_wraps:
    .asciz "\r\nA20 line disabled."         # A20 line is disabled
msg_not_wraps:
    .asciz "\r\nA20 line enabled."          # A20 line is enabled
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
    .byte 0b10011010                        # [ present flag = 1 | privilege level = 00 (OS) | type = 1 (code or data) | type = 1 (executable) | conforming = 0 (non-conforming) | readable = 1 | access flag = 0 (set by cpu) ]
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

# global descriptor table 64bit
gdt64_start:
gdt64_null:                                 # null segment
    .quad 0
gdt64_code:                                 # code segment (selector (offset from gdt_start) = 0x8)
    .word 0                                 # limit 4Gb, bits 0..15
    .word 0                                 # base 0x0, bits 0..15
    .byte 0                                 # base 0x0, bits 16..23
    .byte 0b10011010                        # [ present flag = 1 | privilege level = 00 (OS) | type = 1 (code or data) | type = 1 (executable) | conforming = 0 (non-conforming) | readable = 1 | access flag = 0 (set by cpu) ]
    .byte 0b10101111                        # [ granularity = 1 (multiply by 4k) | size = 0 (64bit) | 64bit code descriptor = 1 | ignored = 0 ] + limit 4Gb, bits 16..19
    .byte 0                                 # base 0x0, bits 24..31
gdt64_data:                                 # data segment (selector (offset from gdt_start) = 0x10)
    .word 0                                 # limit 4Gb, bits 0..15
    .word 0                                 # base 0x0, bits 0..15
    .byte 0                                 # base 0x0, bits 16..23
    .byte 0b10010010                        # [ present flag = 1 | privilege level = 00 (OS) | type = 1 (code or data) | type = 0 (data) | expand = 0 (expand down) | writable = 1 | access flag = 0 (set by cpu) ]
    .byte 0b00000000                        # [ granularity = 0 (multiply by 1) | ignored = 0 | intel reserved = 0 | ignored = 0 ] + limit 4Gb, bits 16..19
    .byte 0                                 # base 0x0, bits 24..31
gdt64_end:
gdt64_desc:
    .word gdt64_end - gdt64_start - 1       # limit is (gdt_end - gdt_start - 1), size is (gdt_end - gdt_start), LGDT expects the limit, not the size
    .quad gdt64_start

# interrupt descriptor table descriptor
idt_desc:
    .word 2047                              # limit is 2047, size is 2048
    .long idt_start

# interrupt descriptor table descriptor 64bit
idt64_desc:
    .word 4095                              # limit is 4095, size is 4096
    .quad idt64_start
