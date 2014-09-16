#include "CAM.h"
#include "printf.h"

module PongC {
    uses {
	interface SplitControl as RadioControl;
	interface Boot;
	interface AMSend;
	interface Receive;
	interface Timer<TMilli> as Timer;
    }
}
implementation {
    message_t msgBuff;
    testmsg_t *payloadPtr = (testmsg_t*) msgBuff.data;

    event void Boot.booted() {
	call RadioControl.start();
    }

    event void RadioControl.startDone(error_t ok) {
	if (ok != SUCCESS) 
	    call RadioControl.start();
	else {
	    if (TOS_NODE_ID == 0) 
		call AMSend.send(2, &msgBuff, sizeof(testmsg_t));
	}
    }

    event void RadioControl.stopDone(error_t error) {}

    event void AMSend.sendDone(message_t* msg, error_t error) {}

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	call Timer.startOneShot(4000);
	return msg;
    }

    event void Timer.fired() {
	if (TOS_NODE_ID == 0)
	    call AMSend.send(2, &msgBuff, sizeof(testmsg_t));
	else
	    call AMSend.send(0, &msgBuff, sizeof(testmsg_t));
    }
}
