#include <stdint.h>

#include "term.h"
#include "vga.h"

int stuff = 50;
int other;
const int more = 100;

const char* big_string = "You know when you write a really long and redundant sentence that just never seems to end because you keep on coming up with new ideas and you also forget to commas and stuff like that due to lack of motivation to write neatly for some strange reason that may stem from the fact that you are actually trying to make the sentence really long which then leads to an issue with your writing style as long boring sentences should be cut up into shorter sentences to keep the reader's attention or else the reader will stop reading and go see something that isn't as long boring and redundant because readers have short attention spans except for you because you are still reading this which is a very good practice to keep as it may or may not help in the future that may or may not end in december due to a possibly true prediction that the world will end but what do they know because they always wrote without spaces or any other way to make sure that stuff is neat which makes you wonder why they didn't invent stuff to space out letters because they seemed smart enough to think about it and they were most likely smarter than the rambler who is making this long and redundant yet interesting sentence about everything that you never need to know because you'll never see what I've been writing because by now you must have stopped reading this and if not you really need to because I plan on destroying your brain with mindless followups without an end which is possibly good or bad depending on whom you are so it may be good but you don't know but I know because I'm me and I'm awesome and I can write big sentences for you that will explain everything you may or may not need to know because it is here so I may continue rambling but I should stop but I won't stop because I see no reason to yet because there is so much to learn and explore in this universe with a single line of every topic in every dimension so lets continue pressing on reader who isn't reading anymore but you should read because this is an interesting long sentence that I've been writing for the past time but you don't know how long because I will not say but why I won't say is a secret to you because you haven't seen the rest of my work yet even though we need to get back on the topic which has been lost in the endless sea of letters spaces words and my rambling that will go on for the rest of time and so forth and on because this is a true work of art made by me and for the lone reader who is asleep because of this awesome text that you see before me that I wrote down in a matter of time and will soon be in your hands for all to read and see due to how long the text is because I am the king of rambling or maybe not as the doom predictors were probably better than I am but they are dead so I am better than them until they come back to life and try to kill me but I can fight them off somehow maybe by using a weapon or a word text but anyways you should still be reading my work so you don't die in a few months because this stuff will possibly save your life unless this somehow kills you but that would be funny because how it could happen is beyond me but it could be something possibly important but thats for the dying person to decide instead of you unless you are that guy in which case its ok because then you won't die because the people said so so yay or nay or whatever you want because you are dying unless you are not which is good because you are the only person reading this unless you fell asleep which isn't good because this is important life saving info that you will need to know someday unless you die in which case you wont need it but its always good o know how to ramble and this is great notes that you can use so that you can ramble without thinking about the fact that you are rambling so that in some awkward moment when you must ramble you will be prepared and ready to say whats on your mind because that is something very important to learn for the near or far future so I wish you a nice rambling season and some other random stuff so goodbye generic reader I love you!";

typedef struct idt_entry {
    uint16_t offset_15_0;
    uint16_t selector;
    uint8_t ist;
    uint8_t type_attr;
    uint16_t offset_31_16;
    uint32_t offset_63_32;
    uint32_t zero;
} idt_entry;

idt_entry* idt = (idt_entry*) 0xffff800000006400;

typedef struct interrupt_frame {
    uint64_t rip;
    uint64_t cs;
    uint64_t rflags;
    uint64_t rsp;
    uint64_t ss;
} interrupt_frame;

