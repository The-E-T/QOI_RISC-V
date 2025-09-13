#include "sensor.h"

unsigned int SENSOR_fetch(void) {
    unsigned int pixeldata;
    pixeldata = SENSOR_PIXELDATA;
    return pixeldata;
}

unsigned int SENSOR_difference(void) {
    return SENSOR_DIFF;
}

void SENSOR_next(void) {
    SENSOR_CR |= SENSOR_CR_RE; 
    SENSOR_CR &= ~SENSOR_CR_RE; 
}