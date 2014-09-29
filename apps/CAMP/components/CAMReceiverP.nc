#include "printf.h"
generic module CAMReceiverP(am_id_t AMId) {
    provides interface Receive;
    uses interface CAMReceive as SubReceive;
}
implementation {
    message_t receiveBuffer;
    message_t *receiveBufferPtr;
    bool initialised;

    event void SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	message_header_t *headerPtr;
	checksummed_msg_t *payloadPtr;

	if (!initialised) {
	    receiveBufferPtr = &receiveBuffer;
	}

	initialised = TRUE;

	if ( ((checksummed_msg_t*)msg->data)->type == AMId ) {
	    *receiveBufferPtr = *msg;

	    headerPtr = (message_header_t*) receiveBufferPtr->header;
	    payloadPtr = (checksummed_msg_t*) msg->data;

	    headerPtr->cc2420.length = payloadPtr->len;
	    headerPtr->cc2420.dest = payloadPtr->dest;
	    headerPtr->cc2420.src = payloadPtr->src;
	    headerPtr->cc2420.type = payloadPtr->type;

	    memcpy(receiveBufferPtr->data, payloadPtr->data, payloadPtr->len);

	    receiveBufferPtr = signal Receive.receive(receiveBufferPtr, receiveBufferPtr->data, payloadPtr->len);
	}	    
    }
}
