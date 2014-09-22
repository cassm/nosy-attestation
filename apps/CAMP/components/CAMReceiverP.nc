#include "printf.h"
generic module CAMReceiverP(am_id_t AMId) {
    provides interface Receive;
    uses interface Receive as SubReceive;
}
implementation {
    message_t receiveBuffer;
    message_t *receiveBufferPtr;
    bool initialised;

    event message_t *SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	message_header_t *headerPtr;
	message_header_t *subHeaderPtr;
	checksummed_msg_t *payloadPtr = (checksummed_msg_t*) msg->data;

	if (!initialised) {
	    receiveBufferPtr = &receiveBuffer;
	}
	
	initialised = TRUE;

	

	if ( payloadPtr->type == AMId ) {
	    headerPtr = (message_header_t*) msg->header;
	    subHeaderPtr = (message_header_t*) receiveBufferPtr->header;

	    headerPtr->cc2420.length = payloadPtr->len;
	    headerPtr->cc2420.fcf = subHeaderPtr->cc2420.fcf;
	    headerPtr->cc2420.dsn = subHeaderPtr->cc2420.dsn;
	    headerPtr->cc2420.destpan = subHeaderPtr->cc2420.destpan;
	    headerPtr->cc2420.dest = payloadPtr->dest;
	    headerPtr->cc2420.src = payloadPtr->src;

	    memcpy(receiveBufferPtr->data, payloadPtr->data, payloadPtr->len);
	    receiveBufferPtr = signal Receive.receive(receiveBufferPtr, receiveBufferPtr->data, payloadPtr->len);
	}	    

	return msg;
    }
}
