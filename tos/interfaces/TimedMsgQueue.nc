#include <CAM.h>

interface TimedMsgQueue {
    command error_t initialise();

    // returns the earliest alarm time
    command uint32_t getEarliestTime();

    // check whether a message is already in the queue
    command bool isInQueue(message_t *msg);

    // returns a pointer to the message with the earliest alarm time
    command message_t *pop();

    // inserts a message into the queue with the provided alarm time
    command error_t insert(message_t *msg, uint32_t alarmTime);

    // removes a message from the queue, if it is present
    command error_t remove(message_t *msg);

    command bool isEmpty();
    command bool isFull();
}
