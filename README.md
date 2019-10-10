Requirements
============
* windows
* msys2 - x86_64, with following packages
  * mingw-w64-i686-toolchain
  * mingw-w64-x86_64-toolchain
  * nasm
  * diffutils
* qemu
* vscode

TODO
====
1. write strings to video memory
2. write CRLF to video memory
3. scroll screen
4. higher half
5. paging
6. disk driver
7. use int 13h extended read
8. beyond ...


x86_64 address space
====================
```
11111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111
      FF       FF       FF       FF       FF       FF       FF       FF = 0xFFFFFFFFFFFFFFFF \
........ ........ ........ ........ ........ ........ ........ ........     ................  = 0x7FFFFFFFFFFF ~= 128 Tb \
      FF       FF       80       00       00       00       00       00 = 0xFFFF800000000000 /                            \
11111111 11111111 10000000 00000000 00000000 00000000 00000000 00000000                                                    \
                                                                                                                            \
-----------------------------------------------------------------------                                                      = 0xFFFFFFFFFFFE ~= 256 Tb
                                                                                                                            /
00000000 00000000 01111111 11111111 11111111 11111111 11111111 11111111                                                    /
      00       00       7F       FF       FF       FF       FF       FF = 0x00007FFFFFFFFFFF \                            /
........ ........ ........ ........ ........ ........ ........ ........     ................  = 0x7FFFFFFFFFFF ~= 128 Tb /
      00       00       00       00       00       00       00       00 = 0x0000000000000000 /
00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
```