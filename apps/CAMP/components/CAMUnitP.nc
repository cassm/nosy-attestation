#include "CAM.h"
#include "printf.h"

generic module CAMUnitP(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
    }
    uses {
	interface AMSend as SubSend;
	interface Receive as SubReceive;
	interface Receive as Snoop;
	interface Leds;
	interface Timer<TMilli> as Timer;
	interface Timer<TMilli> as LightTimer;
	interface CAMBuffer as SendBuffer;
	interface Random;
	interface RouteFinder;
    }
}

implementation {
    uint8_t msgID = 0; // TODO: this needs to be randomised
    bool busySending = FALSE;
    message_t sentBuff;

    command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	cam_buffer_t *msgBuffer;
	checksummed_msg_t *payload;

	call Leds.set(0x7);
	call LightTimer.startOneShot(1000);
	if (busySending)
	    return EBUSY;
	busySending = TRUE;

	printf("Send to %d requested.\n", addr);
	printfflush();

	msgBuffer = call SendBuffer.checkOutBuffer();
	
	if ( !msgBuffer ) {
	    printf("Buffer get failed.");
	    printfflush();
	    return FAIL;
	}

	msgBuffer->message = *msg;
	msgBuffer->retries = 0;
	
	payload = (checksummed_msg_t*) msgBuffer->message.data;
	payload->type = AMId;
	payload->len = len;
	payload->src = TOS_NODE_ID;
	payload->dest = addr;
	payload->ID = msgID;
	
	call SendBuffer.checkInBuffer(msgBuffer);

	call RouteFinder.getNextHop(addr, msgID++, TOS_NODE_ID);
    
	return SUCCESS;
    }

    event void RouteFinder.nextHopFound( uint8_t next_id, uint8_t msg_ID, uint8_t src, error_t ok ) {
	cam_buffer_t *buffer;
	checksummed_msg_t *payload;

	buffer = call SendBuffer.retrieveMsg(src, msg_ID);
	if (!buffer) {
	    printf("Message retrieval failed.\n");
	    printfflush();
	}
	else {
	    call SubSend.send(next_id, &(buffer->message), sizeof(checksummed_msg_t));
	}
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {

	// if this is a forward, overwrite the previous buffer
	// TODO: implement this

	// otherwise, use a new buffer
	cam_buffer_t *buffer;
	checksummed_msg_t *payloadPtr;
	message_t msgbuff;
	message_t *msgptr;
	msgptr = &msgbuff;

	payloadPtr = (checksummed_msg_t*) msg->data;
	
	printf("SubReceive has received a message for %d.\n", payloadPtr->dest);
	printfflush();
	// if message is for this node, copy into single buffer & signal receive
	if (payloadPtr->dest == TOS_NODE_ID) {
	    call Leds.set(0x7);
	    call LightTimer.startOneShot(1000);
	    *msgptr = *msg;
	    payloadPtr = (checksummed_msg_t*) msgptr->data;
	    msgptr = signal Receive.receive(msgptr, &(payloadPtr->data), payloadPtr->len);
	}

	// otherwise, copy into SendBuffer and find a route
	else {	    
	    buffer = call SendBuffer.checkOutBuffer();
	    call Leds.set(0x3);
	    call LightTimer.startOneShot(1000);

	    if (!buffer) {
		printf("Buffer get for forwarding failed.\n");
		printfflush();
	    }

	    else {
		buffer->message = *msg;
		payloadPtr = (checksummed_msg_t*) &(buffer->message.data);
		call RouteFinder.getNextHop(payloadPtr->dest, payloadPtr->ID, payloadPtr->src);
		call SendBuffer.checkInBuffer(buffer);
	    }
	}
	return msgptr;
    }
		
	    

    event void SubSend.sendDone(message_t *msg, error_t error) {
	cam_buffer_t *buffer;
	checksummed_msg_t *payloadPtr;
	sentBuff = *msg;

	buffer = call SendBuffer.getMsgBuffer(msg);
	if (!buffer) {
	    printf("Senddone message buffer retrieval failed.\n");
	    printfflush();
	}
	else {
	    if (error == SUCCESS) {
		call SendBuffer.releaseBuffer(buffer);
		signal AMSend.sendDone(&sentBuff, SUCCESS);
		busySending = FALSE;
		printf("\n");
		printfflush();
	    }
	    else {
		// TODO - implement routefinder link healing
		if (buffer->retries++ > CAM_MAX_RETRIES) {
		    call SendBuffer.releaseBuffer(buffer);
		    signal AMSend.sendDone(&sentBuff, FAIL);
		    busySending = FALSE;
		}
		else		    
		    call RouteFinder.getNextHop(payloadPtr->dest, payloadPtr->ID, payloadPtr->src);
	    }
	}
    }

    command uint8_t AMSend.maxPayloadLength() {
	return MAX_PAYLOAD;
    }

    command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	checksummed_msg_t* payload;

	if (len > MAX_PAYLOAD)
	    return NULL;
	else {
	    payload = (checksummed_msg_t*) msg->data;
	    return payload->data;
	}
    }

    command error_t AMSend.cancel(message_t* msg) {
	return call SubSend.cancel(msg);
    }	

    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	call Leds.set(0x1);
	call Timer.startOneShot(1000);
	return msg;
    }

    event void Timer.fired() {
	call Leds.set(0x0);
    }

    event void LightTimer.fired() {
	call Leds.set(0x0);
    }
}