ENTRY(kmain)

SECTIONS
{
    . = 0x9000;

    .text ALIGN(0x1000) :
    {
        *(.text)
    }

    .rodata ALIGN(0x1000) :
    {
        *(.text)
    }

    .data ALIGN(0x1000) :
    {
        *(.text)
    }

    .bss ALIGN(0x1000) :
    {
        *(.text)
    }
}
