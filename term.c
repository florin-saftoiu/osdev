#include "term.h"

#include "vga.h"
#include "string.h"

#include <stddef.h>

size_t term_x;
size_t term_y;
enum vga_color term_fg;
enum vga_color term_bg;

void term_init(void) {
    term_x = 0;
    term_y = 0;
    term_fg = VGA_COLOR_WHITE;
    term_bg = VGA_COLOR_BLACK;
    vga_clrscr();
}

void term_setcolors(enum vga_color fg, enum vga_color bg) {
    term_fg = fg;
    term_bg = bg;
}

static void term_putch(unsigned char uc) {
    vga_putch(uc, term_fg, term_bg, term_x, term_y);
    term_x += 1;
    if (term_x == VGA_WIDTH) {
        term_y += 1;
        term_x = 0;
    }
}

void term_write(const char* str) {
    size_t len = strlen(str);
    for (size_t i = 0; i < len; i +=1) {
        term_putch(str[i]);
    }
}
