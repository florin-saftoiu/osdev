COMMA:=,
EMPTY:=
SPACE:=$(EMPTY) $(EMPTY)

SRCS:=bootsect.s stage2.s kernel.s
OBJS:=$(SRCS:%.s=%.o)
TMPS:=$(SRCS:%.s=%.tmp)
BINS:=$(SRCS:%.s=%.bin)

all: ${BINS} bootsect_to_img stage2_to_img kernel_to_img bootsect_to_vhd stage2_to_vhd kernel_to_vhd

init_img:
	dd if=/dev/zero of=drive.img bs=512 count=4

bootsect_to_img: init_img bootsect.bin
	dd if=bootsect.bin of=drive.img conv=notrunc

stage2_to_img: init_img stage2.bin
	dd if=stage2.bin of=drive.img seek=1 bs=512 conv=notrunc

kernel_to_img: init_img kernel.bin
	dd if=kernel.bin of=drive.img seek=3 bs=512 conv=notrunc

bootsect_to_vhd: bootsect.bin
	dd if=bootsect.bin of=drive.vhd conv=notrunc

stage2_to_vhd: stage2.bin
	dd if=stage2.bin of=drive.vhd seek=1 bs=512 conv=notrunc

kernel_to_vhd: kernel.bin
	dd if=kernel.bin of=drive.vhd seek=3 bs=512 conv=notrunc

%.bin: %.tmp
	objcopy -O binary -j .text $< $@

bootsect.tmp: bootsect.o
	ld -T NUL -Ttext=0x7c00 -o bootsect.tmp bootsect.o

bootsect.o: bootsect.s
	as bootsect.s -o bootsect.o

stage2.tmp: stage2.o
	ld -T NUL -Ttext=0x8000 -o stage2.tmp stage2.o

stage2.o: stage2.s
	as stage2.s -o stage2.o

kernel.tmp: kernel.o
	ld -T NUL -Ttext=0x8200 -o kernel.tmp kernel.o

kernel.o: kernel.s
	as kernel.s -o kernel.o

clean:
	powershell Remove-Item -ErrorAction Ignore drive.img
	powershell Remove-Item -ErrorAction Ignore $(subst $(SPACE),$(COMMA),$(BINS))
	powershell Remove-Item -ErrorAction Ignore $(subst $(SPACE),$(COMMA),$(TMPS))
	powershell Remove-Item -ErrorAction Ignore $(subst $(SPACE),$(COMMA),$(OBJS))
