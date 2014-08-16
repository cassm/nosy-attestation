#include <CAM.h>

interface CAMBuffer {
    command cam_buffer_t *getEarliest();
    command cam_buffer_t *retrieveMsg(uint8_t dsn);
    command cam_buffer_t *getBuffer();
} 
