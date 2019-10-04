// x86_64-elf-gcc -c krnl.c -o krnl.o -ffreestanding -O2 -Wall -Wextra
// x86_64-elf-ld -T NUL -Ttext=0x8a00 -o krnl.tmp krnl.o
// x86_64-elf-objcopy -O binary -j .text krnl.tmp krnl.bin
// dd if=krnl.bin of=drive.img seek=3 bs=512 conv=notrunc
#include <stdint.h>

enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15
};

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
	return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	return (uint16_t) uc | (uint16_t) color << 8;
}

void kmain(void) {
    uint16_t* buffer = (uint16_t*) 0xb8000;
    buffer[0] = vga_entry('C', vga_entry_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BROWN));

    while (1) {}
}