#include <CAM.h>

generic module CAMBufferP() {
    provides interface CAMBuffer;
}

implementation {
    cam_buffer_t buffer[CAM_BUFFER_SIZE];
    uint8_t j;
    bool initialised = FALSE;

    void initialise() {
	// initialise buffer to empty and unlocked
	for ( j = 0 ; j < CAM_BUFFER_SIZE ; j++ ) {
	    buffer[j].locked = FALSE;
	    buffer[j].inUse = FALSE;
	}
	initialised = TRUE;
    }
    
    command cam_buffer_t *CAMBuffer.getEarliest() {
	uint8_t i;
	bool found = FALSE;
	cam_buffer_t *result = NULL;

	if (!initialised)
	    initialise();

	// find the buffer with the earliest alarm time
	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ ) {
	    if ( buffer[i].inUse && !buffer[i].locked ) {
		if ( !found || buffer[i].alarmtime < result->alarmtime )
		    result = &buffer[i];
		found = TRUE;
	    }
	}

	// return 
	return result;
    }

    command cam_buffer_t *CAMBuffer.retrieveMsg(uint8_t src, uint8_t msgId) {
	uint8_t i;
	checksummed_msg_t *payload;

	if (!initialised)
	    initialise();

	// check all buffers to see if src and msgID match
	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {
	    if ( buffer[i].inUse && !buffer[i].locked ) {
		payload = (checksummed_msg_t*) &(buffer[i].message.data);
		if ( payload->ID == msgId && payload->src == src)
		    // if so, return appropriate buffer
		    return &buffer[i];
	    }
	}

	// if none match, message could not be found
	return NULL;
    }
		

    command cam_buffer_t *CAMBuffer.checkOutBuffer() {
	uint8_t i;

	if (!initialised)
	    initialise();

	// return first unlocked, unused buffer
	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {
	    if ( !buffer[i].inUse && !buffer[i].locked ) {
		buffer[i].locked = TRUE;
		buffer[i].inUse = TRUE;
		return &buffer[i];
	    }
	}
	
	// if all buffers locked or in use, return null
	return NULL;
    }

    command error_t CAMBuffer.checkInBuffer(cam_buffer_t *buff) {
	uint8_t i;

	if (!initialised)
	    initialise();

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {

	    // if payload address matches, unlock it and return success
	    if ( &buffer[i] == buff) {
		buffer[i].locked = FALSE;
		buffer[i].inUse = TRUE;
		return SUCCESS;
	    }
	}

	// if no buffer matched, buffer could not be found
	return FAIL;
    }

    command cam_buffer_t *getMsgBuffer(message_t *msg) {
	unti8_t i;
	checksummed_msg_t* msgPtr;

	for (i = 0 ; i < CAM_BUFFER_SIZE ; i++) {
	    if (!buffer[i].locked) {
		if ( &(buffer[i].message) == msg )
		    return &(buffer[i]);
	    }
	}

	return NULL;
    }

/*    command error_t releaseBuffer(uint8_t source, uint8_t msgId) {
	uint8_t i;
	checksummed_msg_t* payload;

	if (!initialised)
	    initialise();

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {
	    // check all buffers which are currently in use
	    if (buffer.inUse) {
		payload = (checksummed_msg_t*) buffer[i].message.data;

		if ( payload.msgId == msgId && payload.src == source ) {

		    // if buffer matches and is in use, return ebusy
		    if (buffer[i].locked) {
			return EBUSY;
		    }

		    // if buffer matches and is not in use, clear it and return success
		    else {
			buffer[i].inUse = FALSE;
			return SUCCESS;
		    }
		}
	    }
	}

	// if all buffers have been checked and nothing has been returned, message cannot be found
	return FAIL;
    }    
*/
    command error_t CAMBuffer.releaseBuffer(cam_buffer_t *buff) {
	if (buff->locked)  
	    return EBUSY;
	else {
	    buff->inUse = FALSE;
	    return SUCCESS;
	}
    }
} 

