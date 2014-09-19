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
	interface Timer<TMilli> as ListeningTimer;

	interface MsgQueue as RoutingQueue;
	interface MsgQueue as SendingQueue;
	interface MsgQueue as HeardQueue;
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
    message_t receiveBuffer;
    message_t* receiveBufferPtr;
    message_t heardBuffer;
    message_t compareBuffer;
    message_t timeoutBuffer;

    event error_t CAMUnit.initialise() {
	RoutingQueue.initialise();
	SendingQueue.initialise();
	ListeningQueue.initialise();
	receiveBufferPtr = &receiveBuffer;
    }

    task RoutingTask() { 
	message_t *popPtr;
	checksummed_msg_t *payload;

	if ( routingBusy )
	    return;
	routingBusy = TRUE;

	// pop and check atomically, to prevent failure to repost if
	// a msg is pushed onto queue between pop() and routingBusy = FALSE.
	atomic {
	    popPtr = routingQueue.pop();
	    if ( !popPtr ) {
		routingBusy = FALSE;
		return;
	    }
	}

	routingBuffer = *popPtr;
	payload = routingBuffer.data;

	call RouteFinder.getNextHop(payload->dest  , payload->ID , payload->src );
    }

    task SendingTask() { 
	message_t *popPtr;
	checksummed_msg_t *payload;

	if ( sendingBusy )
	    return;
	sendingBusy = TRUE;
	
	// pop and check atomically, to prevent failure to repost if
	// a msg is pushed onto queue between pop() and sendingBusy = FALSE.
	atomic {
	    popPtr = sendingQueue.pop();
	    if ( !popPtr ) {
		sendingBusy = FALSE;
		return;
	    }
	}

	sendingBuffer = *popPtr;
	payload = sendingBuffer.data;

	// TODO: What to do if subsend.send fails?
	call SubSend.send(payload->next, &sendingBuffer, sizeof(checksummed_msg_t));
    }

    task ListeningTask() {
	uint32_t alarmTime;
	uint32_t currentTime;

	if ( ListeningQueue.isEmpty() )
	    return;

	call ListeningTimer.stop();

	alarmTime = call ListeningQueue.getEarliestTime();

	// if alarm is due, signal timer straight away
	if ( inChronologicalOrder(alarmTime, currentTime) ) 
	    signal ListenTimer.fired();
	else 
	    call ListenTimer.startOneShot( alarmTime - currentTime );
    }

    task HeardTask() {
	checksummed_msg_t *newPayload;
	checksummed_msg_t *storedPayload;

	if ( HeardQueue.isEmpty() )
	    return;
	
	heardBuffer = *HeardQueue.pop();

	if ( ListeningQueue.isInQueue(&heardBuffer) ) {
	    compareBuffer = *ListeningQueue.removeMsg(&heardBuffer);

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
	
	ListeningQueue.insert(heardBuffer, CAM_EAVESDROPPING_TIMEOUT + call SysTime.get() );
	post ListeningTask();	
    }

    task void TimeoutTask() {
	checksummed_msg_t *payload;

	if ( TimeoutQueue.isEmpty() )
	    return;

	timeoutBuffer = timeoutQueue.pop();
	payload = (checksummed_msg_t*) timeoutBuffer.data;

	if ( HeardQueue.isInQueue(&timeoutBuffer) ) {
	    // BEWARE naughty shim code 
	    ListenQueue.insert(&timeoutBuffer);
	    post ListenTask();
	}

	// if sent by this node...
	if ( payload->curr == TOS_NODE_ID ) {
	    // if max retries, reroute
	    if ( payload->retry++ >= CAM_MAX_RETRIES ) {
		// TODO: add to blacklist
		call RoutingBuffer.push(&heardBuffer);
		post RoutingTask();
	    }

	    // if not max retries, resend
	    else {
		call SendingBuffer.push(&heardBuffer);
		post SendingTask();
	    } 
	}

	/* TODO: add reporting
	else {
	    // report packet drop?
	}
	*/
    }

    command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	if ( call RoutingQueue.isFull() )
	    return EBUSY;

	checksummed_msg_t *payload;

	payload = (checksummed_msg_t*) msg->data;

	payload->type = AMId;
	payload->len = len;
	payload->src = TOS_NODE_ID;
	payload->dest = addr;
	payload->prev = TOS_NODE_ID;
	payload->curr = TOS_NODE_ID;
	payload->next = TOS_NODE_ID;
	payload->ID = msgID++;
	payload->retries = 0;
	
	if ( call RoutingQueue.push(msg) == ENOMEM )
	    return EBUSY;

	post RoutingTask();

	return SUCCESS;
    }

    event void RouteFinder.nextHopFound( uint8_t next_id, uint8_t msg_ID, uint8_t src, error_t ok ) {
	checksummed_msg_t *payload = routingBuffer.data;

	if ( payload->retries == 0 ) {
	    payload->prev = payload->curr;
	    payload->curr = payload->next;
	    payload->next = next_id;
	}

	else {
	    payload->next = next_id;
	    payload->retries = 0;
	}

	// TODO - what to do if sendingqueue full?
	SendingQueue.push(&routingBuffer);
	post SendingTask();

	RoutingBusy = FALSE;

	if ( !RoutingQueue.isEmpty() )
	    post RoutingTask();
    }


    event void SubSend.sendDone(message_t *msg, error_t error) {
	checksummed_msg_t *payloadPtr = msg->data;

	// TODO: but what if it is b0rken?
	if ( error != SUCCESS ) {
	    call SubSend.send(payload->next, msg, sizeof(checksummed_msg_t));
	    return;
	}

	// set alarm for CAM_FWD_TIMEOUT ms in the future
	ListeningQueue.insert(msg, CAM_FWD_TIMEOUT + call Systime.get());
	
	sendingBusy = FALSE;

	if ( !SendingQueue.isEmpty() )
	    post SendingTask();
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {

	checksummed_msg_t *payloadPtr;

	payloadPtr = (checksummed_msg_t*) msg->data;
	
	// if message destination is this node, signal receive
	if (payloadPtr->dest == TOS_NODE_ID) {
	    // TODO: send ack
	    *receiveBufferPtr = *msg;
	    payloadPtr = (checksummed_msg_t*) receiveBuffer.data;

	    receiveBufferPtr = signal Receive.receive(msgptr, &(payloadPtr->data), payloadPtr->len);

	    return msg;
	}

	// else, route it
	// TODO: what to do if queue is full?
	call RoutingQueue.push(msg);
	post RoutingTask();
    }

    event void ListeningTimer.fired() {
	uint32_t alarmTime;
	message_t *popPtr;

	if ( ListeningQueue.isEmpty() )
	    return;

	alarmTime = call ListeningQueue.getEarliestTime();
	popPtr = call ListeningQueue.pop();
	
	TimeoutQueue.push(popPtr);

	post TimeoutTask();

	if ( !ListenQueue.isEmpty() )
	    post ListenTask();
    }

    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	// TODO: what to do if quue is full?
	HeardQueue.push(msg);
	
	post HeardTask();

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
}
