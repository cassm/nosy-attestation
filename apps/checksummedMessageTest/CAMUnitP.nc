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
	call Leds.set(0x7);

	cam_buffer_t *msgBuffer;
	checksummed_msg_t *payload;

	msgBuffer = sendBuffer.checkOutBuffer();
	
	if ( !msgBuffer )
	    return FAIL;

	msgBuffer->message = *msg;
	
	payload = msgBuffer->message.data;
	payload->type = AMId;
	payload->len = len;
	payload->src = TOS_NODE_ID;
	payload->dest = addr;
	payload->ID = msgID;
	
	sendBuffer.checkInBuffer(msgBuffer);

	RouteFinder.getNextHop(addr, msgID++, TOS_NODE_ID);
    
	return SUCCESS;
    }

    event void RouteFinder.nextHopFound( uint8_t next_id, uint8_t msg_ID, uint8_t src, error_t ok ) {
	cam_buffer_t *buffer;
	checksummed_msg_t *payload;

	buffer = sendBuffer.retrieveMsg(src, msg_ID);
	if (!buffer) {
	    call Leds.set(0x1);
	}
	else {
	    call SubSend.send(next_id, &(buffer->message), sizeof(checksummed_msg_t));
	}
    }

    event message_t *SubReceive.Receive(message_t *msg, void *payload, uint8_t len) {
	call Leds.set(0x6);
	// if this is a forward, overwrite the previous buffer
	// TODO: implement this

	// otherwise, use a new buffer
	cam_buffer_t *buffer;
	checksummed_msg_t *payload;
	message_t msgbuff;
	message_t *msgptr;
	msgptr = &msgbuff;

	// if message is for this node, copy into single buffer & signal receive
	if (payload->dest == TOS_NODE_ID) {
	    *msgptr = *msg;
	    payload = (checksummed_msg_t*) msgptr->data;
	    msgptr = signal Receive.receive(msgptr, &(payload->data), payload->len);
	}

	// otherwise, copy into sendBuffer and find a route
	else {	    
	    buffer = sendBuffer.checkoutBuffer();
	
	    if (!buffer) {
		call Leds.set(0x5);
	    }

	    else {
		buffer->message = *msg;
		payload = (checksummed_msg_t*) &(buffer->message.data);
		RouteFinder.getNextHop(payload->dest, payload->ID, payload->src);
		sendBuffer.checkInBuffer(buffer);
	    }
	}
    }
		
	    

    event void SubSend.sendDone(message_t *msg, error_t error) {
	cam_buffer_t *buffer;
	call Leds.set(0x0)

	buffer = sendBuffer.getMsgBuffer(msg);
	if (!buffer) {
	    call Leds.set(0x3);
	}
	else {
	    if (error == SUCCESS)
		call sendBuffer.releaseBuffer(buffer);
	    else
		// whevs
		// TODO - implement routefinder link healing
		call SubSend.send(next_id, &(buffer->message), sizeof(checksummed_msg_t));
	}
    }
	

    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	call Leds.set(0x4);
	call Timer.startOneShot(250);
	return msg;
    }

    event void Timer.fired() {
	call Leds.set(0x0);
    }
}
