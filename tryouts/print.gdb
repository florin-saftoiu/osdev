# display ax, bx, cx, dx, si, di, sp and bp
define regs
    printf "ax 0x%04x (%d), bx 0x%04x (%d), cx 0x%04x (%d), dx 0x%04x (%d)\n", $ax, $ax, $bx, $bx, $cx, $cx, $dx, $dx
    printf "si 0x%04x (%d), di 0x%04x (%d), sp 0x%04x (%d), bp 0x%04x (%d)\n", $si, $si, $di, $di, $sp, $sp, $bp, $bp
end

# gets executed every time gdb stops
define hook-stop
    regs
end

# gets executed when you quit gdb
define hook-quit
    set confirm off
    kill inferiors 1
end

set pagination off

set remotetimeout 20
shell start qemu-system-i386w.exe -s -S -drive file=print.bin,format=raw
target remote :1234

# force gdb to treat this as 16-bit real mode
set tdesc filename gdb-xml_i386-16bit.xml

# display base on every stop
display/8hx $ss*16+$bp

# display stack on every stop
display/8hx $ss*16+$sp

# display next 2 instructions on every stop
display/2i $cs*16+$pc

until *0x7c00
