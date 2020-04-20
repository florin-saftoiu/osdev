#ifndef TERM_H
#define TERM_H

#include "vga.h"

void term_init(void);
void term_setcolor(vga_color color);
void term_write(const char* str);
void term_write_number(int i);

#endif /* TERM_H */
