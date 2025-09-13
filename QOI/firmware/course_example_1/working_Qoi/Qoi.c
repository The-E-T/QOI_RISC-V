#include <stdio.h>

#define LED_BASEAxDDRESS 0x80000000

#define LED_REG0_ADDRESS (LED_BASEAxDDRESS + 0*4)

#define LED (*(volatile unsigned int *) LED_REG0_ADDRESS)

#define C_WIDTH 8
#define C_HEIGHT 8

struct qoi_header {
    char     magic[4];       // magic bytes "qoif"
    unsigned int width;      // image width in pixels (BE)
    unsigned int height;     // image height in pixels (BE)
    unsigned char  channels;   // 3 = RGB, 4 = RGBA
    unsigned char  colorspace; // 0 = sRGB with linear alpha
                               // 1 = all channels linear
};

/* Header */
struct qoi_header header = {
    .magic = {'q', 'o', 'i', 'f'},
    .width = C_WIDTH,
    .height = C_HEIGHT,
    .channels = 0x03,
    .colorspace = 0x66
};

void irq_handler(unsigned int cause) {

    if (cause & 4) {
        LED = 0xFFFFFFFF;
    }

}

void initialise(unsigned char r[C_WIDTH][C_HEIGHT], unsigned char g[C_WIDTH][C_HEIGHT], unsigned char b[C_WIDTH][C_HEIGHT], unsigned char a[C_WIDTH][C_HEIGHT]) {
    unsigned char w, h;

    for(h=0;h<C_HEIGHT/2;h++) {
        for(w=0;w<C_WIDTH/2;w++) {
            r[h][w] = 255; g[h][w] = 0; b[h][w] = 0; a[h][w] = 255;
        }
        for(w=C_WIDTH/2;w<C_WIDTH;w++) {
            r[h][w] = 0; g[h][w] = 255; b[h][w] = 0; a[h][w] = 255;
        }
    }
    for(h=C_HEIGHT/2;h<C_HEIGHT;h++) {
        for(w=0;w<C_WIDTH/2;w++) {
            r[h][w] = 0; g[h][w] = 0; b[h][w] = 255; a[h][w] = 255;
        }
        for(w=C_WIDTH/2;w<C_WIDTH;w++) {
            r[h][w] = 127; g[h][w] = 127; b[h][w] = 127; a[h][w] = 255;
        }
    }
}

unsigned int Multiply(unsigned int a, unsigned int b) {
    unsigned int result = 0;

    while (b > 0) {
        if (b & 1) { 
            result += a;
        }
        a <<= 1; 
        b >>= 1; 
    }

    return result;
}

unsigned char get_needed_bytes(unsigned long long int number) {
    unsigned char count = 0;
    do {
        count++;
        number >>= 8;
    } while (number != 0);
    return count;
}

void save_compression(unsigned long long int val, unsigned char digits) {
	unsigned int index, max;
	int i; /* !! must be signed, because of the check 'i>=0' */

	max = digits << 3;

	for (i = max - 8; i >= 0; i -= 8) {
        index = (val) >> i;
        index = index & 0xFF;
        printf("%02X ", index);
        //LED = index;
	}
}

unsigned int HashFunction(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    return (Multiply(r, 3) + Multiply(g, 5) + Multiply(b, 7)+ Multiply(a, 11)) & 0x3F;
}

unsigned char closest_difference(unsigned char current, unsigned char prev) {
    signed char diff = (current >= prev) ? current - prev : 256 - (prev - current);
    return diff;
}


