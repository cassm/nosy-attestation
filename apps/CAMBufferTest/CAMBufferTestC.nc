#include "CAM.h"
#include "printf.h"

module CAMBufferTestC {
    uses {
	interface Boot;
	interface CAMBuffer;
    }
}

implementation {
    event void Boot.booted() {
	uint8_t failed = 0;
	uint8_t i;
	cam_buffer_t* buffPtr[CAM_BUFFER_SIZE + 1];
	checksummed_msg_t* msgPtr;

	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ ) {
	    buffPtr[i] = call CAMBuffer.checkOutBuffer();
	    msgPtr = (checksummed_msg_t*) buffPtr[i]->message.data;
	    msgPtr->src = TOS_NODE_ID;
	    msgPtr->ID = i*2;
	    buffPtr[i]->alarmtime = i;
	    if (!buffPtr[i]) {
		printf("Buffer get failed at %d.\n", i);
		printfflush();
		failed++;
	    }
	}
	
	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer();
	if (buffPtr[CAM_BUFFER_SIZE]) {
	    printf("Buffer get limiting failed.\n");
	    printfflush();
	    failed++;
	}

	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest();
	if (buffPtr[CAM_BUFFER_SIZE]) {
	    printf("GetEarliest does not respect buffer lock.\n");
	    printfflush();
	    failed++;
	}
	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.retrieveMsg(TOS_NODE_ID, 10);
	if (buffPtr[CAM_BUFFER_SIZE]) {
	    printf("RetrieveMsg does not respect buffer lock.\n");
	    printfflush();
	    failed++;
	}
    	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.getMsgBuffer(&(buffPtr[5]->message));
	if (buffPtr[CAM_BUFFER_SIZE]) {
	    printf("GetMsgBuffer does not respect buffer lock.\n");
	    printfflush();
	    failed++;
	}

	

	for ( i = 4 ; i < 6 ; i++ ) {
	    if (call CAMBuffer.checkInBuffer(buffPtr[i]) != SUCCESS) {
		printf("Buffer checkin failed at %d.\n", i);
		printfflush();
		failed++;
	    }		
	}

	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest();
	if (!buffPtr[CAM_BUFFER_SIZE]) {
	    printf("GetEarliest failed.\n");
	    printfflush();
	    failed++;
	}
	else if (buffPtr[CAM_BUFFER_SIZE]->alarmtime != 4) {
	    printf("GetEarliest returned wrong buffer.\n");
	    printfflush();
	    failed++;
	}
	
	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer();
	if (buffPtr[CAM_BUFFER_SIZE]) {
	    printf("CheckoutBuffer does not respect buffer inuse.\n");
	    printfflush();
	    failed++;
	}
	
	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.retrieveMsg(TOS_NODE_ID, 10);
	if (!buffPtr[CAM_BUFFER_SIZE])  {
	    printf("retrieveMsg failed to find buffer.\n");
	    printfflush();
	    failed++;
	}

	if (buffPtr[CAM_BUFFER_SIZE]->alarmtime != 5) {
	    printf("retrieveMsg failed to find correct buffer.\n");
	    printfflush();
	    failed++;
	}


    	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.getMsgBuffer(&(buffPtr[5]->message));
	if (!buffPtr[CAM_BUFFER_SIZE]) {
	    printf("GetMsgBuffer failed to retrieve message.\n");
	    printfflush();
	    failed++;
	}


	if (call CAMBuffer.releaseBuffer(buffPtr[4]) != SUCCESS) {
	    printf("Buffer release did not return success.\n");
	    printfflush();
	    failed++;
	}

	buffPtr[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer();
	if (!buffPtr[CAM_BUFFER_SIZE]) {
	    printf("Buffer get failed after release.\n");
	    printfflush();
	    failed++;
	}
	printf("%d tests failed.\n", failed);
	printfflush();
    }
}
