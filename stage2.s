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
.set exfat_start, 0x8600
.set fat_region_start, 0x8800
.set root_directory_start, 0x8a00
.set kernel_start, 0x8a00
_start:
    push    %cx                             # 4(%bp) = drive number passed by bootsect in %cx
    push    %dx                             # 2(%bp) = high byte of starting sector of active partition passed by bootsect in %dx:%ax
    push    %ax                             # (%bp) = low byte of starting sector of active partition passed by bootsect in %dx:%ax
    mov     %sp, %bp
    push    $exfat_start                    # -2(%bp) = current memory offset
    sub     $10, %sp                        # -6(%bp):-4(%bp) = current cluster
                                            # -8(%bp) = index of current cluster in the current fat region sector
                                            # -10(%bp) = kernel length in sectors
                                            # -12(%bp) = kernel general secondary flags

    mov     $0x8, %ah
    mov     4(%bp), %dl                     # put drive number into %dl
    xor     %di, %di
    int     $0x13
    inc     %dh                             # maximum head number = %dh, number of heads = %dh + 1
    mov     %dh, %dl
    xor     %dh, %dh
    mov     %dx, num_heads
    and     $0b00111111, %cl                # remove bits 8..9 of maximum cylinder number
    xor     %ch, %ch
    mov     %cx, secs_per_track             # maximum sector number = number of sectors per track = bits 0..5 of %cl

    mov     $msg_start, %si
    call    _print

    mov     $1, %ch                         # load 1 sector(s)
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     2(%bp), %dx
    mov     (%bp), %ax                      # starting at starting sector of active partition passed by bootsect
    mov     -2(%bp), %bx                    # at current memory offset (%es:%bx)
    call    _readsec
    jnc     _exfat

    mov     $msg_error, %si
    call    _print
    jmp     _hang

_exfat:
    addw    $0x200, -2(%bp)                 # increment current memory offset by 1 sector

_fat_region:
    addw    $0x200, -2(%bp)                 # increment current memory offset by 1 sector
    
    mov     (exfat_start + 96), %ax
    mov     (exfat_start + 98), %dx         # %dx:%ax = first cluster of root directory
1:
    mov     %ax, -6(%bp)
    mov     %dx, -4(%bp)                    # current cluster = %dx:%ax

    clc
    sbb     $2, %ax
    sbb     $0, %dx                         # %dx:%ax = index of current cluster of root directory inside cluster heap

    movzbw  (exfat_start + 109), %cx        # do index * 2 ^ sectors_per_cluster_shift by shifting sectors_per_cluster_shift times
2:
    shl     %dx                             # shift high word
    shl     %ax                             # shift low word
    jnc     3f                              # if CF = 0 go to next shift
    or      $1, %dx                         # else put CF into the least significant bit of high word
3:
    loop    2b                              # %dx:%ax = current cluster of root directory offset in sectors

    clc
    adc     (exfat_start + 64), %ax
    adc     (exfat_start + 66), %dx         # %dx:%ax = current cluster of root directory offset in sectors + partition offset in sectors

    clc
    adc     (exfat_start + 88), %ax
    adc     (exfat_start + 90), %dx         # %dx:%ax = current cluster of root directory offset in sectors + partition offset in sectors + cluster heap offset in sectors

    mov     $1, %ch
    mov     (exfat_start + 109), %cl
    shl     %cl, %ch                        # %ch = 2 ^ sectors_per_cluster_shift, number of sectors per cluster
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     -2(%bp), %bx                    # at current memory offset (%es:%bx)
    call    _readsec
    jnc     4f

    mov     $msg_error, %si
    call    _print
    jmp     _hang

4:
    mov     $1, %ax
    mov     (exfat_start + 109), %cl
    shl     %cl, %ax                        # %ax = 2 ^ sectors_per_cluster_shift, number of sectors per cluster
    shl     $9, %ax                         # multiply %ax by 2^9 (512)
    add     %ax, -2(%bp)                    # increment current memory offset by 2 ^ sectors_per_cluster_shift, number of sectors per cluster sector(s)

    mov     -6(%bp), %ax
    mov     -4(%bp), %dx
    mov     $128, %bx
    div     %bx
    mov     %dx, -8(%bp)
    xor     %dx, %dx                        # %dx:%ax = sector of the fat region that has the current cluster, -8(%bp) = index of current cluster in that sector

    clc
    adc     (exfat_start + 80), %ax
    adc     (exfat_start + 82), %dx         # %dx:%ax = fat region offset in sectors + fat offset in sectors

    clc
    adc     (exfat_start + 64), %ax
    adc     (exfat_start + 66), %dx         # %dx:%ax = fat region offset in sectors + fat offset in sectors + partition offset in sectors

    mov     $1, %ch                         # load 1 sector
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     $fat_region_start, %bx          # at fat_region_start (%es:%bx)
    call    _readsec
    jnc     5f

    mov     $msg_error, %si
    call    _print
    jmp     _hang

