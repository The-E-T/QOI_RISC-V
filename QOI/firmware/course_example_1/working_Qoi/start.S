.global start
.global sw_mult

.section .init, "ax"

start:
reset_vector:
    j do_reset

/* TRAP VECTOR (start at 0x10) */
.balign 16
trap_vector:
    csrrw sp, mscratch, sp

    sw x1,   0*4(sp)
    sw x3,   1*4(sp)
    sw x4,   2*4(sp)
    sw x5,   3*4(sp)
    sw x6,   4*4(sp)
    sw x7,   5*4(sp)
    sw x8,   6*4(sp)
    sw x9,   7*4(sp)
    sw x10,  8*4(sp)
    sw x11,  9*4(sp)
    sw x12, 10*4(sp)
    sw x13, 11*4(sp)
    sw x14, 12*4(sp)
    sw x15, 13*4(sp)
    sw x16, 14*4(sp)
    sw x17, 15*4(sp)
    sw x18, 16*4(sp)
    sw x19, 17*4(sp)
    sw x20, 18*4(sp)
    sw x21, 19*4(sp)
    sw x22, 20*4(sp)
    sw x23, 21*4(sp)
    sw x24, 22*4(sp)
    sw x25, 23*4(sp)
    sw x26, 24*4(sp)
    sw x27, 25*4(sp)
    sw x28, 26*4(sp)
    sw x29, 27*4(sp)
    sw x30, 28*4(sp)
    sw x31, 29*4(sp)

    csrrc a0, mcause, zero
    jal ra, irq_handler

    lw x1,   0*4(sp)
    lw x3,   1*4(sp)
    lw x4,   2*4(sp)
    lw x5,   3*4(sp)
    lw x6,   4*4(sp)
    lw x7,   5*4(sp)
    lw x8,   6*4(sp)
    lw x9,   7*4(sp)
    lw x10,  8*4(sp)
    lw x11,  9*4(sp)
    lw x12, 10*4(sp)
    lw x13, 11*4(sp)
    lw x14, 12*4(sp)
    lw x15, 13*4(sp)
    lw x16, 14*4(sp)
    lw x17, 15*4(sp)
    lw x18, 16*4(sp)
    lw x19, 17*4(sp)
    lw x20, 18*4(sp)
    lw x21, 19*4(sp)
    lw x22, 20*4(sp)
    lw x23, 21*4(sp)
    lw x24, 22*4(sp)
    lw x25, 23*4(sp)
    lw x26, 24*4(sp)
    lw x27, 25*4(sp)
    lw x28, 26*4(sp)
    lw x29, 27*4(sp)
    lw x30, 28*4(sp)
    lw x31, 29*4(sp)

    csrrw sp, mscratch, sp
    mret

do_reset:
    /* clear registers */
    addi x1, x0, 0
    addi x2, x0, 0
    addi x3, x0, 0
    addi x4, x0, 0
    addi x5, x0, 0
    addi x6, x0, 0
    addi x7, x0, 0
    addi x8, x0, 0
    addi x9, x0, 0
    addi x10, x0, 0
    addi x11, x0, 0
    addi x12, x0, 0
    addi x13, x0, 0
    addi x14, x0, 0
    addi x15, x0, 0
    addi x16, x0, 0
    addi x17, x0, 0
    addi x18, x0, 0
    addi x19, x0, 0
    addi x20, x0, 0
    addi x21, x0, 0
    addi x22, x0, 0
    addi x23, x0, 0
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0
    addi x31, x0, 0

    /* set gp and tp */
    lui gp, %hi(0xdeadbeef)
    addi gp, gp, %lo(0xdeadbeef)
    addi tp, gp, 0

    /* This part is for/from Zicsr */
    lui x2, %hi(4*1024)
    addi x2, x2, %lo(4*1024)
    csrrw x0, mscratch, x2

    /* write mtvec */
    la x2, trap_vector
    csrrw x0, mtvec, x2

    /* enable general interrupt */
    csrrwi x0, mstatus, 8

    /* allow all external interrupts */
    addi x2, zero, -1
    csrrw x0, mie, x2

    /* set stack pointer */
    lui x2, %hi(4*1024-32)
    addi x2, x2, %lo(4*1024-32)



    /* call main function */
    jal ra, main

    /* trap */
    ebreak

    jal ra, main
    j done

# Software multiplication. It returns the product of a0 and a1
sw_mult: 
    addi sp, sp, -(3*4)
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
        
    # Return a0, in case it is 0x0
    bne a0, zero, sw_mult_init
    j sw_mult_exit
sw_mult_init:
    # Initialise t0 (=x-1) and t1 (=y)
    add t1, a1, zero
    addi t0, a0, -1
    # Return y if t0 is 0x0
    bne t0, zero, sw_mult_loop
    add a0, a1, zero
    j sw_mult_exit
sw_mult_loop:
    # Add (t1 += a1) and substract (t0--)
    add t1, t1, a1
    addi t0, t0, -1
    # Check to see if the operation is done
    bne t0, zero, sw_mult_loop
    add a0, t1, zero
sw_mult_exit:
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    addi sp, sp, (3*4)
    jalr zero, 0(ra)

done:
    j done

error:
    j error
