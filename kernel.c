#include <stdint.h>

#include "term.h"

int stuff = 50;
int other;
const int more = 100;

const char* big_string = "You know when you write a really long and redundant sentence that just never seems to end because you keep on coming up with new ideas and you also forget to commas and stuff like that due to lack of motivation to write neatly for some strange reason that may stem from the fact that you are actually trying to make the sentence really long which then leads to an issue with your writing style as long boring sentences should be cut up into shorter sentences to keep the reader's attention or else the reader will stop reading and go see something that isn't as long boring and redundant because readers have short attention spans except for you because you are still reading this which is a very good practice to keep as it may or may not help in the future that may or may not end in december due to a possibly true prediction that the world will end but what do they know because they always wrote without spaces or any other way to make sure that stuff is neat which makes you wonder why they didn't invent stuff to space out letters because they seemed smart enough to think about it and they were most likely smarter than the rambler who is making this long and redundant yet interesting sentence about everything that you never need to know because you'll never see what I've been writing because by now you must have stopped reading this and if not you really need to because I plan on destroying your brain with mindless followups without an end which is possibly good or bad depending on whom you are so it may be good but you don't know but I know because I'm me and I'm awesome and I can write big sentences for you that will explain everything you may or may not need to know because it is here so I may continue rambling but I should stop but I won't stop because I see no reason to yet because there is so much to learn and explore in this universe with a single line of every topic in every dimension so lets continue pressing on reader who isn't reading anymore but you should read because this is an interesting long sentence that I've been writing for the past time but you don't know how long because I will not say but why I won't say is a secret to you because you haven't seen the rest of my work yet even though we need to get back on the topic which has been lost in the endless sea of letters spaces words and my rambling that will go on for the rest of time and so forth and on because this is a true work of art made by me and for the lone reader who is asleep because of this awesome text that you see before me that I wrote down in a matter of time and will soon be in your hands for all to read and see due to how long the text is because I am the king of rambling or maybe not as the doom predictors were probably better than I am but they are dead so I am better than them until they come back to life and try to kill me but I can fight them off somehow maybe by using a weapon or a word text but anyways you should still be reading my work so you don't die in a few months because this stuff will possibly save your life unless this somehow kills you but that would be funny because how it could happen is beyond me but it could be something possibly important but thats for the dying person to decide instead of you unless you are that guy in which case its ok because then you won't die because the people said so so yay or nay or whatever you want because you are dying unless you are not which is good because you are the only person reading this unless you fell asleep which isn't good because this is important life saving info that you will need to know someday unless you die in which case you wont need it but its always good o know how to ramble and this is great notes that you can use so that you can ramble without thinking about the fact that you are rambling so that in some awkward moment when you must ramble you will be prepared and ready to say whats on your mind because that is something very important to learn for the near or far future so I wish you a nice rambling season and some other random stuff so goodbye generic reader I love you!";

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
    term_write("25_scrolled");
    
    while (1) {}
}
