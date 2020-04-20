#include "term.h"

#include "vga.h"
#include "string.h"

#include <stddef.h>

size_t term_x;
size_t term_y;
vga_color term_color;

void term_init(void) {
    term_x = 0;
    term_y = 0;
    term_color = FG_WHITE | BG_BLACK;
    vga_clrscr();
}

void term_setcolor(vga_color color) {
    term_color = color;
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
        vga_putch(uc, term_color, term_x, term_y);
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

void term_write_number(int i) {
    if (i < 0) {
        term_putch('-');
        i = -i;
    }

    if (i / 10) {
        term_write_number(i / 10);
    }

    term_putch(i % 10 + '0');
}
