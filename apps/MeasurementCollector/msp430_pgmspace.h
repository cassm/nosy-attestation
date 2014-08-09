#ifndef MSP430_PGM
#define MSP430_PGM
#include <stdint.h>

uint8_t pgm_read_byte_far(uint16_t address_long) {
    uint8_t *Flash_ptrA;                         // Segment A pointer
    uint8_t CAL_DATA;

    Flash_ptrA = (uint8_t *)address_long;              // Initialize Flash segment A ptr
    CAL_DATA = Flash_ptrA[0];
    return CAL_DATA;
}


#endif
