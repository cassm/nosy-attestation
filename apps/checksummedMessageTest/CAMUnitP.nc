#include "CAM.h"

generic module CAMUnitP(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
    uses {
	interface AMSend as SubSend;
	interface Receive as SubReceive;
	interface Receive as Snoop;
	interface Leds;
	interface Timer<TMilli> as Timer;
	interface CAMBuffer as SendBuffer;
	interface Random;
	interface RouteFinder;
    }
}

implementation {
    uint8_t msgID = (uint8_t) Random.rand16();

    command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	message_t *msgBuffer;
	checksummed_msg_t *payload;

	msgBuffer = sendBuffer.checkOutBuffer();
	
	if ( !msgBuffer )
	    return FAIL;

	msgBuffer = *msg;
	
	payload = msgBuffer->data;
	payload->type = AMId;
	payload->len = len;
	payload->dest = addr;
	payload->ID = msgID;
	
	sendBuffer.checkInBuffer(msgBuffer);

	RouteFinder.getNextHop(addr, msgID++);
    
	return SUCCESS;
    }

    event void

    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	call Leds.set(0x7);
	call Timer.startOneShot(1000);
	return msg;
    }

    event void Timer.fired() {
	call Leds.set(0x0);
    }
}
