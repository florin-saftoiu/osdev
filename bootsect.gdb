shell start /b qemu-system-x86_64.exe -s -S -drive file=drive.vhd,format=vpc &
shell timeout 5
target remote :1234
display/i $cs*16+$pc
#display/i $pc
break *0x7c00
break *0x8000
break *0x8400
continue
