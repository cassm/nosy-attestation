#include "CAM.h"

generic module CAMSenderP(am_id_t AMId) {
    provides interface AMSend;
    uses interface AMSend as SubSend;
}

implementation {
    bool sendingBusy;
    message_t sendingBuffer;
    message_t *msgPtr;

    command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	checksummed_msg_t* payload = (checksummed_msg_t*) sendingBuffer.data;

	if ( sendingBusy )
	    return EBUSY;

	sendingBusy = TRUE;

	payload->type = AMId;
	payload->len = len;
	payload->src = TOS_NODE_ID;
	payload->dest = addr;
	payload->prev = TOS_NODE_ID;
	payload->curr = TOS_NODE_ID;
	payload->next = TOS_NODE_ID;
	
	memcpy(payload->data, msg->data, len);
	
	return call SubSend.send(addr, &sendingBuffer, sizeof(checksummed_msg_t));
    }

    event void SubSend.sendDone(message_t *msg, error_t result) {
	sendingBusy = FALSE;
	signal AMSend.sendDone(msgPtr, result);
    }

    command error_t AMSend.cancel(message_t* msg) {
	// TODO: Be less worse
	return SUCCESS;
    }

    command uint8_t AMSend.maxPayloadLength() {
	return MAX_PAYLOAD;
    }

    command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	if ( len > MAX_PAYLOAD )
	    return NULL;
	return msg->data;
    }
}
