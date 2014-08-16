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

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ ) {
	    if ( buffer[i].inUse && !buffer[i].locked ) {
		if ( !found || buffer[i].alarmtime < result->alarmtime )
		    result = &buffer[i];
		found = TRUE;
	    }
	}
	return result;
    }

    command cam_buffer_t *CAMBuffer.retrieveMsg(uint8_t src, uint8_t msgId) {
	uint8_t i;
	checksummed_msg_t *payload;

	if (!initialised)
	    initialise();

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {
	    if ( buffer[i].inUse ) {
		payload = (checksummed_msg_t*) &buffer[i].message.data;
		if ( payload->msgId == msgId && payload->src == src)
		    return &buffer[i];
	    }
	}
	return NULL;
    }
		

    command cam_buffer_t *CAMBuffer.getBuffer() {
	uint8_t i;
	checksummed_msg_t *payload;

	if (!initialised)
	    initialise();

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ )  {
	    if ( !buffer[i].inUse && !buffer[i].locked ) {
		buffer[i].locked = TRUE;
		return &buffer[i];
	    }
	}
	return NULL;
    }
} 

