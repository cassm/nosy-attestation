#include "CAM.h"
#include "printf.h"

generic module MsgQueueP() {
    provides interface MsgQueue;
} 
implementation {
    message_t exitBuffer;
    message_t inspectionBuffer;

    message_t queue[CAM_QUEUE_SIZE];
    bool inUse[CAM_QUEUE_SIZE];
    uint8_t index[CAM_QUEUE_SIZE];

    bool initialised = FALSE;
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

    int findMsg(message_t *key) {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		if ( sameMsg(key, &queue[i]) )
		    return i;
	    }
	}
	return -1;
    }

    int8_t getMax() {
	int8_t max = -1;

	// find the highest-value index which is in use
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] && index[i] > max ) {
		max = index[i];
	    }
	}
	return max;
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

    command error_t MsgQueue.initialise() {
	// mark all buffers as not in use
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ )
	    inUse[i] = FALSE;
	return SUCCESS;
    }

    command bool MsgQueue.isEmpty() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    command bool MsgQueue.isFull() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( !inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    // check whether a message is already in the queue
    command bool MsgQueue.isInQueue(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 )
	    return FALSE;
	else
	    return TRUE;
    }

    command message_t *MsgQueue.getByDest(uint8_t dest) {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] && ((checksummed_msg_t*)(queue[i].data))->dest == dest ) {
		inUse[i] = FALSE;
		return &queue[i];
	    }
	}
	return NULL;
    }

    command message_t *MsgQueue.removeMsg(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 )
	    return NULL;
	else {
	    inUse[i] = FALSE;
	    return &queue[result];
	}
    }	

    // inspects a message in the queue, if it is present
    command message_t *MsgQueue.inspectMsg(message_t *msg) {
	int result = findMsg(msg);
	if ( result < 0 ) {
	    return NULL;
	}
	else {
	    inspectionBuffer = queue[i];
	    return &exitBuffer;
	}
    }

    command error_t MsgQueue.push(message_t *item) {
	int8_t slot = getEmptySlot();

	// if getEmptySlot returns -1, queue is full
	if ( slot < 0 ) {
	    return ENOMEM;
	}

	// place message in empty slot, with next consecutive index value
	index[slot] = getMax() + 1;
	queue[slot] = *item;
	inUse[slot] = TRUE;
	
	return SUCCESS;
    }	

    command error_t MsgQueue.pushFront(message_t *item) {
	int8_t slot = getEmptySlot();
	if ( slot < 0 ) {
	    return ENOMEM;
	}

	// increment all currently used index values
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		index[i]++;
	    }
	}

	// place message in empty slot with index 0
        queue[slot] = *item;
	inUse[slot] = TRUE;
	index[slot] = 0;
	return SUCCESS;
    }	


    // note: pop places the requested buffer into a single exit slot. 
    // Be sure call and copy from it atomically.
    command message_t *MsgQueue.pop() {
	if ( getMax() == -1 ) {
	    return NULL;
	}
	
	// find slot with index 0
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] && index[i] == 0 ) {
		break;
	    }
	}
	
	// empty slot into exit buffer
	inUse[i] = FALSE;
	exitBuffer = queue[i];
	
	// decrement all in use index values
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		index[i]--;
	    }
	}

	return &exitBuffer;
    }

    
}

	
    
