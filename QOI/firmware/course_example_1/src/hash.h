#ifndef HASH_H
#define HASH_H

#define HASH_BASEADDRESS              0x83000000

#define HASH_REG0_ADDRESS             (HASH_BASEADDRESS + 0*4)
#define HASH_REG1_ADDRESS             (HASH_BASEADDRESS + 1*4)

#define HASH_IN                       (*(volatile unsigned int *) HASH_REG0_ADDRESS)
#define HASH_OUT                      (*(volatile unsigned int *) HASH_REG1_ADDRESS)

void HASH_write(unsigned hash_data);
unsigned char HASH_compute(void);

#endif