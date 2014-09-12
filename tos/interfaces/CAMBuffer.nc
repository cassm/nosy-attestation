#include <CAM.h>

interface CAMBuffer {

    // returns the unlocked buffer slot with the earliest alarm time, or null if buffer is empty
    command cam_buffer_t *getEarliest();

    // returns the first buffer slot containing a message with the correct source and ID,
    // or NULL if none match
    command cam_buffer_t *retrieveMsg(uint8_t source, uint8_t msgId);

    // returns the first unused buffer, or NULL if no buffers are free. Marks buffer locked and in use
    command cam_buffer_t *checkOutBuffer();

    // marks a buffer as unlacked and in use
    command error_t checkInBuffer(cam_buffer_t *buff);

    // marks a buffer as no longer in use. Returns FAIL if details match no buffer, EBUSY if the buffer is locked
    //command error_t releaseBuffer(uint8_t source, uint8_t msgId);
    command error_t releaseBuffer(cam_buffer_t *buff);

    // retrieves the buffer slot corresponding to a message's memory address, or null
    command cam_buffer_t *getMsgBuffer(message_t *msg);
} 
