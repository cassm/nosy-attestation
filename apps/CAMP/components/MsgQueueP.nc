#include "CAM.h"

component MsgQueueP {
    provides interface MsgQueue;
} 
implementation {
    message_t exitBuffer;

    message_t queue[CAM_QUEUE_SIZE];
    bool inUse[CAM_QUEUE_SIZE];
    uint8_t index[CAM_QUEUE_SIZE];

    bool initialised = FALSE;
    uint8_t i;

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

    command error_t initialise() {
	// mark all buffers as not in use
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ )
	    inUse[i] = FALSE;
    }

    command bool isEmpty() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    command bool isFull() {
	// buffer fills up from the bottom, so check the top first
	for ( i = CAM_QUEUE_SIZE - 1 ; i >= 0 ; i-- ) {
	    if ( !inUse[i] ) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    command error_t push(message_t *item) {
	int8_t slot = getEmptySlot();

	// if getEmptySlot returns -1, queue is full
	if ( slot < 0 ) {
	    return ENOMEM;
	}

	// place message in empty slot, with next consecutive index value
	buffer[slot] = *item;
	inUse[slot] = TRUE;
	index[slot] = getMax() + 1;
	return SUCCESS;
    }	

    command error_t pushFront(message_t *item) {
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
	buffer[slot] = *item;
	inUse[slot] = TRUE;
	index[slot] = 0;
	return SUCCESS;
    }	


    // note: pop places the requested buffer into a single exit slot. 
    // Be sure call and copy from it atomically.
    command message_t *pop(message_t *item) {
	if ( isEmpty() ) {
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
	exitBuffer = buffer[i];
	
	// decrement all in use index values
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( inUse[i] ) {
		index[i]--;
	    }
	}

	return &exitBuffer;
    }
}

	
    
