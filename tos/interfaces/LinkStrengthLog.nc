#include <message.h>
interface LinkStrengthLog {
    command uint8_t update(message_t* msg);
    command uint8_t getLqi(uint8_t node);
}
