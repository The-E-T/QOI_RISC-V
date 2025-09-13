#include "hash.h"

void HASH_write(unsigned hash_data) {
    HASH_IN = hash_data; // Write the data to the input register
    // No need to read from the output register here, as we are just writing
}

unsigned char HASH_compute(void) {
    unsigned char hash_value;
    hash_value = HASH_OUT; // Read the hash value from the output register
    return hash_value;
}