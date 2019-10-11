#include "string.h"

#include <stddef.h>

size_t strlen(const char* str) {
    size_t l = 0;
    while (str[l]) {
        l += 1;
    }
    return l;
}
