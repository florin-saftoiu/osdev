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

all: drive.img

drive_c.vhd: drive_c.img
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive_c.vhd --delete
	VBoxManage convertfromraw drive_c.img drive_c.vhd --format vhd --variant fixed
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium drive_c.vhd

drive.vhd: drive.img
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive.vhd --delete
	VBoxManage convertfromraw drive.img drive.vhd --format vhd --variant fixed
	VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium drive.vhd

drive_c.img: bootsect.bin stage2.bin krnl.bin
	dd if=/dev/zero of=drive_c.img bs=512 count=4
	dd if=bootsect.bin of=drive_c.img seek=0 bs=512 conv=notrunc
	dd if=stage2.bin of=drive_c.img seek=1 bs=512 conv=notrunc
	dd if=krnl.bin of=drive_c.img seek=3 bs=512 conv=notrunc

drive.img: bootsect.bin stage2.bin kernel.bin
	dd if=/dev/zero of=drive.img bs=512 count=4
	dd if=bootsect.bin of=drive.img seek=0 bs=512 conv=notrunc
	dd if=stage2.bin of=drive.img seek=1 bs=512 conv=notrunc
	dd if=kernel.bin of=drive.img seek=3 bs=512 conv=notrunc

%.bin: %.tmp
	objcopy -O binary -j .text $< $@

%.tmp: %.o
	ld -T NUL -Ttext=${${basename $@}_offset} -o $@ $<

%.o: %.s
	as -o $@ $<

%.o: %.c
	x86_64-elf-gcc -c $< -o $@ -ffreestanding -O2 -Wall -Wextra

clean:
	-powershell Remove-Item -ErrorAction Ignore drive_c.img, drive.img, $(subst $(SPACE),$(COMMA),$(BINS)), $(subst $(SPACE),$(COMMA),$(TMPS)), $(subst $(SPACE),$(COMMA),$(OBJS))
	-VBoxManage storageattach bootsect --storagectl IDE --port 0 --device 0 --type hdd --medium none
	-VBoxManage closemedium drive_c.vhd --delete
	-VBoxManage closemedium drive.vhd --delete
