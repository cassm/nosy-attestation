#include "CAM.h"
#include "printf.h"

module LinkControlP {
    provides interface LinkControl;
    uses {
	interface AMSend;
	interface Receive;
	interface MsgQueue as ValidationQueue;
	interface TimedMsgQueue as QueryQueue;

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

    task void TimerTask() {
	uint32_t alarmTime;
	uint32_t currentTime = call SysTime.get();

	call Timer.stop();

	printf("Timertask.\n");
	printfflush();

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
	printf("Validationtask\n");
	printfflush();

	if ( validationBusy )
	    return;
	validationBusy = TRUE;
       
	if ( call ValidationQueue.isEmpty() )
	    return;

	validationBuffer = *call ValidationQueue.pop();
	payload = call AMSend.getPayload(&validationBuffer, sizeof(link_validation_msg_t));        

	if ( payload->src > MAX_NETWORK_SIZE || payload->dest > MAX_NETWORK_SIZE ) {
	    signal LinkControl.ValidationDone( payload->src, payload->dest, INVALID );
	    validationBusy = FALSE;
	    
	    if (!call ValidationQueue.isEmpty() )
		post ValidationTask();
	    else
		return;
	}

	payload->status = links[payload->dest][payload->src];

	if ( payload->status ) {
	    validationBusy = FALSE;
	    signal LinkControl.ValidationDone( payload->src, payload->dest, payload->status );
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
	    printf("Send done.\n");
	    printfflush();
	    // set a maximum alarm time for a round trip through every node
	    // TODO: make this deal with large network sizes better
	    currentTime = call SysTime.get();

	    call QueryQueue.insert(&validationBuffer, currentTime + (2 * CAM_FWD_TIMEOUT * MAX_NETWORK_SIZE));

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
	printf("Timer fired.\n");
	printfflush();



	if ( call QueryQueue.isEmpty() )
	    return;
	
	timeoutBuffer = *call QueryQueue.pop();

        payload = call AMSend.getPayload(&timeoutBuffer, sizeof(link_validation_msg_t));

	signal LinkControl.ValidationDone( payload->src, payload->dest, UNKNOWN );
	
	post TimerTask();
    }

    event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len) {
	link_validation_msg_t *payloadPtr = (link_validation_msg_t*) payload;

	printf("Response received!\n");
	printfflush();

	if (TOS_NODE_ID == 0) {
	    respondBuffer = *msg;
	    payloadPtr = (link_validation_msg_t*) respondBuffer.data;
	    payloadPtr->status = payloadPtr->dest % 3;
	    call AMSend.send(1, &respondBuffer, sizeof(link_validation_msg_t)); 
	    return msg;
	}
	
	call ValidationQueue.removeMsg(msg);

	printf("%d->%d::%d\n", payloadPtr->src, payloadPtr->dest, payloadPtr->status);
	
	links[payloadPtr->dest][payloadPtr->src] = payloadPtr->status;

	signal LinkControl.ValidationDone( payloadPtr->src, payloadPtr->dest, payloadPtr->status );
	    
	return msg;
    }

    command uint8_t LinkControl.isPermitted(uint8_t src, uint8_t dest) {
	if ( src > MAX_NETWORK_SIZE || dest > MAX_NETWORK_SIZE )
	    return INVALID;
	printf("Status of link from %d to %d is %d\n", src, dest, links[dest][src]);
	printfflush();
	return links[dest][src];
    }

    command error_t LinkControl.ValidateLink(uint8_t src, uint8_t dest) {
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
	    
