# README

## Changes in philosophy

### Peripheral mask
A 32-bit address is logically divided into two parts when it comes to memory-mapped IO. The most significant part is used to select a peripheral. The least significant part is used to select a register in the peripheral. The split was made on 12 bits (31..12 for peripheral selection and 11..0 for register selection). Given that the data memory is 8KiB, a 12-bit register selection is required but can not be served. Therefore the cut-off point is repositioned to 16. Now bits 31-16 select the peripheral and bits 15..0 select the register.

### An external interrupt
An external interrupt is added to the microcontroller. This is mapped to *"BTN[3]"*. Before this signal can be used, it needs to be synchronised first. This is done by two FF in series. Next, the signal needs to be debounced. If the output of the second FF is high, it enables a counter. When this counter is 15 cycles before its maximum, a set-reset flipflop is set. When this counter is 1 cycles before its maximum, the set-reset flipflop is reset. This produces an interrupt that is high for 14 clock cycles, which should be sufficient for the processor to catch it.
This single external interrupt signal replaces the 32-bit interrupt vector.

### Organisation of memories
An error has been made with respect to memory addressing. The linker script was written with a 32-bit width in mind. This is not correct and it is also byte-aligned. The sizes of the memory section in the linker script have been update to 8kb and the offsets of the RAM and the rodata section have been updated accordingly.


## Changes to the hardware

* wrapped_timer.vhd
  * a set-reset FF is added to keep an interrupt for longer than an a single clock cycle
  * the reset must be acknowledged (as in ... the reset for the SRFF) through register0(4)
  * an output port **irq** is added
  * implemented rescaling of peripheral mask
* PKG_hwswcd.vhd
  * the added port of the wrapped_timer is added to the component declaration
  * implemented rescaling of peripheral mask
  * updated to a single external interrupt source
* riscv_microcontroller_tb.vhd
  * the external interrupt is commented out
  * updated to a single external interrupt source
* riscv_microcontroller.vhd
  * the interrupt of the wrapped_timer is connected to the RISC-V
  * implemented rescaling of peripheral mask
  * updated to a single external interrupt source
  * [BUGFIX] when writing to the DMEM, the peripheral mask should be verified
  * [BUGFIX] 32-bit vs 8-bit memory organisation
* riscv_microcontroller_pynq.xdc
  * updated to a single external interrupt source


## Changes to the software

### Firmware
* [BUGFIX] the sw_mult firmware (in assembly) did not back up registers T0 and T1 on the stack
* [BUGFIX] the initialisation of the stack pointer in **mscratch** was wrong
* [BUGFIX] linkerscript has correct memory addresses
* []

### Tools
* newer version of the conversion tool for firmware_imem.hex and firmware_dmem.hex generation

