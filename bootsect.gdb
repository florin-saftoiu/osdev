# gets executed when you quit gdb
define hook-quit
    set confirm off
    kill inferiors 1
end

set pagination off

set remotetimeout 20
shell start qemu-system-x86_64w.exe -s -S -drive file=build/drive.vhd,format=vpc
target remote :1234

symbol-file build/kernel.bin

# display next 2 instructions on every stop
display/2i $pc

break kmain
continue
