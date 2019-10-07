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
1. kernel in non contiguous exfat clusters
2. load all segments of ELF64 kernel at the right place
3. use int 13h extended read
4. write strings to video memory
5. write CRLF to video memory
6. scroll screen
7. higher half
8. paging
9. disk driver
10. beyond ...
