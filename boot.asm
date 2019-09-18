; nasm -f bin boot.asm -o boot.bin
; qemu-system-x86_64.exe -drive file=boot.bin,format=raw
org 7c00h

Start:
    xor     ax, ax
    mov     ds, ax
    mov	    si, msg_start
Print:	
	lodsb
	or      al, al
	jz      End
	mov     ah, 0eh
	mov     bx, 07h
	int     10h
	jmp     Print
End:
    jmp     End

msg_start db 'booted', 0

%if $ - Start > 510
    %error "Binary would be larger than 512 bytes !"
%endif

times (510 - ($ - Start)) db 0
db 55h, 0aah
