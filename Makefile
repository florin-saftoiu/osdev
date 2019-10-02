EMPTY:=
SPACE:=$(EMPTY) $(EMPTY)
COMMA:=, $(EMPTY)

SRCS:=bootsect.s stage2.s kernel.s krnl.c
OBJS:=$(patsubst %.c,%.o,$(SRCS:%.s=%.o))
TMPS:=$(OBJS:%.o=%.tmp)
BINS:=$(TMPS:%.tmp=%.bin)

bootsect_offset:=0x7c00
stage2_offset:=0x8000
kernel_offset:=0x8400
krnl_offset:=0x8400

.PRECIOUS: ${TMPS} ${OBJS} # keep the intermediate files for debugging

all: drive.vhd

drive.vhd: bootsect.bin stage2.bin kernel.bin
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive.vhd --delete
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\create_vhd.ps1", drive.vhd, kernel.bin -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'
	dd if=bootsect.bin of=drive.vhd seek=0 bs=512 conv=notrunc
	dd if=stage2.bin of=drive.vhd seek=1 bs=512 conv=notrunc
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium drive.vhd

drive_c.vhd: bootsect.bin stage2.bin krnl.bin
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive_c.vhd --delete
	powershell '$$ps = Start-Process -FilePath powershell -ArgumentList "$$(Get-Location)\create_vhd.ps1", drive_c.vhd, krnl.bin -Verb RunAs -PassThru; $$ps.WaitForExit(); exit $$ps.ExitCode'
	dd if=bootsect.bin of=drive_c.vhd seek=0 bs=512 conv=notrunc
	dd if=stage2.bin of=drive_c.vhd seek=1 bs=512 conv=notrunc
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium drive_c.vhd

%.bin: %.tmp
	objcopy -O binary -j .text $< $@

%.tmp: %.o
	ld -T NUL -Ttext=${${basename $@}_offset} -o $@ $<

%.o: %.s
	as -o $@ $<

%.o: %.c
	x86_64-elf-gcc -c $< -o $@ -ffreestanding -O2 -Wall -Wextra

clean:
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive.vhd --delete
	-powershell Remove-Item -ErrorAction Ignore drive.vhd, drive_c.vhd, $(subst $(SPACE),$(COMMA),$(BINS)), $(subst $(SPACE),$(COMMA),$(TMPS)), $(subst $(SPACE),$(COMMA),$(OBJS))
