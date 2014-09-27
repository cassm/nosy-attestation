#include "CAM.h"
#include "printf.h"

module CAMUnitP {
    provides {
	interface AMSend;
	interface CAMReceive;
	interface SplitControl;
    }
    uses {
	interface AMSend as SubSend;
	interface AMSend as ReportSend;
	interface AMSend as DigestSend;
	interface Receive as SubReceive;
	interface Receive as DigestReceive;
	interface Receive as Snoop;
	interface SplitControl as AMControl;
	interface SplitControl as LinkSplitControl;
	interface SplitControl as AODVControl;
	interface Leds;
	interface Timer<TMilli> as ListeningTimer;
	interface Timer<TMilli> as LightTimer;

	interface MsgQueue as RoutingQueue;
	interface MsgQueue as SendingQueue;
	interface MsgQueue as HeardQueue;
	interface MsgQueue as ReceivedQueue;
	interface MsgQueue as ReportingQueue;
	interface MsgQueue as ValidationQueue;
	interface TimedMsgQueue as ListeningQueue;
	interface TimedMsgQueue as TimeoutQueue;

	interface LinkStrengthLog;
	interface LinkControl;
	interface Random;
	interface RouteFinder;
	interface LocalTime<TMilli> as SysTime;
    }
}

implementation {
    uint8_t msgID = 0;

    bool routingBusy = FALSE;
    bool sendingBusy = FALSE;
    bool reportingBusy = FALSE;
    bool validationBusy = FALSE;

    message_t routingBuffer;
    message_t sendingBuffer;
    message_t receivedBuffer;
    message_t exitBuffer;
    message_t* exitBufferPtr;
    message_t heardBuffer;
    message_t compareBuffer;
    message_t timeoutBuffer;
    message_t digestBuffer;
    message_t analysisBuffer;
    message_t reportingBuffer;
    message_t validationBuffer;

    task void ReportingTask();

    command error_t SplitControl.start() {
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
	else {
	    call AODVControl.start();
	}
    }

    event void AODVControl.startDone(error_t err) {
	if (err != SUCCESS) {
	    call AODVControl.start();
	}
	else {
	    call LinkSplitControl.start();
	}
    }

    event void LinkSplitControl.startDone(error_t err) {
	if (err != SUCCESS) {
	    call LinkSplitControl.start();
	}
	else {
	    signal SplitControl.startDone(SUCCESS);
	}
    }

    event void AMControl.stopDone(error_t err) {
	// do nothing
    }
    event void AODVControl.stopDone(error_t err) {
	// do nothing
    }
    event void LinkSplitControl.stopDone(error_t err) {
	// do nothing
    }

    command error_t SplitControl.stop() {}

    

    error_t buildDigest(message_t* target, message_t *output) {
        cc2420_header_t *header;
	checksummed_msg_t *payload;
	msg_digest_t *digest;

	header = &((message_header_t*)target->header)->cc2420;
	payload = (checksummed_msg_t*) target->data;
	digest = (msg_digest_t*) output->data;

	digest->reporter = TOS_NODE_ID;

	digest->h_src = header->src;
	digest->h_dest = header->dest;
	digest->h_len = header->length;

	digest->src = payload->src;
	digest->prev = payload->prev;
	digest->curr = payload->curr;
	digest->next = payload->next;
	digest->dest = payload->dest;

	digest->type = payload->type;
	digest->id = payload->ID;
	digest->len = payload->len;

	// manually set header type on output
	header = &((message_header_t*)output->header)->cc2420;
	header->type = DIGESTMSG;

	return SUCCESS; 
    }

    error_t buildReport(message_t *target, message_t *output) {	
        cc2420_header_t *header;
	cc2420_metadata_t *metadataPtr;

	checksummed_msg_t *payload;
	message_t *bufferedMsg;
	checksummed_msg_t* bufferedPayload;
	
	msg_report_t *report = (msg_report_t*) output->data;
	payload = (checksummed_msg_t*) target->data;

	metadataPtr = &((message_metadata_t*)target->metadata)->cc2420;

	buildDigest(target, &digestBuffer);

	// ================ INTERNAL CONSISTENCY CHECKS ================

	// get lqi
	report->analytics.lqi = metadataPtr->lqi;

	// copy digest into report
	memcpy(&report->digest, &digestBuffer.data, sizeof(msg_digest_t));
	
	// check AM header against CAM header
	report->analytics.headers_agree = ( report->digest.h_src == report->digest.curr
					    && report->digest.h_dest == report->digest.next );
	
	// sanity check the lengths in the AM and CAM headers
	report->analytics.valid_len = ( report->digest.h_len <= TOSH_DATA_LENGTH
					&& report->digest.len <= MAX_PAYLOAD );

	// check whether the LQI of the received message is within the bounds of what we would expect
	report->analytics.anomalous_lqi = ( call LinkStrengthLog.getLqiDiff(target) >= LQI_DIFF_THRESHOLD );
    
	// see if we have heard from this mote before
	report->analytics.first_time_heard = ( call LinkStrengthLog.getLqi(payload->curr) == 0 );
	
	// see if the checksum is valid
	report->analytics.checksum_correct = ( payload->checksum == checksum_msg(target) );

	// is that you, John Wayne?
	report->analytics.impersonating_me = ( header->src == TOS_NODE_ID );

	// ===================== CONTINUITY CHECKS =====================

	// perform the following checks if the message is being listened for
	bufferedMsg = call ListeningQueue.inspectMsg(target);
	if ( bufferedMsg != NULL ) {
	    bufferedPayload = (checksummed_msg_t*) bufferedMsg->data;
	    
	    // see if checksum matches buffered checksum
	    if ( payload->checksum == bufferedPayload->checksum )
		report->analytics.checksum_matches = GOOD;
	    else
		report->analytics.checksum_matches = BAD;

	    // see if payloads are the same
	    if ( memcmp(&(payload->data), &(bufferedPayload->data), MAX_PAYLOAD) )
		report->analytics.payload_matches = BAD;
	    else
		report->analytics.payload_matches = GOOD;
	}

	// otherwise, set both values to UNKNOWN
	else {
	    report->analytics.checksum_matches = UNKNOWN;
	    report->analytics.payload_matches = UNKNOWN;
	}

	// ====================== ROUTING CHECKS =======================

	// check routing against cached routing information
	report->analytics.valid_routing = call RouteFinder.checkRouting(payload);

	// check link validity against cached link permissions
	report->analytics.link_status = call LinkControl.isPermitted(payload->curr, payload->next);

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

	// manually set header type on output
	header = &((message_header_t*)output->header)->cc2420;
	header->type = REPORTMSG;

	return SUCCESS; 
    }

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
/*
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
*/
    task void SendingTask() { 
	message_t *popPtr;
	checksummed_msg_t *payload;

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
	checksummed_msg_t *payload;
	uint8_t linkStatus;

	if ( call HeardQueue.isEmpty() )
	    return;
	
	heardBuffer = *call HeardQueue.pop();

	if ( call ListeningQueue.isInQueue(&heardBuffer) ) {
	    compareBuffer = *call ListeningQueue.removeMsg(&heardBuffer);
	}

	payload = (checksummed_msg_t*) heardBuffer.data;

	linkStatus = call LinkControl.isPermitted(payload->curr, payload->next);

        // TODO: deal better with link permissions log desynchronisation

	// expect permitted links to be forwarded immediately
	if ( linkStatus == PERMITTED  ) {
	    call ListeningQueue.insert(&heardBuffer, CAM_EAVESDROPPING_TIMEOUT + call SysTime.get() );
	    post ListeningTask();
	}

	// expect unknown links to take a while
	if ( linkStatus == UNKNOWN && FWD_UNKNOWN_LINKS ) {
	    call ListeningQueue.insert(&heardBuffer, LINK_VALIDATION_TIMEOUT + CAM_FWD_TIMEOUT + call SysTime.get() );
	    post ListeningTask();
	}
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

	else {
	    // report on msg drop
	    buildDigest(&timeoutBuffer, &digestBuffer);
	    call ReportingQueue.push(&digestBuffer);
	    post ReportingTask();

	    printf("Send from %d to %d failed.\n", payload->curr, payload->next);
	    printfflush();
	}
    }

    task void ReceivedTask() {
	checksummed_msg_t *payload;

	if ( call ReceivedQueue.isEmpty() )
	    return;

	receivedBuffer = *call ReceivedQueue.pop();

	payload = (checksummed_msg_t*) receivedBuffer.data;
	
	payload->retry = 0;

	// send ack
	payload->prev = payload->curr;
	payload->curr = TOS_NODE_ID;
	payload->next = (uint8_t) AM_BROADCAST_ADDR;

	call SendingQueue.push(&receivedBuffer);
	post SendingTask();
	
	// signal receive
	printf("Signalling receive\n");
	printfflush();
        signal CAMReceive.receive(&receivedBuffer, &(payload->data), payload->len);

	if ( !call ReceivedQueue.isEmpty() )
	    post ReceivedTask();
    }

    task void ReportingTask() {
	cc2420_header_t *header;
        msg_digest_t *digestptr;

	if ( call ReportingQueue.isEmpty() )
	    return;

	if ( reportingBusy )
	    return;
	reportingBusy = TRUE;

	reportingBuffer = *call ReportingQueue.pop();
	header = &((message_header_t*)reportingBuffer.header)->cc2420;
	
	// report is for a dropped message
	if ( header->type == DIGESTMSG && REPORT_DROPS ) {
	    digestptr = (msg_digest_t*) reportingBuffer.data;
	    if ( digestptr->next != 0 )
		call DigestSend.send(BASE_STATION_ID, &reportingBuffer, sizeof(msg_digest_t));
	    return;
	}

	// report is for a snooped or received message
	else if ( header->type == REPORTMSG ) {

	    // TODO: implement filtering here
	    if ( FALSE ) {
		call ReportSend.send(BASE_STATION_ID, &reportingBuffer, sizeof(msg_report_t));
		return;
	    }
	}

	// if control reaches here, no report has been sent
	reportingBusy = FALSE;

	if ( !call ReportingQueue.isEmpty() )
	    post ReportingTask();
    }

    event void ReportSend.sendDone(message_t *msg, error_t error) {
	if ( error != SUCCESS )
	    call ReportSend.send(BASE_STATION_ID, &reportingBuffer, sizeof(msg_report_t));
	else {
	    reportingBusy = FALSE;
	    if ( !call ReportingQueue.isEmpty() )
		post ReportingTask();
	}
    }

    event void DigestSend.sendDone(message_t *msg, error_t error) {
	if ( error != SUCCESS )
	    call DigestSend.send(BASE_STATION_ID, &reportingBuffer, sizeof(msg_report_t));
	else {
	    reportingBusy = FALSE;
	    if ( !call ReportingQueue.isEmpty() )
		post ReportingTask();
	}
    }

    task void validationTask() {
	checksummed_msg_t *payload;

	if ( call ValidationQueue.isEmpty() )
	    return;
	if ( validationBusy ) 
	    return;
	validationBusy = TRUE;

	printf("Requesting validation\n");
	printfflush();

	validationBuffer = *call ValidationQueue.pop();
	payload = (checksummed_msg_t*) validationBuffer.data;

	call LinkControl.validateLink(payload->curr, payload->next);
    }

    event void LinkControl.validationDone( uint8_t src, uint8_t dest, uint8_t status ) {
	checksummed_msg_t *payloadPtr = (checksummed_msg_t*) validationBuffer.data;

	printf("Validation done: %d\n", status);
	printfflush();

	if ( status == PERMITTED || ( status == UNKNOWN && FWD_UNKNOWN_LINKS ) ) {
	    // TODO: What to do if queue is full?
	    // if the message is for this node, receive it
	    if ( payloadPtr->dest == TOS_NODE_ID ) {
		call ReceivedQueue.push(&validationBuffer);
		post ReceivedTask();
		return;
	    }

	    // if message is an ack, process it
	    if ( payloadPtr->dest == payloadPtr->curr ) {
		call ListeningQueue.removeMsg(&validationBuffer);
		post ListeningTask();
		return;
	    }

	    // otherwise, forward it
     
	    // TODO: what to do if queue is full?
	    call RoutingQueue.push(&validationBuffer);
	    call RouteFinder.getNextHop( dest );
	}
	post validationTask();
    }

    command error_t AMSend.send(am_addr_t addr, message_t *msg, uint8_t len) {
	checksummed_msg_t *payload;
        cc2420_header_t *header;

	call Leds.set(0x7);
	call LightTimer.startOneShot(250);

	if ( call RoutingQueue.isFull() )
	    return EBUSY;

	if ( addr == TOS_NODE_ID ) {
	    // stop hitting yourself
	    return EALREADY;
	}

	payload = (checksummed_msg_t*) msg->data;

	payload->src = TOS_NODE_ID;
	payload->prev = TOS_NODE_ID;
	payload->curr = TOS_NODE_ID;
	payload->next = TOS_NODE_ID;
	payload->dest = addr;

	// manually set header type
     	header = &((message_header_t*)msg->header)->cc2420;

	printf("Send to %d requested. Type = %d/%d\n", addr, payload->type, header->type);
	printfflush();

	header->type = CAMMSG;

	payload->ID = msgID++;
	payload->retry = 0;
	
	payload->checksum = checksum_msg(msg);

	if ( call RoutingQueue.push(msg) == ENOMEM )
	    return EBUSY;

	call RouteFinder.getNextHop( addr );

	signal AMSend.sendDone(msg, SUCCESS);

	return SUCCESS;
    }

    event void RouteFinder.nextHopFound( uint8_t nextHop, uint8_t dest ) {
	message_t *routingPtr = call RoutingQueue.getByDest(dest);

	printf("Next hop to %d found: %d\n", dest, nextHop);
	printfflush();

	while ( routingPtr != NULL ) {
	    checksummed_msg_t *payload = (checksummed_msg_t*) routingPtr->data;
 
	    // if this is the first attempt at sending this message from this node
	    // set all the routing information
	    if ( payload->retry == 0 ) {
		payload->prev = payload->curr;
		payload->curr = payload->next;
		payload->next = nextHop;
	    }

	    // otherwise, just change the next node
	    else {
		payload->next = nextHop;
		payload->retry = 0;
	    }

	    // TODO - what to do if sendingqueue full?
	    call SendingQueue.push(routingPtr);
	    routingPtr = call RoutingQueue.getByDest(dest);
	}

	post SendingTask();
    }


    event void SubSend.sendDone(message_t *msg, error_t error) {
	uint8_t linkStatus;
	checksummed_msg_t *payload = (checksummed_msg_t*) msg->data;

	linkStatus = call LinkControl.isPermitted(payload->curr, payload->next);

	// if this is not an ack
	if ( payload->dest != TOS_NODE_ID ) {
	    // TODO: but what if it is b0rken?
	    if ( error != SUCCESS ) {
		call SubSend.send(payload->next, msg, sizeof(checksummed_msg_t));
		return;
	    }

  	    // set alarm for CAM_FWD_TIMEOUT ms in the future
	    if ( linkStatus == UNKNOWN ) {
		call ListeningQueue.insert(msg, LINK_VALIDATION_TIMEOUT + CAM_FWD_TIMEOUT + call SysTime.get());
	    }

	    else if ( linkStatus == PERMITTED ) {
		call ListeningQueue.insert(msg, CAM_FWD_TIMEOUT + call SysTime.get());
	    }

	    post ListeningTask();
	
	}

	sendingBusy = FALSE;

	if ( !call SendingQueue.isEmpty() )
	    post SendingTask();
    }

    event message_t *DigestReceive.receive(message_t *msg, void *payload, uint8_t len) {
	msg_digest_t *payloadPtr = (msg_digest_t*) msg->data;

	if ( TOS_NODE_ID == 0 ) {
	    printf("Report: %d reports message dropped between %d and %d.\n", payloadPtr->reporter, payloadPtr->curr, payloadPtr->next);
	    printfflush();
	}
	return msg;
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
	checksummed_msg_t *payloadPtr;
	uint8_t linkStatus;

	payloadPtr = (checksummed_msg_t*) msg->data;

	printf("Message for %d  subreceived\n", payloadPtr->dest);
	printPacket(msg);
	call Leds.set(0x3);
	call LightTimer.startOneShot(250);

	// report on msg
	// TODO: block dangerous messages here
	buildReport(msg, &analysisBuffer);
	call ReportingQueue.push(&analysisBuffer);
	post ReportingTask();

	call LinkStrengthLog.update(msg);

	// don't listen for this any more
	call ListeningQueue.removeMsg(msg);
	post ListeningTask();

	linkStatus = call LinkControl.isPermitted(payloadPtr->curr, payloadPtr->next);

	// allow all link validation messages from base
	if (linkStatus == PERMITTED || (payloadPtr->curr == 0 && payloadPtr->type == LINKVALMSG) || TOS_NODE_ID == 0) {

	    printf("Link permitted\n");
	    printfflush();
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
	    call RouteFinder.getNextHop(payloadPtr->dest);
	    return msg;
	}

	else if ( linkStatus == UNKNOWN ) {
	    printf("Link unknown\n");
	    printfflush();

	    call ValidationQueue.push(msg);
	    post validationTask();
	    return msg;
	}

	else {
	    printf("Link forbidden\n");
	    printfflush();
	}

	// if link status is forbidden, drop packet.
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
        cc2420_header_t *header;

//	printf("Snoop.receive\n");
//	printPacket(msg);

	// TODO: what to do if queue is full?
	call Leds.set(0x1);
	call LightTimer.startOneShot(250);

	payloadPtr = (checksummed_msg_t*) payload;

	header = &((message_header_t*)msg->header)->cc2420;

	// report on msg
	// TODO; block dangerous messages here
	buildReport(msg, &analysisBuffer);
	call ReportingQueue.push(&analysisBuffer);
	post ReportingTask();

	call LinkStrengthLog.update(msg);

	// process acks
	if ( payloadPtr->dest == AM_BROADCAST_ADDR || (payloadPtr->dest == payloadPtr->curr && header->type == CAMMSG) ) {
	    printf("Delivery of type %d message from %d to %d acknowledged.\n", payloadPtr->type, payloadPtr->src, payloadPtr->dest);
	    printf("Header details: %d -> %d : %d\n", header->src, header->dest, header->type);
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
