#include "CAM.h"

generic module CAMReceiverP(am_id_t AMId) {
    uses interface Receive as SubReceive;
    uses interface Leds;
    provides interface Receive;
}

implementation {
    message_t messbuff_in;
    message_t messbuff_out;    

    checksummed_msg_t *payload_ptr;
    message_t *msg_ptr;

    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
	payload_ptr = (checksummed_msg_t*) payload;
	if (payload_ptr->type == AMId) {
	    messbuff_out = *msg;
	    msg_ptr = &messbuff_out;
	    payload_ptr = (checksummed_msg_t*) (msg_ptr->data);
	    signal Receive.receive(msg_ptr, payload_ptr->data, payload_ptr->len);
	}
	return &messbuff_in;
    }
}
