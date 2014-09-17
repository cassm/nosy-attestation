#include "printf.h"
#include "CAM.h"

module MsgQueueTestC {
    uses {
	interface Boot;
	interface MsgQueue as Queue1;
	interface MsgQueue as Queue2;
    }
}
implementation {
    uint8_t i;
    message_t msg; 
    message_t *msgPtr;
    int *payload = (int*) msg.data;

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
	    *payload = i + 10;
	    if ( call Queue1.push(&msg) != SUCCESS ) {
		printResult(2, FALSE);
		return;
	    }
	}

	printResult(3, call Queue2.pop() == NULL);

	printResult(4, call Queue1.isFull());

	printResult(5, call Queue1.push(&msg) != SUCCESS);

	msgPtr = call Queue1.pop();

	printResult(6, msgPtr != NULL);

	if (!msgPtr)
	    return;
	
	msg = *msgPtr;

	printResult(7, *payload == 10);

	payload = (int*) msg.data;

	printResult(8, !(call Queue1.isFull()));

	msg = *call Queue1.pop();
    	
	printResult(9, *payload == 11);

	*payload = 35;

	msg = *call Queue1.pop();

	printResult(10, *payload == 35);

	
	for ( i = 0 ; i < CAM_QUEUE_SIZE - 2 ; i++ ) {
	    if ( !call Queue1.pop() ) {
		printResult(11, FALSE);
		return;
	    }
	}

	printResult(12, !call Queue1.pop());
	printResult(13, !call Queue1.isFull());
    }
}		
	

