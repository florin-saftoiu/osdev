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
    if (uc == '\n') {
        term_x = 0;
        if (term_y == VGA_HEIGHT - 1) {
            vga_scroll();
        } else {
            term_y++;
        }
    } else {
        vga_putch(uc, term_fg, term_bg, term_x, term_y);
        term_x++;
        if (term_x == VGA_WIDTH) {
            term_x = 0;
            if (term_y == VGA_HEIGHT - 1) {
                vga_scroll();
            } else {
                term_y++;
            }
        }
    }
}

void term_write(const char* str) {
    size_t len = strlen(str);
    for (size_t i = 0; i < len; i++) {
        term_putch(str[i]);
    }
}