int main(void) {

    // TCNT_stop();

    unsigned char r[C_HEIGHT][C_WIDTH];
    unsigned char g[C_HEIGHT][C_WIDTH];
    unsigned char b[C_HEIGHT][C_WIDTH];
    unsigned char a[C_HEIGHT][C_WIDTH];

    unsigned char r_prev = 0;
    unsigned char g_prev = 0;
    unsigned char b_prev = 0;
    unsigned char a_prev = 255;

    signed char dr, dg, db; //difference between current and previous pixel


    signed char rle = -1; //counting identical pixels in a row 
    unsigned int running_array[64]; //memory of previous pixels
    unsigned char rv; //temporary storage
    unsigned char index; //index for running array
    unsigned int value; //value of current pixel (8*3bit RGB + 8bit A)
    unsigned int value_prev = 0; //value of previous pixel (8*3bit RGB + 8bit A)

    /* Sanity check */
    if((C_WIDTH % 2) || (C_HEIGHT % 2)) {
        while(1) {
            // Error: C_WIDTH and C_HEIGHT must be even numbers
        }
        return 1;
    }

    /* Initialisation */
    initialise(r, g, b, a);
    for(int i=0;i<64;i++) {
        running_array[i] = 0;
    }

    // LED = 0x71;
    // LED = 0x6F;
    // LED = 0x69;
    // LED = 0x66;
    
    save_compression(header.width, 4);
    save_compression(header.height, 4);

    // LED = 0X03;
    // LED = 0X00;

    // LED = header.channels;
    // LED = header.colorspace;
    // save_compression(header.channels, 1);
    // save_compression(header.colorspace, 1);

    /* Loop over pixels */
    for(unsigned char h=0;h<C_HEIGHT;h++) {
        for(unsigned char w=0;w<C_WIDTH;w++) {

            if(header.channels == 4) {
                value = (r[h][w] << 24) | (g[h][w] << 16) | (b[h][w] << 8) | a[h][w];
            } else {
                value = (r[h][w] << 16) | (g[h][w] << 8) | b[h][w];
            }
            

            if(value == value_prev) {
                rle++;
            } else {

                if(rle > -1 || rle == 62) {
                    unsigned long long int result = 0b11000000 + rle;
                    save_compression(result, get_needed_bytes(result));
                    rle = -1;
                }
            
                index = HashFunction(r[h][w], g[h][w], b[h][w], a[h][w]);

                if(running_array[index] == value) {
                    unsigned long long int result = 0b00000000 + index;
                    save_compression(result, get_needed_bytes(result));
                } else {
                    running_array[index] = value;
                    dr = closest_difference(r[h][w], r_prev);
                    dg = closest_difference(g[h][w], g_prev);
                    db = closest_difference(b[h][w], b_prev);

                    if(dr >= -2 && dr <= 1 && dg >= -2 && dg <= 1 && db >= -2 && db <= 1 && a[h][w] == a_prev) {
                        unsigned long long int result = 0b01000000
                                        | ((dr + 2) << 4)
                                        | ((dg + 2) << 2)
                                        | (db + 2);
                        save_compression(result, get_needed_bytes(result));
                    } else if (dg >= -32 && dg <= 31 && (dr - dg) >= -8 && (dr - dg) <= 7 && (db - dg) >= -4 && (db - dg) <= 4 && a[h][w] == a_prev) {
                        unsigned long long int result = 0b1000000000000000
                                        | ((dg + 32) << 8)
                                        | ((dr - dg + 8) << 4)
                                        | (db - dg + 8);
                        save_compression(result, get_needed_bytes(result));
                    } else {
                        if(header.channels == 4){
                            unsigned long long int result = 0xFF00000000 | value;
                            save_compression(result, 5);
                        }
                        else{
                            unsigned long long int result = 0xFE000000 | value;
                            save_compression(result, 4);
                        }
                        
                    }
                }
                
            } 

                value_prev = value;
            r_prev = r[h][w];
            g_prev = g[h][w];
            b_prev = b[h][w];
            a_prev = a[h][w];
        }
    }

    if(rle > -1 || rle == 62) {
        unsigned long long int result = 0b11000000 + rle;
        save_compression(result, get_needed_bytes(result));
        rle = -1;
    }

    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x00;
    // LED = 0x01;

    return 0;
}

    
