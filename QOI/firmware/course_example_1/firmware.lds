ENTRY(start)

MEMORY 
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 8k
    RAM (rwx) : ORIGIN = 0x00002000, LENGTH = 8k
}
SECTIONS {
    /* this part has to go into the IMEM */
    .text : {
        . = 0x000000;
        *(.init);
        *(.text*);
    } > ROM

    /* this part has to go into the DMEM */
    .data : {
        . = 0x000;
        *(.data);
    } > RAM

    .rodata : {
        . = 0x1000;
        *(.rodata);
        . = ALIGN(4);
        FILL(0xFF)
    } > RAM

    /DISCARD/ :
    {
        *(.note*);
        *(.iplt*);
        *(.igot*);
        *(.rel*);
        *(.comment);
        *(.riscv.attributes);
    }
}

