S_SRCS:=bootsect.s stage2.s
C_SRCS:=kernel.c string.c vga.c term.c
S_OBJS:=$(S_SRCS:%.s=build/%.o)
C_OBJS:=$(C_SRCS:%.c=build/%.o)
S_TMPS:=$(S_OBJS:%.o=%.tmp)
S_BINS:=$(S_TMPS:%.tmp=%.bin)

build/bootsect_offset:=0x7c00
build/stage2_offset:=0x8000

.PRECIOUS: $(S_TMPS) $(S_OBJS) # keep the intermediate files for debugging

all: build/drive.vhd

vbox: build/drive.vhd
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium vbox\drive_vbox.vhd --delete
	cp build\drive.vhd vbox\drive_vbox.vhd
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium vbox\drive_vbox.vhd

clean-vbox:
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium vbox\drive_vbox.vhd --delete

build/drive.vhd: build/bootsect.bin build/stage2.bin build/kernel.bin build/empty.vhd
	cp build\empty.vhd build\drive.vhd
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\kernel_to_vhd.ps1", build\drive.vhd, build\kernel.bin -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'
	dd if=build/bootsect.bin of=build/drive.vhd bs=440 count=1 conv=notrunc
	dd if=build/stage2.bin of=build/drive.vhd seek=1 bs=512 conv=notrunc

build/empty.vhd:
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\create_vhd.ps1", build\empty.vhd -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'

build/kernel.bin: $(C_OBJS)
	x86_64-elf-gcc -g -Xlinker --nmagic -T kernel.ld -o $@ -ffreestanding -O0 -nostdlib -mno-red-zone -lgcc $^

build/%.bin: build/%.tmp
	x86_64-elf-objcopy -O binary -j .text $< $@

build/%.tmp: build/%.o
	x86_64-elf-ld -T NUL -Ttext=$($(basename $@)_offset) -o $@ $<

build/%.o: %.s
	x86_64-elf-as --divide -o $@ $<

build/%.o: %.c
	x86_64-elf-gcc -c $< -o $@ -g -ffreestanding -O0 -Wall -Wextra -mcmodel=large -mno-red-zone -mgeneral-regs-only

clean:
	rm -f build/drive.vhd build/empty.vhd build/kernel.bin $(S_BINS) $(S_TMPS) $(S_OBJS) $(C_OBJS)
