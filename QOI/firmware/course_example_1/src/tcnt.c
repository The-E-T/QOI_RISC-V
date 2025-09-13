#include "tcnt.h"

void TCNT_start(void) {
    TCNT_CR = TCNT_CR | TCNT_CR_CS_ON;
}

void TCNT_start_div8(void) {
    TCNT_stop();
    TCNT_CR = TCNT_CR | TCNT_CR_CS_DIV8;
}

void TCNT_start_div16(void) {
    TCNT_stop();
    TCNT_CR = TCNT_CR | TCNT_CR_CS_DIV64;
}

void TCNT_stop(void) {
    TCNT_CR = TCNT_CR & ~(TCNT_CR_CS_ON);
}
