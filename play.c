#include <stdio.h>

struct st {
    int i;
    char ch;
    double d;
} __attribute__((packed));

int main() {
    printf("Play again !\n");
    char* s = "StringPlay";
    printf("%s\n", s + 6);
    struct st a;
    a.i = 10;
    a.ch = 'g';
    printf("Size of a is %ld\n", sizeof(a));
    printf("a.i = %i\n", a.i);
    printf("a.ch = %c\n", a.ch);
    return 0;
}