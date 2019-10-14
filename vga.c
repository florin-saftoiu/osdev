#include "vga.h"

#include "string.h"

#include <stdint.h>
#include <stddef.h>

const size_t VGA_WIDTH = 80;
const size_t VGA_HEIGHT = 25;

uint16_t* vga_buffer = (uint16_t*) 0xffff8000000b8000;

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
	return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
	return (uint16_t) uc | (uint16_t) color << 8;
}

void vga_clrscr(void) {
    for (size_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = 0;
    }
}

void vga_putch(unsigned char uc, enum vga_color fg, enum vga_color bg, size_t x, size_t y) {
    vga_buffer[y * VGA_WIDTH + x] = vga_entry(uc, vga_entry_color(fg, bg));
}

void vga_scroll(void) {
    memmove(vga_buffer, vga_buffer + VGA_WIDTH, VGA_WIDTH * VGA_HEIGHT);
    memset(vga_buffer + (VGA_WIDTH * (VGA_HEIGHT - 1)), 0, VGA_WIDTH);
}
