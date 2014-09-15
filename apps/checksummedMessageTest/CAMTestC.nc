#include "CAM.h"
#include "printf.h"

module CAMTestC {
    uses {
	interface Boot;
	interface AMSend;
	interface Timer<TMilli> as Timer;
	interface Receive as Receiver;
	interface SplitControl as AMControl;
	interface RouteFinder;
    }
}
implementation {
    message_t messbuff;
    message_t messptr;
    uint8_t i;

    event void Boot.booted() {
	call AMControl.start();
    }

    event void AMControl.startDone(error_t error) {
	if (error != SUCCESS)
	    call AMControl.start();
	else
	    signal Timer.fired();
    }

    event void AMControl.stopDone(error_t err) {}
	
    event void Timer.fired() {
	call RouteFinder.getNextHop( i , 35, TOS_NODE_ID );
/*
	testmsg_t *payloadptr;
	payloadptr = (testmsg_t*) call AMSend.getPayload(&messbuff, sizeof(testmsg_t));

	if (!payloadptr)
	    call Leds.set(0x7);
	else {
	    payloadptr->val1 = 6;
	    payloadptr->val2 = 18;
	    call AMSend.send(1, &messbuff, sizeof(testmsg_t));
	}
*/  }

    event void RouteFinder.nextHopFound( uint8_t nextHop, uint8_t msgId, uint8_t src, error_t ok ) {
	printf("%d -> %d :: %d\n", src, i++, nextHop);
	printfflush();
	if (i >= 10)
	    i = 0;
	call Timer.startOneShot(1000);
    }

    event void AMSend.sendDone(message_t *msg, error_t error) {}

    event message_t *Receiver.receive(message_t *msg, void *payload, uint8_t len) {
	checksummed_msg_t *msg_payload;
	msg_payload = (checksummed_msg_t*) msg->data;

	if (msg_payload->checksum)
	    printf("Message received: Valid checksum.\n");
	else 
	    printf("Message received: Invalid checksum.\n");
	printfflush();
	return msg;
    }
}
