S_SRCS:=bootsect.s stage2.s
C_SRCS:=kernel.c string.c vga.c term.c
S_OBJS:=$(S_SRCS:%.s=%.o)
C_OBJS:=$(C_SRCS:%.c=%.o)
S_TMPS:=$(S_OBJS:%.o=%.tmp)
S_BINS:=$(S_TMPS:%.tmp=%.bin)

bootsect_offset:=0x7c00
stage2_offset:=0x8000

.PRECIOUS: $(S_TMPS) $(S_OBJS) # keep the intermediate files for debugging

all: drive.vhd

vbox: drive.vhd
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive_vbox.vhd --delete
	cp drive.vhd drive_vbox.vhd
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium drive_vbox.vhd

clean-vbox:
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive_vbox.vhd --delete

drive.vhd: bootsect.bin stage2.bin kernel.bin empty.vhd
	cp empty.vhd drive.vhd
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\kernel_to_vhd.ps1", drive.vhd, kernel.bin -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'
	dd if=bootsect.bin of=drive.vhd bs=440 count=1 conv=notrunc
	dd if=stage2.bin of=drive.vhd seek=1 bs=512 conv=notrunc

empty.vhd:
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\create_vhd.ps1", empty.vhd -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'

kernel.bin: $(C_OBJS)
	x86_64-elf-gcc -g -Xlinker --nmagic -T kernel.ld -o $@ -ffreestanding -O0 -nostdlib -lgcc $^

%.bin: %.tmp
	x86_64-elf-objcopy -O binary -j .text $< $@

%.tmp: %.o
	x86_64-elf-ld -T NUL -Ttext=$($(basename $@)_offset) -o $@ $<

%.o: %.s
	x86_64-elf-as --divide -o $@ $<

%.o: %.c
	x86_64-elf-gcc -c $< -o $@ -g -ffreestanding -O0 -Wall -Wextra -mcmodel=large

clean:
	rm -f drive.vhd empty.vhd kernel.bin $(S_BINS) $(S_TMPS) $(S_OBJS) $(C_OBJS)
