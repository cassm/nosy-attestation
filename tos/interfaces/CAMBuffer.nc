#include <CAM.h>

interface CAMBuffer {
    command message_t *getEarliest();
    command message_t *retrieveMsg(uint8_t source, uint8_t dsn);
    command message_t *checkOutBuffer();
    command error_t checkInBuffer(message_t *buffer);
} 
