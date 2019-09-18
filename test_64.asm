; nasm -f win32 test.asm -o test.o
; ld -o test_64.exe -L"C:\Program Files\mingw-w64\x86_64-8.1.0-posix-seh-rt_v6-rev0\mingw64\x86_64-w64-mingw32\lib" test_64.o -lkernel32 -luser32
; MAKE SURE LD IS 64-bit !!!

NULL          EQU 0                         ; constants
MB_DEFBUTTON1 EQU 0
MB_DEFBUTTON2 EQU 100h
IDNO          EQU 7
MB_YESNO      EQU 4

extern MessageBoxA                          ; external functions in system libraries
extern ExitProcess

global Start

section .data
    caption db '64-bit hello!', 0
    message db 'Hello World!', 0

section .text
Start:
    sub     rsp, 8                          ; aligns stack to multiple of 16 bytes
    sub     rsp, 32                         ; 32 bytes of shadow space

.DisplayMessageBox:
    mov     rcx, NULL                       ; HWND hWnd = HWND_DESKTOP
    lea     rdx, [REL message]              ; LPCSTR lpText
    lea     r8, [REL caption]               ; LPCSTR lpCaption
    mov     r9d, MB_YESNO | MB_DEFBUTTON2   ; UINT uType
    call    MessageBoxA

    cmp     rax, IDNO
    je      .DisplayMessageBox

    add     rsp, 32                         ; remove shadow space

    mov     rcx, rax                        ; UINT uExitCode = MessageBox(...)
    call    ExitProcess
