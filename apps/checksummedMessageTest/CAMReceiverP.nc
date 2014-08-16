#include "CAM.h"

generic module CAMReceiverP(am_id_t AMId) {
    uses interface Receive as SubReceive;
    uses interface Leds;
    provides interface Receive;
}

implementation {
    message_t messbuff_in;
    message_t messbuff_out;    
    bool checksummingBusy;
    message_t *msg_ptr;

    task void checksum_and_signal() {
	uint32_t checksum;
	checksummed_msg_t *payload_ptr;       

	checksum = checksum_msg(&messbuff_out);
	payload_ptr = (checksummed_msg_t*) messbuff_out.data;

	if (payload_ptr->checksum)
	    call Leds.led2On();
	payload_ptr->checksum += checksum;

	signal Receive.receive(&messbuff_out, payload_ptr->data, payload_ptr->len);	
	checksummingBusy = FALSE;
    }
	
    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
	checksummed_msg_t *payload_ptr;
	payload_ptr = (checksummed_msg_t*) payload;
	if (payload_ptr->type == AMId && !checksummingBusy) {
	    messbuff_out = *msg;
	    checksummingBusy = TRUE;
	    post checksum_and_signal();
	}
	return &messbuff_in;
    }
}
