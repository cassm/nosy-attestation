#include "CAM.h"
#include "printf.h"

module CAMUnitTestC {
    uses {
	interface Boot;
	interface AMSend;
	interface Receive;
	interface StdControl;
    }
}

implementation {
    event void Boot.booted() {
	call StdControl.start();
    }
    event void AMSend.sendDone(message_t* msg, error_t error) {}
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	return msg;
    }
}
    
	    
