#include "CAM.h"
#include "printf.h"

module CAMUnitTestC {
    uses {
	interface Boot;
	interface AMSend;
	interface Receive;
	interface Timer<TMilli> as Timer;
    }
}
implementation {
    message_t msgBuff;
    message_t *msgPtr;
    testmsg_t *payloadPtr;
    uint8_t i;
    
    event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len) {
	return msg;
    }

    event void Boot.booted() {
	msgPtr = &msgBuff;
	i = 0;
	signal Timer.fired();
    }

    event void Timer.fired() {
	payloadPtr = call AMSend.getPayload(msgPtr, sizeof(testmsg_t));
	if (!payloadPtr) {
	    printf("Payload get failed.\n");
	    printfflush();
	}
	
	printf("Requesting send to %d.", i);
	printfflush();

	call AMSend.send(i++, msgPtr, sizeof(testmsg_t));
	if (i > 10)
	    i = 0;
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
	printf("send done signalled.\n");
	printfflush();
	call Timer.startOneShot(1000);
    }
	

	
	
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
  }

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
	}*/
}
