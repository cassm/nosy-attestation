#include "CAM.h"

module CAMTestC {
    uses {
	interface Boot;
	interface AMSend;
	interface Leds;
	interface Timer<TMilli> as SendTimer;
	interface Timer<TMilli> as LightTimer;
	interface Receive as GreenReceiver;
	interface Receive as RedReceiver;
	interface SplitControl as AMControl;
    }
}
implementation {
    message_t messbuff;
    message_t messptr;

    event void Boot.booted() {
	call AMControl.start();
    }

    event void AMControl.startDone(error_t error) {
	if (error != SUCCESS)
	    call AMControl.start();
	else
	    if (TOS_NODE_ID == 0)
		call SendTimer.startPeriodic(3000);
    }

    event void AMControl.stopDone(error_t err) {}
	
    event void SendTimer.fired() {
	testmsg_t *payloadptr;
	payloadptr = (testmsg_t*) call AMSend.getPayload(&messbuff, sizeof(testmsg_t));

	if (!payloadptr)
	    call Leds.set(0x7);
	else {
	    payloadptr->val1 = 6;
	    payloadptr->val2 = 18;
	    call AMSend.send(AM_BROADCAST_ADDR, &messbuff, sizeof(testmsg_t));
	}
    }

    event void AMSend.sendDone(message_t *msg, error_t error) {}

    event message_t *RedReceiver.receive(message_t *msg, void *payload, uint8_t len) {
	testmsg_t *tester;
	tester = (testmsg_t*) payload;

	if (tester->val1 == 6 && tester->val2 == 18)
	    call Leds.led0On();
	else 
	    call Leds.led2On();

	call LightTimer.startOneShot(1000);

	return msg;
    }

    event message_t *GreenReceiver.receive(message_t *msg, void *payload, uint8_t len) {
	testmsg_t *tester;
	tester = (testmsg_t*) payload;

	if (tester->val1 == 6 && tester->val2 == 18)
	    call Leds.led1On();
	else 
	    call Leds.led2On();

	call LightTimer.startOneShot(1000);


	return msg;
    }
    event void LightTimer.fired() {
	call Leds.set(0x0);
    }
}
