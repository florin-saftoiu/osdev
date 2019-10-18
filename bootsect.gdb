define hook-quit
    set confirm off
    kill inferiors 1
end
set remotetimeout 20
#shell start /b qemu-system-x86_64.exe -s -S -drive file=drive.vhd,format=vpc &
#target remote :1234
target remote | qemu-system-x86_64.exe -S -gdb stdio -drive file=drive.vhd,format=vpc
#file kernel.bin
#display/i $cs*16+$pc
display/i $pc
#break *0x7c00
#break *0x8000
break *0x838d
#break *0xffff8000001000a2
continue
