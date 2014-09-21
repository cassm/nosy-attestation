#include "CAM.h"
#include "printf.h"

module SendStubP {
    provides interface AMSend;
    uses interface Timer<TMilli>;
}
implementation {
    message_t *msgPtr;

    event void Timer.fired() {
	signal AMSend.sendDone(msgPtr, SUCCESS);
    }

    command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	msgPtr = msg;
	printf("SubSend sending message to %d.\n", addr);
	signal AMSend.sendDone(msgPtr, SUCCESS);
	//call Timer.startOneShot(50);
	return SUCCESS;
    }

    command error_t AMSend.cancel(message_t* msg) {
	return SUCCESS;
    }

    command uint8_t AMSend.maxPayloadLength() {
	return TOSH_DATA_LENGTH;
    }

    command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	if (len > TOSH_DATA_LENGTH)
	    return NULL;
	else
	    return msg->data;
    }
}
     
