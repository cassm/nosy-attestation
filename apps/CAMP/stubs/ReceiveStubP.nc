#include "CAM.h"
#include "printf.h"

module ReceiveStubP {
    provides interface StdControl as ReceiveControl;
    provides interface Receive;
    uses interface Timer<TMilli> as Timer;
}
implementation {
    message_t messBuff;
    checksummed_msg_t *payloadPtr;
    uint8_t i = 1;
    uint8_t j = 0;
    bool active = FALSE;

    event void Timer.fired() {
	payloadPtr = (checksummed_msg_t*) messBuff.data;
	payloadPtr->ID = j++;
	payloadPtr->dest = i++;
	if (i > 5)
	    i = 0;
	payloadPtr->src = 35;
	payloadPtr->type = TESTMSG;
	signal Receive.receive(&messBuff, payloadPtr, sizeof(checksummed_msg_t));
    }

    command error_t ReceiveControl.start() {
	if (active)
	    return EALREADY;

	active = TRUE;
	//signal Timer.fired();
	call Timer.startPeriodic(8000);
	return SUCCESS;
    }

    command error_t ReceiveControl.stop() {
	if (!active)
	    return EALREADY;
	active = FALSE;
	call Timer.stop();
	return SUCCESS;
    }
}
