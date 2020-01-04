#ifndef TERM_H
#define TERM_H

#include "vga.h"

void term_init(void);
void term_setcolors(enum vga_color fg, enum vga_color bg);
void term_write(const char* str);
void term_write_number(int i);

#endif /* TERM_H */
