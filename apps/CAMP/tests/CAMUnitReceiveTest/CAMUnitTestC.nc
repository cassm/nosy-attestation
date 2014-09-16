#include "CAM.h"
#include "printf.h"

module CAMUnitTestC {
    uses {
	interface Boot;
	interface AMSend;
	interface Receive;
	interface StdControl as ReceiveControl;
    }
}
implementation {
    message_t msgBuff;
    message_t *msgPtr;
    testmsg_t *payloadPtr;
    uint8_t i = 0;
    

    event void Boot.booted() {
	msgPtr = &msgBuff;
	call ReceiveControl.start();
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
    }
	
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	printf("Message received!\n");
	printfflush();
	return msg;
    }
}
