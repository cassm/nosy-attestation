/* A queue for message buffers. Contents are ordered by index */

interface MsgQueue {
    command error_t initialise();

    command bool isEmpty();

    command bool isFull();

    command error_t push(message_t* item);

    command error_t pushFront(message_t* item);

    // note: pop places the requested buffer into a single exit slot. 
    // Be sure call and copy from it atomically.
    command message_t *pop(message_t* item);
}
