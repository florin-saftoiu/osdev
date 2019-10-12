#ifndef STRING_H
#define STRING_H

#include <stddef.h>

size_t strlen(const char* str);
void* memmove(void* to, const void* from, size_t size);
void* memset(void* block, int c, size_t size);

#endif /* STRING_H */
