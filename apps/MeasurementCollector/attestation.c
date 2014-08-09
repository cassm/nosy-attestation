
// NOTE to avoid cache flushes during the attestation, the code should be 
//      placed within one cache block (i.e. one single compressed block)

#include "attestation.h"

uint32_t attestation(uint32_t nonce, uint32_t max) {
    uint16_t i;
    uint32_t checksum;
    uint8_t byte;

    checksum = 0;

    for( i = PROG_MEM_START ; i < max ; i++ ) {
	byte = pgm_read_byte_far(i);
	if (nonce % byte & 0x1) { 
	    checksum = (checksum + byte) % 4294967296; // 2^32
	}
    }

    // todo: make the nonce do anything

    return checksum;
}

