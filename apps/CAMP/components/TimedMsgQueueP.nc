/*******************************************************************************
 *
 *  NOTE!! This implementation is only for use with checksummed active messages! 
 *  Behaviour with any other kind of message is undefined, and extremely unlikely 
 *  to be at all useful.
 *
 *******************************************************************************/

#include "CAM.h"
#include "printf.h"

generic module TimedMsgQueueP() {
    provides interface TimedMsgQueue;
}
implementation {
    message_t queue[CAM_QUEUE_SIZE];
    message_t exitBuffer;
    bool inUse[CAM_QUEUE_SIZE];
    uint32_t alarmTime[CAM_QUEUE_SIZE];
    checksummed_msg_t *payloadPtr;
    uint8_t i;

    bool sameMsg(message_t *m1, message_t *m2) {
	checksummed_msg_t *p1 = (checksummed_msg_t*) m1->data;
	checksummed_msg_t *p2 = (checksummed_msg_t*) m2->data;
	// if src, ID, and type are the same, we can say the message is the same
	return (p1->src == p2->src && 
		p1->ID == p2->ID && 
		p1->type == p2->type);
    }

    int8_t getEmptySlot() {
	// return the index of an unused buffer, or -1
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( !inUse[i] ) {
		return i;
	    } 
	}
	return -1;
    }


    int getEarliestSlot() {
	int min = -1;
	// if a time is more than 0.75*2^32 ms later, assume instead that it is less than 0.25*2^32 ms 
	// earlier. This deals with intervals which span a wrap.
	uint32_t wrapThreshold = -1;
	wrapThreshold /= 4;

	// find earliest time, accounting for wraps
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		if ( min == -1 
		     || ( alarmTime[i] < alarmTime[min] 
			  && alarmTime[i] - alarmTime[min] > wrapThreshold * 3 )
		     || (alarmTime[i] - alarmTime[min]) > wrapThreshold ) {

		    min = i;
		}	      
	    }
	}
	printfflush();
	
	// returns -1 if queue is empty
	return min;
    }

    int findMsg(message_t *key) {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		if ( sameMsg(key, &queue[i]) )
		    return i;
	    }
	}
	return -1;
    }


    command error_t TimedMsgQueue.initialise() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    inUse[i] = FALSE;
	}
	return SUCCESS;
    }

    // returns the earliest alarm time
    command uint32_t TimedMsgQueue.getEarliestTime() {
	int result = getEarliestSlot();

	// 0 is reserved as the error val for an empty buffer. This occasionally causes
	// alarm timing to slip by 1ms.
	if ( result < 0 )
	    return 0;
	else if ( alarmTime[result] == 0 )
	    return 1;
	else
	    return alarmTime[result];
    }

    // check whether a message is already in the queue
    command bool TimedMsgQueue.isInQueue(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 )
	    return FALSE;
	else
	    return TRUE;
    }

    // returns a pointer to the message with the earliest alarm time
    command message_t *TimedMsgQueue.pop() {
	int result = getEarliestSlot();

	if ( result < 0 )
	    return NULL;

	inUse[result] = FALSE;
	exitBuffer = queue[result];

	return &exitBuffer;
    }

    
    // inserts a message into the queue with the provided alarm time
    command error_t TimedMsgQueue.insert(message_t *msg, uint32_t alarm) {
	int slot;

	// do not allow duplicates
	if ( call TimedMsgQueue.isInQueue(msg) )
	    return EALREADY;

	slot = getEmptySlot();

	// return enomem if full
	if ( slot < 0 )
	    return ENOMEM;

	queue[slot] = *msg;
	inUse[slot] = TRUE;
	alarmTime[slot] = alarm;

	return SUCCESS;
    }

    // removes a message from the queue, if it is present
    command error_t TimedMsgQueue.remove(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 ) {
	    return EINVAL;
	}
	else {
	    inUse[i] = FALSE;
	    return SUCCESS;
	}
    }
	    
    command bool TimedMsgQueue.isEmpty() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    command bool TimedMsgQueue.isFull() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( !inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }
}

    
