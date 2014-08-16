#include "CAM.h"

generic module CAMSenderP(am_id_t AMId) {
    uses interface AMSend as SubSend;
    provides interface AMSend as CAMSend;
}

implementation { 
    message_t msgbuffer;
    message_t *msgbufferpointer = &msgbuffer;
    
    bool sendingbusy = FALSE;

    // simply pass the command and result
    command error_t CAMSend.cancel(message_t *msg) {
	error_t result;
	result = call SubSend.cancel(msgbufferpointer);
	if (result == SUCCESS)
	    sendingbusy = FALSE;
	return result;
    }

    command void *CAMSend.getPayload(message_t *msg, uint8_t len) {

	// honour more stringent space requirements of CAM type
	if (len > MAX_PAYLOAD)
	    return NULL;
	else {
	    checksummed_msg_t* payload;

	    // get payload from subsend
	    // TODO: check this works
	    payload = (checksummed_msg_t*) call SubSend.getPayload(msg, sizeof(checksummed_msg_t));

	    if (!payload) {
		//call Leds.set(0x0);
		return NULL;
	    }

	    return payload->data;
	}
    }

    command uint8_t CAMSend.maxPayloadLength() {
	return MAX_PAYLOAD;
    }

    command error_t CAMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	error_t result;
	checksummed_msg_t* payload;
	payload = (checksummed_msg_t*) msg->data;
	payload->len = len;
	payload->type = AMId;
	result = call SubSend.send(addr, msg, sizeof(checksummed_msg_t));
	if (result == SUCCESS)
	    sendingbusy = TRUE;
	return result;
    }

    event void SubSend.sendDone(message_t *msg, error_t error) {
	if (msg == msgbufferpointer)
	    sendingbusy = FALSE;
	signal CAMSend.sendDone(msg, error);
    }
}
