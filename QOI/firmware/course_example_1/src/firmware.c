//#include <stdio.h>

#include "tcnt.h"
#include "sensor.h"
#include "hash.h"

#define LED_BASEAxDDRESS 0x80000000

#define LED_REG0_ADDRESS (LED_BASEAxDDRESS + 0*4)

#define LED (*(volatile unsigned int *) LED_REG0_ADDRESS)

#define CHANNELS 3
#define COLOURPSACE 0x00

void irq_handler(unsigned int cause) {

    TCNT_CR = 0x17;
    TCNT_CR = 0x7;

}

void save_compression(unsigned long long int val, unsigned char digits) {
	unsigned int index, max;
	int i; /* !! must be signed, because of the check 'i>=0' */

	max = digits << 3;
	for (i = max - 8; i >= 0; i -= 8) {
        index = (val) >> i;
        index = index & 0xFF;
        //printf("%02X ", index);
        LED = index;
	}
}

// unsigned int HashFunction(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
//     return (Multiply(r, 3) + Multiply(g, 5) + Multiply(b, 7)+ Multiply(a, 11)) & 0x3F;
// }

// unsigned char closest_difference(unsigned char current, unsigned char prev) {
//     signed char diff = (current >= prev) ? current - prev : 256 - (prev - current);
//     return diff;
// }

int main(void) {

    unsigned char r_prev = 0;
    unsigned char g_prev = 0;
    unsigned char b_prev = 0;
    unsigned char a_prev = 255;

    signed char dr, dg, db; //difference between current and previous pixel
    unsigned char r_cur, g_cur, b_cur, a_cur;

    signed char rle = -1; //counting identical pixels in a row 
    unsigned int running_array[64]; //memory of previous pixels
    unsigned char rv; //temporary storage
    unsigned char index; //index for running array
    unsigned int value; //value of current pixel (8*3bit RGB + 8bit A)
    unsigned int value_prev = 0x000000ff; //value of previous pixel (8*3bit RGB + 8bit A)

    /* Initialisation */
    for(int i=0;i<64;i++) {
        running_array[i] = 0;
    }
    
    LED = 0x71;
    LED = 0x6F;
    LED = 0x69;
    LED = 0x66;

    unsigned char C_WIDTH = SENSOR_get_width();
    unsigned char C_HEIGHT = SENSOR_get_height();
    
    save_compression(C_WIDTH, 4);
    save_compression(C_HEIGHT, 4);

    LED = 0X03;
    LED = 0X00;

    /* Loop over pixels */
    for(unsigned char h=0;h<C_HEIGHT;h++) {
        for(unsigned char w=0;w<C_WIDTH;w++) {

            value = SENSOR_fetch();

            // r_cur = (value >> 24) & 0xFF;
            // g_cur = (value >> 16) & 0xFF;
            // b_cur = (value >> 8) & 0xFF;
            // a_cur = value & 0xFF;

            if(value == value_prev) {
                rle++;
            } else {
                HASH_write(value);
                
                if(rle > -1 || rle == 62) {
                    unsigned long long int result = 0b11000000 + rle;
                    save_compression(result, 1);
                    rle = -1;
                }

                index = HASH_compute();

                if(running_array[index] == value) {
                    unsigned long long int result = 0b00000000 + index;
                    save_compression(result, 1);
                } else {
                    running_array[index] = value;
                    // dr = closest_difference(r_cur, r_prev);
                    // dg = closest_difference(g_cur, g_prev);
                    // db = closest_difference(b_cur, b_prev);

                    int result = SENSOR_difference();
                    //if(dr >= -2 && dr <= 1 && dg >= -2 && dg <= 1 && db >= -2 && db <= 1 && a_cur == a_prev)
                    if((result & 0xFFFFFFC0) == 0x40) {
                        // unsigned long long int result = 0b01000000
                        //                 | ((dr + 2) << 4)
                        //                 | ((dg + 2) << 2)
                        //                 | (db + 2);
                        save_compression(result, 1);
                        //if(dg >= -32 && dg <= 31 && (dr - dg) >= -8 && (dr - dg) <= 7 && (db - dg) >= -8 && (db - dg) <= 7 && a_cur == a_prev)
                    } else if ((result & 0xFFFFC000) == 0x8000) {
                        // unsigned long long int result = 0b1000000000000000
                        //                 | ((dg + 32) << 8)
                        //                 | ((dr - dg + 8) << 4)
                        //                 | (db - dg + 8);
                        save_compression(result, 2);
                    } else {
                        if(CHANNELS == 4){
                            unsigned long long int result = 0xFF00000000 | value;
                            save_compression(result, 5);
                        }
                        else{
                            unsigned long long int result = 0xFE000000 | (value >> 8);
                            save_compression(result, 4);
                        }
                        
                    }
                }
                
            } 
            SENSOR_next();
            value_prev = value;
            // r_prev = r_cur;
            // g_prev = g_cur;
            // b_prev = b_cur;
            // a_prev = a_cur;

        }
    }

    if(rle > -1 || rle == 62) {
        unsigned long long int result = 0b11000000 + rle;
        save_compression(result, 1);
        rle = -1;
    }

    LED = 0x00;
    LED = 0x00;
    LED = 0x00;
    LED = 0x00;
    LED = 0x00;
    LED = 0x00;
    LED = 0x00;
    LED = 0x01;

    return 0;
}

    
