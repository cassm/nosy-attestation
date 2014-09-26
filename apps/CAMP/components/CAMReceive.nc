#include <message.h>
interface CAMReceive {
    event void receive(message_t* msg, void* payload, uint8_t len);
}
