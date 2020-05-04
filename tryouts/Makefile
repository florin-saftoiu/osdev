print_offset:=0x7c00
readsec_offset:=0x7c00
params_offset:=0x7c00

.PRECIOUS: %.tmp %.o

%.bin: %.tmp
	objcopy -O binary -j .text $< $@

%.tmp: %.o
	ld -T NUL -Ttext=$($(basename $@)_offset) -o $@ $<

%.o: %.s
	as --divide -o $@ $<