static inline uint8_t inb(uint16_t port) {
    uint8_t val;
    asm volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wreturn-type"
static inline uint64_t irq_disable(void) {
    uint64_t rflags;
    asm volatile ("pushfq\n\tcli\n\tpop %0" : "=r"(rflags) : : "memory");
}
#pragma GCC diagnostic pop

static inline void irq_restore(uint64_t rflags) {
    asm ("push %0\n\tpopfq" : : "rm"(rflags) : "memory", "cc");
}

static inline void irq_enable(void) {
    asm volatile ("sti");
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
__attribute__ ((interrupt)) void gpf_handler(interrupt_frame* frame, uint64_t error_code) {
    term_write("GPF");
    term_write_number(error_code);
    term_write("\n");
}

__attribute__ ((interrupt)) void interrupt_handler(interrupt_frame* frame) {
    term_write("INT\n");
}

__attribute__ ((interrupt)) void timer_handler(interrupt_frame* frame) {
    uint64_t rflags = irq_disable();
    outb(0x43, 0x0);
    uint8_t low = inb(0x40);
    uint8_t high = inb(0x40);
    uint16_t count = (high << 8) + low;
    char count_str[] = "     ";
    int i = 4;
    while (count / 10) {
        count_str[i] = (count % 10) + '0';
        count = count / 10;
        i--;
    }
    count_str[i] = (count % 10) + '0';
    vga_putstr("T=", VGA_COLOR_WHITE, VGA_COLOR_RED, 73, 24);
    vga_putstr(count_str, VGA_COLOR_WHITE, VGA_COLOR_RED, 75, 24);
    irq_restore(rflags);
    outb(0x20, 0x20);
}

__attribute__ ((interrupt)) void keyboard_handler(interrupt_frame* frame) {
    uint8_t code = inb(0x60);
    char code_str[] = "00";
    int i = 1;
    while (code / 16) {
        code_str[1] = (code % 16) + (code % 16 > 9 ? '7' : '0');
        code = code / 16;
        i--;
    }
    code_str[i] = (code % 16) + (code % 16 > 9 ? '7' : '0');
    vga_putstr("K=0x", VGA_COLOR_WHITE, VGA_COLOR_BLUE, 0, 24);
    vga_putstr(code_str, VGA_COLOR_WHITE, VGA_COLOR_BLUE, 4, 24);
    outb(0x20, 0x20);
}
#pragma GCC diagnostic pop

void kmain(void) {
    stuff++;
    other = 76;
    term_init();
    term_setcolors(VGA_COLOR_WHITE, VGA_COLOR_GREEN);
    term_write("OKAY");
    term_write((char*) &stuff);
    term_write((char*) &other);
    term_write((char*) &more);
    term_write(&big_string[4000]);
    term_write(" new\nline\n");
    term_write("3\n");
    term_write("4\n");
    term_write("5\n");
    term_write("6\n");
    term_write("7\n");
    term_write("8\n");
    term_write("9\n");
    term_write("10\n");
    term_write("11\n");
    term_write("12\n");
    term_write("13\n");
    term_write("14\n");
    term_write("15\n");
    term_write("16\n");
    term_write("17\n");
    term_write("18\n");
    term_write("19\n");
    term_write("20\n");
    term_write("21\n");
    term_write("22\n");
    term_write("23\n");
    term_write("24\n");
    term_write("25_scrolled 1 line");

    outb(0x20, 0x11);
    outb(0xA0, 0x11);
    outb(0x21, 0x20);
    outb(0xA1, 0x28);
    outb(0x21, 0x4);
    outb(0xA1, 0x2);
    outb(0x21, 0x1);
    outb(0xA1, 0x1);
    outb(0x21, 0x0);
    outb(0xA1, 0x0);

    uint64_t gpf_handler_address = (uint64_t) gpf_handler;
    idt[13].offset_15_0 = gpf_handler_address & 0xffff;
    idt[13].selector = 0x8;
    idt[13].ist = 0;
    idt[13].type_attr = 0x8e;
    idt[13].offset_31_16 = (gpf_handler_address & 0xffff0000) >> 16;
    idt[13].offset_63_32 = (gpf_handler_address & 0xffffffff00000000) >> 32;
    idt[13].zero = 0;

    uint64_t timer_handler_address = (uint64_t) timer_handler;
    idt[32].offset_15_0 = timer_handler_address & 0xffff;
    idt[32].selector = 0x8;
    idt[32].ist = 0;
    idt[32].type_attr = 0x8e;
    idt[32].offset_31_16 = (timer_handler_address & 0xffff0000) >> 16;
    idt[32].offset_63_32 = (timer_handler_address & 0xffffffff00000000) >> 32;
    idt[32].zero = 0;

    uint64_t keyboard_handler_address = (uint64_t) keyboard_handler;
    idt[33].offset_15_0 = keyboard_handler_address & 0xffff;
    idt[33].selector = 0x8;
    idt[33].ist = 0;
    idt[33].type_attr = 0x8e;
    idt[33].offset_31_16 = (keyboard_handler_address & 0xffff0000) >> 16;
    idt[33].offset_63_32 = (keyboard_handler_address & 0xffffffff00000000) >> 32;
    idt[33].zero = 0;

    irq_enable();

    int c = 0;
    while (1) {
        term_write("c = ");
        c++;
        term_write_number(c);
        term_write("\n");
    }
}
