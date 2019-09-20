shell start /b qemu-system-x86_64.exe -s -S -drive file=drive.img,format=raw &
shell timeout 5
target remote :1234
display/i $cs*16+$pc
break *0x7c00
break *0x7c32
continue