5:
    mov     -8(%bp), %di
    shl     $2, %di                         # multiply index in %di by 4 to get the offset
    mov     (%bx, %di), %ax
    mov     2(%bx, %di), %dx
    cmp     $0xffff, %ax
    jne     1b
    cmp     $0xffff, %dx
    jne     1b

_root_directory:
    mov     $root_directory_start, %bx
    xor     %di, %di
1:
    mov     (%bx, %di), %al                 # read 1st byte of directory entry
    add     $32, %di                        # advance to next entry
    cmp     $0, %al                         # if 1st byte is 0 than error
    jne     2f

    mov     $msg_error, %si
    call    _print
    jmp     _hang

2:
    cmp     $0x85, %al                      # if 1st byte is 0x85 it's a file directory entry
    jne     1b                              # else read next entry

    push    %di                             # save pointer to next directory entry
    
    mov     $20, %cx
    add     $34, %di
    add     $root_directory_start, %di
    mov     $kernel_filename, %si           # compare filename to 'kernel.bin'
3:
    cmpsb
    jne     5f                              # if different restore pointer to next entry and advance to it
    loop    3b
    
    pop     %di                             # it's the kernel
    
    mov     8(%bx, %di), %ax
    mov     10(%bx, %di), %dx               # put it's data length in bytes in %dx:%ax
    mov     $512, %cx
    div     %cx
    cmp     $0, %dx
    je      4f
    inc     %ax
4:
    mov     %ax, -10(%bp)                   # put it's data length in sectors in -10(%bp)

    movzbw  1(%bx, %di), %ax                # put it's general secondary flags in %ax
    mov     %ax, -12(%bp)                   # put it's general secondary flags in -12(%bp)

    mov     20(%bx, %di), %ax
    mov     22(%bx, %di), %dx               # put it's cluster number in %dx:%ax
    jmp     _kernel

5:
    pop     %di
    jmp     1b

_kernel:
    movw    $kernel_start, -2(%bp)          # set current memory offset to kernel_start
1:
    mov     %ax, -6(%bp)
    mov     %dx, -4(%bp)                    # current cluster = %dx:%ax

    clc
    sbb     $2, %ax
    sbb     $0, %dx                         # %dx:%ax = index of current cluster of kernel inside cluster heap

    movzbw  (exfat_start + 109), %cx        # do index * 2 ^ sectors_per_cluster_shift by shifting sectors_per_cluster_shift times
2:
    shl     %dx                             # shift high word
    shl     %ax                             # shift low word
    jnc     3f                              # if CF = 0 go to next shift
    or      $1, %dx                         # else put CF into the least significant bit of high word
3:
    loop    2b                              # %dx:%ax = current cluster of kernel offset in sectors

    clc
    adc     (exfat_start + 64), %ax
    adc     (exfat_start + 66), %dx         # %dx:%ax = current cluster of kernel offset in sectors + partition offset in sectors

    clc
    adc     (exfat_start + 88), %ax
    adc     (exfat_start + 90), %dx         # %dx:%ax = current cluster of kernel offset in sectors + partition offset in sectors + cluster heap offset in sectors

    testw   $2, -12(%bp)                    # test NoFatChain bit
    jz      4f                              # if not set than it's a cluster chain, else read full kernel length in one shot

    mov     -10(%bp), %ch                   # load full kernel length
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     -2(%bp), %bx                    # at current memory offset (%es:%bx)
    call    _readsec
    jnc     _pm                             # consider that the kernel is in continous sectors

    mov     $msg_error, %si
    call    _print
    jmp     _hang

4:
    mov     $1, %ch
    mov     (exfat_start + 109), %cl
    shl     %cl, %ch                        # %ch = 2 ^ sectors_per_cluster_shift, number of sectors per cluster 
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     -2(%bp), %bx                    # at current memory offset (%es:%bx)
    call    _readsec
    jnc     5f

    mov     $msg_error, %si
    call    _print
    jmp     _hang

