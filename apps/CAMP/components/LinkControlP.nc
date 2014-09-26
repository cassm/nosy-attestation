#include "CAM.h"
#include "printf.h"

module LinkControlP {
    provides {
	interface LinkControl;
	interface SplitControl;
    }
   
    uses {
	interface AMSend;
	interface Receive;

	interface Leds;

	interface AMSend as BeaconSend;
	interface Receive as BeaconReceive;
	interface AMSend as BeaconUpdateSend;
	interface Receive as BeaconUpdateReceive;
	interface Timer<TMilli> as BeaconTimer;
	interface Timer<TMilli> as BeaconPhaseTimer;

	interface MsgQueue as ValidationQueue;
	interface TimedMsgQueue as QueryQueue;

	interface LinkStrengthLog;

	interface LocalTime<TMilli> as SysTime;
	interface Timer<TMilli> as Timer;
    }
}

implementation {
    //           [   destination  ][     source     ]
    uint8_t links[MAX_NETWORK_SIZE][MAX_NETWORK_SIZE];
    uint8_t msg_id;
    message_t entryBuffer;
    message_t validationBuffer;
    message_t timeoutBuffer;
    message_t respondBuffer;
    bool validationBusy;
    bool beaconPhase;
    bool beaconUpdatePhase;

    command error_t SplitControl.stop() {
	return SUCCESS;
    }

    command error_t SplitControl.start() {
	call Leds.set(0x2);
	beaconPhase = TRUE; 
	beaconUpdatePhase = FALSE;
	links[TOS_NODE_ID][TOS_NODE_ID] = PERMITTED; // whatever you do in the privacy of your own home...
	call BeaconPhaseTimer.startOneShot(BEACONPHASELENGTH);
	call BeaconTimer.startOneShot(10 * TOS_NODE_ID);
	return SUCCESS;
    }

    void copyPermissions(uint8_t *src, nx_uint8_t *dest) {
	uint8_t i;
	for ( i = 0 ; i < MAX_NETWORK_SIZE ; i++ ) {
	    dest[i] = src[i];
	}
    }

    void updatePermissions(nx_uint8_t *src, uint8_t *dest) {
	uint8_t i;
	for ( i = 0 ; i < MAX_NETWORK_SIZE ; i++ ) {
	    dest[i] = src[i];
	}
    }

    event void BeaconPhaseTimer.fired() {
	uint8_t i;
	uint8_t j;
	if ( beaconPhase ) {	  
	    call Leds.set(0x4);
	    beaconPhase = FALSE;
	    beaconUpdatePhase = TRUE;
	    call BeaconPhaseTimer.startOneShot(BEACONPHASELENGTH);
	}
	else if ( beaconUpdatePhase ) {
	    call Leds.set(0x0);
	    for (i = 0 ; i < MAX_NETWORK_SIZE ; i++ )
		printf("%d ", links[TOS_NODE_ID][i]);
	    printf("\n\n");
	    printfflush();
	    beaconUpdatePhase = FALSE;
	    call BeaconTimer.stop();
	    call BeaconPhaseTimer.startOneShot(BEACONPHASELENGTH);
	}
	else {
	    for (i = 0 ; i < MAX_NETWORK_SIZE ; i++ ) {
		for (j = 0 ; j < MAX_NETWORK_SIZE ; j++ )
		    printf("%d ", links[i][j]);
		printf("\n");
	    }
	    printfflush();
	    	
	    signal SplitControl.startDone(SUCCESS);
	}
    }

    event void BeaconTimer.fired() {
	beacon_update_t *payload;

	if ( beaconPhase ) {
	    call BeaconSend.send(AM_BROADCAST_ADDR, &entryBuffer, 1);
	}
	else if (beaconUpdatePhase) {
	    payload = (beacon_update_t*) entryBuffer.data;
	    copyPermissions(links[TOS_NODE_ID], payload->permissions);
	    call BeaconUpdateSend.send(AM_BROADCAST_ADDR, &entryBuffer, sizeof(beacon_update_t));
	    call BeaconTimer.startOneShot(BEACONINTERVAL);
	}
    }

    event void BeaconSend.sendDone(message_t *msg, error_t ok) {
	call BeaconTimer.startOneShot(BEACONINTERVAL);
    }

    event void BeaconUpdateSend.sendDone(message_t *msg, error_t ok) {
	call BeaconTimer.startOneShot(BEACONINTERVAL);
    }

    event message_t *BeaconReceive.receive(message_t *msg, void *payload, uint8_t len) {
	message_header_t *headerPtr;
	uint8_t src;
		
	if (!beaconPhase)
	    return msg;

	headerPtr = (message_header_t*) msg->header;
	
	src = headerPtr->cc2420.src;

	links[TOS_NODE_ID][src] = PERMITTED;
	
	call LinkStrengthLog.update(msg);
	
	return msg;
    }

    event message_t *BeaconUpdateReceive.receive(message_t *msg, void *payload, uint8_t len) {
	message_header_t *headerPtr;
	uint8_t src;
	beacon_update_t *payloadPtr;
	
	if (!beaconUpdatePhase)
	    return msg;

	headerPtr = (message_header_t*) msg->header;
	payloadPtr = (beacon_update_t*) payload;

	src = headerPtr->cc2420.src;

	updatePermissions(payloadPtr->permissions, links[src]);

	return msg;
    }

    task void TimerTask() {
	uint32_t alarmTime;
	uint32_t currentTime = call SysTime.get();

	call Timer.stop();

	if ( call QueryQueue.isEmpty() )
	    return;

	alarmTime = call QueryQueue.getEarliestTime();
	    
	// if alarm is due, signal timer straight away
	if ( inChronologicalOrder(alarmTime, currentTime) ) 
	    signal Timer.fired();
	else 
	    call Timer.startOneShot( alarmTime - currentTime );
    }

    task void ValidationTask() {
	link_validation_msg_t *payload;
	cc2420_header_t *header;

	if ( validationBusy )
	    return;
	validationBusy = TRUE;
       
	if ( call ValidationQueue.isEmpty() )
	    return;

	validationBuffer = *call ValidationQueue.pop();
	header = &((message_header_t*)validationBuffer.header)->cc2420;
	header->type = LINKVALMSG;
	payload = call AMSend.getPayload(&validationBuffer, sizeof(link_validation_msg_t));        

	if ( payload->src > MAX_NETWORK_SIZE || payload->dest > MAX_NETWORK_SIZE ) {
	    signal LinkControl.validationDone( payload->src, payload->dest, INVALID );
	    validationBusy = FALSE;
	    
	    if (!call ValidationQueue.isEmpty() )
		post ValidationTask();
	    else
		return;
	}

	payload->status = links[payload->dest][payload->src];

	if ( payload->status ) {
	    validationBusy = FALSE;
	    signal LinkControl.validationDone( payload->src, payload->dest, payload->status );
	}
	else {
	    printf("Querying base station.\n");
	    printfflush();
	    call AMSend.send(0, &validationBuffer, sizeof(link_validation_msg_t));
	}
    }

    event void AMSend.sendDone(message_t *msg, error_t ok) {
	uint32_t currentTime;

	if (TOS_NODE_ID == 0)
	    return;

	if ( ok == SUCCESS ) {
	    // set a maximum alarm time for a round trip through every node
	    // TODO: make this deal with large network sizes better
	    currentTime = call SysTime.get();

	    call QueryQueue.insert(&validationBuffer, currentTime + (LINK_VALIDATION_TIMEOUT));

	    post TimerTask();

	    validationBusy = FALSE;
	    if ( !call ValidationQueue.isEmpty() )
		post ValidationTask();
	}
	else
	    call AMSend.send(0, &validationBuffer, sizeof(link_validation_msg_t));
    }	

    event void Timer.fired() {
	link_validation_msg_t *payload;

	if ( call QueryQueue.isEmpty() )
	    return;
	
	timeoutBuffer = *call QueryQueue.pop();

        payload = call AMSend.getPayload(&timeoutBuffer, sizeof(link_validation_msg_t));

	signal LinkControl.validationDone( payload->src, payload->dest, UNKNOWN );
	
	post TimerTask();
    }

    event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len) {
	cc2420_header_t *header;
	error_t result;
	message_t *msgBuff;
	link_validation_msg_t *payloadPtr;

	respondBuffer = *msg;
	header = &((message_header_t*)respondBuffer.header)->cc2420;
	payloadPtr = (link_validation_msg_t*) respondBuffer.data;

	if ( TOS_NODE_ID == 0 && payloadPtr->status == 0 ) {
	    printf("Responding...\n");
	    printfflush();

	    payloadPtr->status = 1;

	    links[payloadPtr->dest][payloadPtr->src] = 1;

	    result = call AMSend.send(header->src, &respondBuffer, sizeof(link_validation_msg_t));

	    switch(result) {
	    case EBUSY:
		printf("ebusy\n");
		break;
	    case ENOMEM:
		printf("enomem\n");
		break;
	    case EINVAL:
		printf("einval\n");
		break;
	    }
	    printfflush();
	    return msg;
	}
	
	printf("Response received!\n");
	printfflush();

	call AMSend.send(AM_BROADCAST_ADDR, &respondBuffer, sizeof(link_validation_msg_t));

	msgBuff = call ValidationQueue.removeMsg(msg);

	printf("%d->%d::%d\n", payloadPtr->src, payloadPtr->dest, payloadPtr->status);
	
	links[payloadPtr->dest][payloadPtr->src] = payloadPtr->status;

	if ( msgBuff )
	    signal LinkControl.validationDone( payloadPtr->src, payloadPtr->dest, payloadPtr->status );
	    
	return msg;
    }

    command uint8_t LinkControl.isPermitted(uint8_t src, uint8_t dest) {
	if ( src > MAX_NETWORK_SIZE || dest > MAX_NETWORK_SIZE )
	    return INVALID;
	return links[dest][src];
    }

    command error_t LinkControl.validateLink(uint8_t src, uint8_t dest) {
	link_validation_msg_t *payload = (link_validation_msg_t*) call AMSend.getPayload(&entryBuffer, sizeof(link_validation_msg_t));
	    printf("Validating link.\n");
	    printfflush();

	payload->src = src;
	payload->dest = dest;
	
	if ( call ValidationQueue.push(&entryBuffer) != SUCCESS )
	    return ENOMEM;

	post ValidationTask();
	return SUCCESS;
    }
}
	    
