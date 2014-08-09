
#ifndef ATTESTATION_H
#define ATTESTATION_H

#include <stdint.h>

#ifdef SENSOR
    #define PROG_MEM_START 0x4000
    #define PROG_MEM_END 0xffe0 
    #include "msp430_pgmspace.h"
#else
    #define PROG_MEM_START 0
    #define PROG_MEM_END 0xbfe0
#endif

#define CHECKSUM_LENGTH 4 // max 8 (64-bit)

// due to the coupon collector's problem we have to do 128K * ln(128K) accesses
// NOTE it increases the attacker's overhead, because the paper assumes 128K memory accesses only

#define MAX_MEMORY_ACCESSES 1544 //474 



#endif

