; nasm -f win32 test.asm -o test.o
; ld.exe -o test.exe -LC:\msys64\mingw32\i686-w64-mingw32\lib test.o -lkernel32 -luser32

NULL          EQU 0                         ; constants
MB_DEFBUTTON1 EQU 0
MB_DEFBUTTON2 EQU 100h
IDNO          EQU 7
MB_YESNO      EQU 4

extern _MessageBoxA@16                      ; external functions in system libraries
extern _ExitProcess@4

global Start

section .rdata
    caption db '32-bit hello!', 0
    message db 'Hello World!', 0

section .text
Start:
    push    MB_YESNO | MB_DEFBUTTON2        ; UINT uType
    push    caption                         ; LPCSTR lpCaption
    push    message                         ; LPCSTR lpText
    push    NULL                            ; HWND hWnd = HWND_DESKTOP
    call    _MessageBoxA@16

    cmp     eax, IDNO
    je      Start

    push    eax                             ; UINT uExitCode = MessageBox(...)
    call    _ExitProcess@4
