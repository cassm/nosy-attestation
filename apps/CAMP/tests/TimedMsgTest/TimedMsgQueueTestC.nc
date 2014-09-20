#include "printf.h"
#include "CAM.h"

module TimedMsgQueueTestC {
    uses {
	interface Boot;
	interface TimedMsgQueue as Queue1;
	interface TimedMsgQueue as Queue2;
    }
}
implementation {
    uint8_t i;
    message_t msg; 
    message_t *msgPtr;
    checksummed_msg_t *payloadPtr = (checksummed_msg_t*) msg.data;

    void printResult(uint8_t number, bool result) {
	if ( result ) 
	    printf("%d: PASSED\n", number);
	else
	    printf("%d: FAILED\n", number);
	printfflush();
    }


    event void Boot.booted() {
	
	call Queue1.initialise();
	call Queue2.initialise();

	printResult(0, call Queue1.isEmpty() && call Queue2.isEmpty() );

	printResult(1, !call Queue1.isFull() && !call Queue2.isFull() );

	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    payloadPtr->src = i;
	    payloadPtr->dest = i+10;
	    payloadPtr->type = 2*i;

	    if ( call Queue1.insert(&msg,10*i) != SUCCESS ) {
		printResult(2, FALSE);
		return;
	    }
	}

	printResult(3, call Queue2.pop() == NULL);

	printResult(4, call Queue1.isFull());

	payloadPtr->src = 45;
	payloadPtr->dest = i+10;
	payloadPtr->type = 2*i;
	    
	printResult(5, call Queue1.insert(&msg, ~100) != SUCCESS);

	msgPtr = call Queue1.pop();
	msgPtr = call Queue1.pop();

	printResult(6, msgPtr != NULL);

	if (!msgPtr)
	    return;

	payloadPtr->src = 41;
	payloadPtr->dest = i+10;
	payloadPtr->type = 2*i;
	
	printResult(7, call Queue1.insert(&msg, 150) == SUCCESS);

	payloadPtr->src = 45;
	printResult(7, call Queue1.insert(&msg, -150) == SUCCESS);



	msgPtr = call Queue1.pop();

	msg = *msgPtr;

	printResult(8, payloadPtr->src == 45 );

	printResult(9, !(call Queue1.isFull()));

	msg = *call Queue1.pop();
    	
	printResult(10, payloadPtr->src == 2);

	printResult(11, call Queue1.getEarliestTime() == 30);

	payloadPtr->src = 3;
	payloadPtr->dest = 13;
	payloadPtr->type = 6;
	
	printResult(12, call Queue1.isInQueue(&msg));

	payloadPtr->src = 4;

	printResult(13, !call Queue1.isInQueue(&msg));

	payloadPtr->src = 3;

	printResult(14, call Queue1.remove(&msg) == SUCCESS);
	
	printResult(15, !call Queue1.isInQueue(&msg));

	msg = *call Queue1.pop();
	
	printResult(16, payloadPtr->src == 4);

	for ( i = 0 ; i < 7 ; i++ ) 
	    call Queue1.pop();

	printResult(17, call Queue1.isEmpty());
    }
}
