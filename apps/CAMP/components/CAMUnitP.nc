#include "CAM.h"
#include "printf.h"

module CAMUnitP {
    provides {
	interface AMSend;
	interface Receive;
	interface StdControl;
    }
    uses {
	interface AMSend as SubSend;
	interface Receive as SubReceive;
	interface Receive as Snoop;
	interface SplitControl as AMControl;
	interface Leds;
	interface Timer<TMilli> as ListeningTimer;
	interface Timer<TMilli> as LightTimer;

	interface MsgQueue as RoutingQueue;
	interface MsgQueue as SendingQueue;
	interface MsgQueue as HeardQueue;
	interface MsgQueue as ReceivedQueue;
	interface TimedMsgQueue as ListeningQueue;
	interface TimedMsgQueue as TimeoutQueue;

	interface Random;
	interface RouteFinder;
	interface LocalTime<TMilli> as SysTime;
    }
}

implementation {
    uint8_t msgID = 0;

    bool routingBusy = FALSE;
    bool sendingBusy = FALSE;

    message_t routingBuffer;
    message_t sendingBuffer;
    message_t receivedBuffer;
    message_t exitBuffer;
    message_t* exitBufferPtr;
    message_t heardBuffer;
    message_t compareBuffer;
    message_t timeoutBuffer;

    command error_t StdControl.start() {
	exitBufferPtr = &exitBuffer;
	call RoutingQueue.initialise();
	call SendingQueue.initialise();
	call HeardQueue.initialise();
	call ReceivedQueue.initialise();
	call ListeningQueue.initialise();
	call TimeoutQueue.initialise();
	call AMControl.start();
	return SUCCESS;	
    }

    event void AMControl.startDone(error_t err) {
	if (err != SUCCESS) {
	    call AMControl.start();
	}
    }

    event void AMControl.stopDone(error_t err) {
	// do nothing
    }

    command error_t StdControl.stop() {}

    void printPacket(message_t* msg) {
	checksummed_msg_t *payload = (checksummed_msg_t*) msg->data;

	printf("S: %d | D: %d | P: %d | C: %d | N: %d\n", 
	       payload->src,
	       payload->dest,
	       payload->prev,
	       payload->curr,
	       payload->next);
	printfflush();
    }

    task void RoutingTask() { 
	message_t *popPtr;
	checksummed_msg_t *payload;

	if ( call RoutingQueue.isEmpty() )
	    return;

	if ( routingBusy )
	    return;
	routingBusy = TRUE;

	// pop and check atomically, to prevent failure to repost if
	// a msg is pushed onto queue between pop() and routingBusy = FALSE.
	atomic {
	    popPtr = call RoutingQueue.pop();
	    if ( !popPtr ) {
		routingBusy = FALSE;
		return;
	    }
	}

	routingBuffer = *popPtr;
	payload = (checksummed_msg_t*) routingBuffer.data;

	call RouteFinder.getNextHop(payload->dest  , payload->ID , payload->src );
    }

    task void SendingTask() { 
	message_t *popPtr;
	checksummed_msg_t *payload;

	printf("SendingTask\n");
	printfflush();

	if ( call SendingQueue.isEmpty() )
	    return;

	if ( sendingBusy )
	    return;
	sendingBusy = TRUE;
	
	// pop and check atomically, to prevent failure to repost if
	// a msg is pushed onto queue between pop() and sendingBusy = FALSE.
	atomic {
	    popPtr = call SendingQueue.pop();
	    if ( !popPtr ) {
		sendingBusy = FALSE;
		return;
	    }
	}

	sendingBuffer = *popPtr;
	payload = (checksummed_msg_t*) sendingBuffer.data;

	// TODO: What to do if subsend.send fails?
	printf("SubSending to %d.\n", payload->next);

	if ( call SubSend.send(payload->next, &sendingBuffer, sizeof(checksummed_msg_t)) != SUCCESS ) {
	    call SendingQueue.push(&sendingBuffer);
	    sendingBusy = FALSE;
	    printf("Send failed, retrying...\n");
	    printfflush();
	    post SendingTask();
	}
	else {
	    printf("Send successful\n");
	    printfflush();
	}
    }

    task void ListeningTask() {
	uint32_t alarmTime;
	uint32_t currentTime;

	if ( call ListeningQueue.isEmpty() )
	    return;

	call ListeningTimer.stop();

	currentTime = call SysTime.get();
	alarmTime = call ListeningQueue.getEarliestTime();

	// if alarm is due, signal timer straight away
	if ( inChronologicalOrder(alarmTime, currentTime) ) 
	    signal ListeningTimer.fired();
	else 
	    call ListeningTimer.startOneShot( alarmTime - currentTime );
    }

    task void HeardTask() {
	checksummed_msg_t *newPayload;
	checksummed_msg_t *storedPayload;

	if ( call HeardQueue.isEmpty() )
	    return;
	
	heardBuffer = *call HeardQueue.pop();

	if ( call ListeningQueue.isInQueue(&heardBuffer) ) {
	    compareBuffer = *call ListeningQueue.removeMsg(&heardBuffer);

	    newPayload = (checksummed_msg_t*) heardBuffer.data;
	    storedPayload = (checksummed_msg_t*) compareBuffer.data;

	    // TODO: add checking
	    // TODO: add rangefinding
	    // TODO: add reporting
	    /*
	    if ( newpayload->curr == storedPayload->curr && newPayload->ID == storedPayload->ID ) {
		// message is a retry
		
		if ( storedPayload->retry == CAM_MAX_RETRIES ) {
		    // message should be a reroute

		    // expect next node to be different
		    if ( storedPayload->next == newPayload->next ) {
			// do some kind of report
		    }
		}
		else {
		    // message should be a retry
		    if ( newPayload->retry != storedPayload->retry + 1 ) {
			// do some kind of report
		    }

		    if ( storedPayload->next != newPayload->next ) {
			// do some kind of report
		    }
		}
	    }

	    else {
		// expect forward. do the rest of the checking here
	    }
	    */
	}
	
	call ListeningQueue.insert(&heardBuffer, CAM_EAVESDROPPING_TIMEOUT + call SysTime.get() );
	post ListeningTask();	
    }

    task void TimeoutTask() {
	checksummed_msg_t *payload;

	if ( call TimeoutQueue.isEmpty() )
	    return;

	timeoutBuffer = *call TimeoutQueue.pop();
	payload = (checksummed_msg_t*) timeoutBuffer.data;

	if ( call HeardQueue.isInQueue(&timeoutBuffer) ) {
	    // BEWARE naughty shim code 
	    call ListeningQueue.insert(&timeoutBuffer, CAM_EAVESDROPPING_TIMEOUT * call SysTime.get());
	    post ListeningTask();
	}

	// if sent by this node...
	if ( payload->curr == TOS_NODE_ID ) {
	    // if max retries, reroute
	    if ( payload->retry++ >= CAM_MAX_RETRIES ) {
		// TODO: add to blacklist
		printf("Send to %d failed. Aborting..\n", payload->next);
		printfflush();
//		call RoutingQueue.push(&heardBuffer);
//		post RoutingTask();
	    }

	    // if not max retries, resend
	    else {
		printf("Send to %d failed. Retrying (attempt %d of 3).\n", payload->next, payload->retry);
		printfflush();
		call SendingQueue.push(&timeoutBuffer);
		post SendingTask();
	    } 
	}

	// TODO: add reporting
	else {
	    printf("Send from %d to %d failed.\n", payload->curr, payload->next);
	    printfflush();
	}
	
    }

    task void ReceivedTask() {
	checksummed_msg_t *payload;

	printf("ReceivedTask\n");
	printfflush();

	if ( call ReceivedQueue.isEmpty() )
	    return;

	receivedBuffer = *call ReceivedQueue.pop();
	*exitBufferPtr = receivedBuffer;

	payload = (checksummed_msg_t*) receivedBuffer.data;
	
	payload->retry = 0;

	// send ack
	payload->prev = payload->curr;
	payload->curr = TOS_NODE_ID;
	payload->next = (uint8_t) AM_BROADCAST_ADDR;

	call SendingQueue.push(&receivedBuffer);
	post SendingTask();
	
	payload = (checksummed_msg_t*) exitBufferPtr->data;
	
	// signal receive
	printf("Signalling receive\n");
	printfflush();
	exitBufferPtr = signal Receive.receive(exitBufferPtr, &(payload->data), payload->len);

	if ( !call ReceivedQueue.isEmpty() )
	    post ReceivedTask();
    }

    command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	checksummed_msg_t *payload;

	call Leds.set(0x7);
	call LightTimer.startOneShot(250);

	if ( call RoutingQueue.isFull() )
	    return EBUSY;

	payload = (checksummed_msg_t*) msg->data;

	printf("Send to %d requested.\n", addr);
	printfflush();

	payload->ID = msgID++;
	payload->retry = 0;
	
	if ( call RoutingQueue.push(msg) == ENOMEM )
	    return EBUSY;

	post RoutingTask();

	signal AMSend.sendDone(msg, SUCCESS);

	return SUCCESS;
    }

    event void RouteFinder.nextHopFound( uint8_t next_id, uint8_t msg_ID, uint8_t src, error_t ok ) {
	checksummed_msg_t *payload = (checksummed_msg_t*) routingBuffer.data;

	if ( payload->retry == 0 ) {
	    payload->prev = payload->curr;
	    payload->curr = payload->next;
	    payload->next = next_id;
	}

	else {
	    payload->next = next_id;
	    payload->retry = 0;
	}

	// TODO - what to do if sendingqueue full?
	call SendingQueue.push(&routingBuffer);
	post SendingTask();

	routingBusy = FALSE;

	if ( !call RoutingQueue.isEmpty() )
	    post RoutingTask();
    }


    event void SubSend.sendDone(message_t *msg, error_t error) {
	checksummed_msg_t *payload = (checksummed_msg_t*) msg->data;

	// if this is not an ack
	if ( payload->dest != TOS_NODE_ID ) {
	    // TODO: but what if it is b0rken?
	    if ( error != SUCCESS ) {
		call SubSend.send(payload->next, msg, sizeof(checksummed_msg_t));
		return;
	    }

	    // set alarm for CAM_FWD_TIMEOUT ms in the future
	    call ListeningQueue.insert(msg, CAM_FWD_TIMEOUT + call SysTime.get());
	    post ListeningTask();
	
	}

	sendingBusy = FALSE;

	if ( !call SendingQueue.isEmpty() )
	    post SendingTask();
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
	checksummed_msg_t *payloadPtr;

	payloadPtr = (checksummed_msg_t*) msg->data;

	printf("Message for %d  subreceived\n", payloadPtr->dest);
	printPacket(msg);
	call Leds.set(0x3);
	call LightTimer.startOneShot(250);

	// don't listen for this any more
	call ListeningQueue.removeMsg(msg);
	post ListeningTask();

	// TODO: What to do if queue is full?
	// if the message is for this node, receive it
	if ( payloadPtr->dest == TOS_NODE_ID ) {
	    call ReceivedQueue.push(msg);
	    post ReceivedTask();
	    return msg;
	}

	// if message is an ack, process it
	if ( payloadPtr->dest == payloadPtr->curr ) {
	    call ListeningQueue.removeMsg(msg);
	    post ListeningTask();
	    return msg;
	}
	
	printf("Forwarding...\n");
	printfflush();

	// otherwise, forward it
     
	// TODO: what to do if queue is full?
	call RoutingQueue.push(msg);
	post RoutingTask();
	return msg;
    }

    event void ListeningTimer.fired() {
	uint32_t alarmTime;
	message_t *popPtr;

	if ( call ListeningQueue.isEmpty() )
	    return;

	alarmTime = call ListeningQueue.getEarliestTime();
	popPtr = call ListeningQueue.pop();
	
	call TimeoutQueue.insert(popPtr, alarmTime);

	post TimeoutTask();

	if ( !call ListeningQueue.isEmpty() )
	    post ListeningTask();
    }

    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	checksummed_msg_t *payloadPtr;

//	printf("Snoop.receive\n");
//	printPacket(msg);

	// TODO: what to do if quue is full?
	call Leds.set(0x1);
	call LightTimer.startOneShot(250);

	payloadPtr = (checksummed_msg_t*) payload;

	// process acks
	if ( payloadPtr->dest == payloadPtr->curr ) {
	    printf("Delivery of message from %d to %d acknowledged.\n", payloadPtr->src, payloadPtr->dest);
	    printfflush();
	    call ListeningQueue.removeMsg(msg);
	    post ListeningTask();
	}

	// if not ack, listen for as normal
	else {
	    call HeardQueue.push(msg);
	    post HeardTask();
	}

	return msg;
    }

    //==================================================================

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

    event void LightTimer.fired() {
	call Leds.set(0);
    }
}
