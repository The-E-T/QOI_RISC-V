#ifndef SENSOR_H
#define SENSOR_H

#define SENSOR_BASEADDRESS              0x82000000

#define SENSOR_REG0_ADDRESS             (SENSOR_BASEADDRESS + 0*4)
#define SENSOR_REG1_ADDRESS             (SENSOR_BASEADDRESS + 1*4)
#define SENSOR_REG2_ADDRESS             (SENSOR_BASEADDRESS + 2*4)
#define SENSOR_REG3_ADDRESS             (SENSOR_BASEADDRESS + 3*4)

#define SENSOR_CR                       (*(volatile unsigned int *) SENSOR_REG0_ADDRESS)
#define SENSOR_PIXELDATA                (*(volatile unsigned int *) SENSOR_REG1_ADDRESS)
#define SENSOR_SR                       (*(volatile unsigned int *) SENSOR_REG2_ADDRESS)
#define SENSOR_DIFF                     (*(volatile unsigned int *) SENSOR_REG3_ADDRESS)

#define SENSOR_CR_RE                    0x1
#define SENSOR_SR_FIRST                 0x3

#define SENSOR_get_width()              (unsigned char)((SENSOR_SR>>16) & 0xff)
#define SENSOR_get_height()             (unsigned char)((SENSOR_SR>>8) & 0xff)

unsigned int SENSOR_fetch(void);
unsigned int SENSOR_difference(void);
void SENSOR_next(void);

#endif