5:
    mov     $1, %ax
    mov     (exfat_start + 109), %cl
    shl     %cl, %ax                        # %ax = 2 ^ sectors_per_cluster_shift, number of sectors per cluster
    shl     $9, %ax                         # multiply %ax by 2^9 (512)
    add     %ax, -2(%bp)                    # increment current memory offset by 2 ^ sectors_per_cluster_shift, number of sectors per cluster sector(s)

    mov     -6(%bp), %ax
    mov     -4(%bp), %dx
    mov     $128, %bx
    div     %bx
    mov     %dx, -8(%bp)
    xor     %dx, %dx                        # %dx:%ax = sector of the fat region that has the current cluster, -8(%bp) = index of current cluster in that sector

    clc
    adc     (exfat_start + 80), %ax
    adc     (exfat_start + 82), %dx         # %dx:%ax = fat region offset in sectors + fat offset in sectors

    clc
    adc     (exfat_start + 64), %ax
    adc     (exfat_start + 66), %dx         # %dx:%ax = fat region offset in sectors + fat offset in sectors + partition offset in sectors

    mov     $1, %ch                         # load 1 sector
    mov     4(%bp), %cl                     # from drive left by bootsect
    mov     $fat_region_start, %bx          # at fat_region_start (%es:%bx)
    call    _readsec
    jnc     6f

    mov     $msg_error, %si
    call    _print
    jmp     _hang
                        
6:
    mov     -8(%bp), %di
    shl     $2, %di                         # multiply index in %di by 4 to get the offset
    mov     (%bx, %di), %ax
    mov     2(%bx, %di), %dx
    cmp     $0xffff, %ax
    jne     1b
    cmp     $0xffff, %dx
    jne     1b

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
    loop    1b                              # this identity maps the first 2 Mb of virtual space to the first 2Mb of physical space

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

    # move kernel 0x100000 = 1Mb
    mov     $kernel_start, %rbx
    add     (kernel_start + 32), %rbx       # program header offset
    movzwq  (kernel_start + 56), %rcx       # number of entries in program header
1:
    mov     (%rbx), %eax                    # move p_type into %eax
    cmp     $1, %eax                        # if p_type = 1 then it's a LOAD segment
    jne     2f                              # else move to next segment
    push    %rcx

    mov     16(%rbx), %rdi                  # p_vaddr in %rdi
    mov     40(%rbx), %rcx                  # p_memsz in %rcx
    rep     stosb                           # clear p_memsz bytes at p_vaddr

    mov     $kernel_start, %rsi
    xor     %rax, %rax
    mov     8(%rbx), %eax
    add     %rax, %rsi                      # kernel_offset + p_offset in %rsi
    mov     16(%rbx), %rdi                  # p_vaddr in %rdi
    mov     32(%rbx), %rcx                  # p_filesz in %rcx
    rep     movsb                           # copy p_filesz bytes from kernel_offset + p_offset to p_vaddr
    
    pop     %rcx
2:
    add     $56, %rbx                       # move to next segment
    loop    1b
    
    mov     (kernel_start + 24), %rax       # program entry address
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

# read %ch sectors from disk %cl starting at sector %dx:%ax (in LBA format)
# into buffer starting at %es:%bx
# input:  %ch - number of sectors to read
#         %cl - drive number
#         %dx:%ax - logical sector number of the start sector
#         %es:%bx - buffer address
# output: data from logical sector in %ds:%ax at memory location %es:%bx
#         CF - set on error
_readsec:
    push    %bp
    mov     $3, %di                         # retry counter
    push    %cx                             # put number of sectors to read and drive number on stack
    mov     %sp, %bp                        # save a stack pointer in %bp
1:
    divw    secs_per_track
    mov     %dl, %cl
    inc     %cl                             # %cl = physical sector = LBA sector % sec_per_track + 1

    xor     %dx, %dx
    divw    num_heads
    mov     %al, %ch                        # %ch = bits 0..7 of cylinder = LBA sector / (num_heads * sec_per_track) = (LBA sector / sec_per_track) / num_heads
    shl     $6, %ah
    add     %ah, %cl                        # %cl = bits 8..9 of cylinder + physical sector

    mov     %dl, %dh                        # %dh = head = (LBA sector / sec_per_track) % num_heads
    
    movb    (%bp), %dl                      # %dl = drive number
    movb    1(%bp), %al                     # %al = number of sectors to read

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
    pop     %bp
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
secs_per_track:
    .word 63
num_heads:
    .word 16
kernel_filename:
    .asciz "k\000e\000r\000n\000e\000l\000.\000b\000i\000n\000"

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
