#include <stdint.h>

#include "vga.h"

int stuff = 50;
int other;
const int more = 100;

void kmain(void) {
    stuff++;
    other = 76;
    vga_clear_screen();
    uint16_t* buffer = (uint16_t*) 0xb8000;
    buffer[0] = vga_entry('O', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_GREEN));
    buffer[1] = vga_entry('K', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_GREEN));
    buffer[2] = vga_entry('A', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_GREEN));
    buffer[3] = vga_entry('Y', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_GREEN));

    while (1) {}
}
