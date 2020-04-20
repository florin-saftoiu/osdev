#ifndef VGA_H
#define VGA_H

#include <stddef.h>

typedef enum {
    FG_BLACK         = 0x00,
    FG_BLUE          = 0x01,
    FG_GREEN         = 0x02,
    FG_CYAN          = 0x03,
    FG_RED           = 0x04,
    FG_MAGENTA       = 0x05,
    FG_BROWN         = 0x06,
    FG_LIGHT_GREY    = 0x07,
    FG_DARK_GREY     = 0x08,
    FG_LIGHT_BLUE    = 0x09,
    FG_LIGHT_GREEN   = 0x0A,
    FG_LIGHT_CYAN    = 0x0B,
    FG_LIGHT_RED     = 0x0C,
    FG_LIGHT_MAGENTA = 0x0D,
    FG_LIGHT_BROWN   = 0x0E,
    FG_WHITE         = 0x0F,
    BG_BLACK         = 0x00,
    BG_BLUE          = 0x10,
    BG_GREEN         = 0x20,
    BG_CYAN          = 0x30,
    BG_RED           = 0x40,
    BG_MAGENTA       = 0x50,
    BG_BROWN         = 0x60,
    BG_LIGHT_GREY    = 0x70,
    BG_DARK_GREY     = 0x80,
    BG_LIGHT_BLUE    = 0x90,
    BG_LIGHT_GREEN   = 0xA0,
    BG_LIGHT_CYAN    = 0xB0,
    BG_LIGHT_RED     = 0xC0,
    BG_LIGHT_MAGENTA = 0xD0,
    BG_LIGHT_BROWN   = 0xE0,
    BG_WHITE         = 0xF0
} vga_color;

extern const size_t VGA_WIDTH;
extern const size_t VGA_HEIGHT;

void vga_clrscr(void);
void vga_putch(unsigned char uc, vga_color color, size_t x, size_t y);
void vga_putstr(char* str, vga_color color, size_t x, size_t y);
void vga_scroll(void);

#endif /* VGA_H */
