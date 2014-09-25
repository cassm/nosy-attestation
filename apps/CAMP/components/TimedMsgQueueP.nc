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
    message_t inspectionBuffer;
    bool inUse[CAM_QUEUE_SIZE];
    uint32_t alarmTime[CAM_QUEUE_SIZE];
    checksummed_msg_t *payloadPtr;
    uint8_t i;

    // Message sameness classifier. Type sensitive among cam, link validation, digest, and report msgs.
    bool sameMsg(message_t *m1, message_t *m2) {
	cc2420_header_t *header1;
	cc2420_header_t *header2;

	header1 = &((message_header_t*)m1->header)->cc2420;
	header1 = &((message_header_t*)m2->header)->cc2420;

	switch(header1->type) {

	case CAMMSG:
	    // if src, ID, and type are the same, we can say the message is the same
	    return (((checksummed_msg_t*)(m1->data))->src == ((checksummed_msg_t*)(m2->data))->src 
		    && ((checksummed_msg_t*)(m1->data))->ID == ((checksummed_msg_t*)(m2->data))->ID 
		    && ((checksummed_msg_t*)(m1->data))->type == ((checksummed_msg_t*)(m2->data))->type);

	case LINKVALMSG:
	    // if src and dest are the same, msg is the same
	    return (((link_validation_msg_t*)(m1->data))->src == ((link_validation_msg_t*)(m2->data))->src
		    && ((link_validation_msg_t*)(m1->data))->dest == ((link_validation_msg_t*)(m2->data))->dest);

	case DIGESTMSG:
	    // if src, curr, ID and type are the same, we can say it is the same msg
	    return (((msg_digest_t*)(m1->data))->src == ((msg_digest_t*)(m2->data))->src
		    && ((msg_digest_t*)(m1->data))->curr == ((msg_digest_t*)(m2->data))->curr
		    && ((msg_digest_t*)(m1->data))->id == ((msg_digest_t*)(m2->data))->id
		    && ((msg_digest_t*)(m1->data))->type == ((msg_digest_t*)(m2->data))->type);

	case REPORTMSG:
	    // if src, curr, next, ID and type are the same, we can say it is the same msg
	    return (((msg_report_t*)(m1->data))->digest.src == ((msg_report_t*)(m2->data))->digest.src
		    && ((msg_report_t*)(m1->data))->digest.curr == ((msg_report_t*)(m2->data))->digest.curr
		    && ((msg_report_t*)(m1->data))->digest.next == ((msg_report_t*)(m2->data))->digest.next
		    && ((msg_report_t*)(m1->data))->digest.id == ((msg_report_t*)(m2->data))->digest.id
		    && ((msg_report_t*)(m1->data))->digest.type == ((msg_report_t*)(m2->data))->digest.type);

	default:
	    // default to src, dest, type, and identifier
	    return (header1->src == header2->src 
		    && header1->dest == header2->dest
		    && header1->type == header2->type
		    && header1->dsn == header2->dsn);	 
	}   
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

	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		if ( min == -1 || inChronologicalOrder( alarmTime[i], alarmTime[min]) ) {
		    min = i;
		}	      
	    }
	}
	
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
    command message_t *TimedMsgQueue.removeMsg(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 ) {
	    return NULL;
	}
	else {
	    inUse[i] = FALSE;
	    exitBuffer = queue[i];
	    return &exitBuffer;
	}
    }

    // inspects a message in the queue, if it is present
    command message_t *TimedMsgQueue.inspectMsg(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 ) {
	    return NULL;
	}
	else {
	    inspectionBuffer = queue[i];
	    return &exitBuffer;
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

    
