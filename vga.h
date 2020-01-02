#ifndef VGA_H
#define VGA_H

#include <stddef.h>

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

extern const size_t VGA_WIDTH;
extern const size_t VGA_HEIGHT;

void vga_clrscr(void);
void vga_putch(unsigned char uc, enum vga_color fg, enum vga_color bg, size_t x, size_t y);
void vga_putstr(char* str, enum vga_color fg, enum vga_color bg, size_t x, size_t y);
void vga_scroll(void);

#endif /* VGA_H */
