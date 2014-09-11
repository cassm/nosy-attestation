#include "CAM.h"

module CamBuffTestC {
    uses {
	interface Boot;
	interface CAMBuffer;
	interface Timer<TMilli> as Timer;
    }
}

implementation {
    cam_buffer_t *currentBuff[CAM_BUFFER_SIZE + 1];
    checksummed_msg_t *msg;
    
    void fillBuff(cam_buffer_t *buff, uint8_t src, uint8_t msgId, uint8_t time, uint8_t value) {
	buff->alarmtime = time;
	msg = (checksummed_msg_t*) &(buff->message.data);
	msg->ID = msgId;
	msg->src = src;
	//msg->message = value;
    }

    uint8_t getVal(cam_buffer_t *buff) {
	msg = (checksummed_msg_t*) &(buff->message.data);
	return (uint8_t) msg->data;
    }

    uint8_t i;
    
    event void Timer.fired() {}

    event void Boot.booted() {
	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ ) {
	    //printf("Getting buffer %d...\n", i);
	    printfflush();
	    currentBuff[i] = call CAMBuffer.checkOutBuffer();
	    if (!currentBuff[i]){ 
		printf("Null value received at %d!",i);
		printfflush();
	    }
	    else {
		fillBuff(currentBuff[i], TOS_NODE_ID, i+3, i, i*2);
		//printf("Buffer obtained.\n");
		printfflush();
	    }
	}

	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer(); */
	/* if (!currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Max buffer size test 1 PASSED.\n"); */
	/* else */
	/*     printf("Max buffer size test 1 FAILED.\n"); */
	/* printfflush(); */
	    
	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest(); */
	/* if (!currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Buffer lock test 1 PASSED.\n"); */
	/* else */
	/*     printf("Buffer lock test 1 FAILED.\n"); */
	/* printfflush(); */
	    
	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.retrieveMsg(TOS_NODE_ID, 5); */
	/* if (!currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Buffer lock test 2 PASSED.\n"); */
	/* else */
	/*     printf("Buffer lock test 2 FAILED.\n"); */
	/* printfflush(); */
	    
	/* call CAMBuffer.checkInBuffer(currentBuff[0]); */

	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.retrieveMsg(TOS_NODE_ID, 3); */
	/* if (currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Buffer checkin test 1 PASSED.\n"); */
	/* else */
	/*     printf("Buffer checkin test 1 FAILED.\n"); */
	/* printfflush(); */
	    
	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest(); */
	/* if (currentBuff[CAM_BUFFER_SIZE]) { */
	/*     if (currentBuff[CAM_BUFFER_SIZE]->alarmtime == 0)  */
	/* 	printf("Buffer checkin test 2 PASSED (correct time).\n"); */
	/*     else */
	/* 	printf("Buffer checkin test 2 PASSED (incorrect time).\n"); */
	/* } */
	/* else */
	/*     //printf("Buffer checkin test 2 FAILED.\n"); */
	/* printfflush(); */
	    
	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer(); */
	/* if (!currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Buffer checkin test 3 PASSED.\n"); */
	/* else */
	/*     printf("Buffer checkin test 3 FAILED.\n"); */
 
	for ( i = 0 ; i < CAM_BUFFER_SIZE ; i++ ) {
	    call CAMBuffer.checkInBuffer(currentBuff[i]);
	}
	/* printfflush(); */
	    
	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest(); */
	/* if (currentBuff[CAM_BUFFER_SIZE]) { */
	/*     if (currentBuff[CAM_BUFFER_SIZE]->alarmtime == 0)  */
	/* 	printf("Buffer checkin test 4 PASSED (correct time).\n"); */
	/*     else */
	/* 	printf("Buffer checkin test 4 PASSED (incorrect time).\n"); */
	/* } */
	/* else */
	/*     printf("Buffer checkin test 4 FAILED.\n"); */
	/* printfflush(); */
	    

	/* currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer(); */
	/* if (!currentBuff[CAM_BUFFER_SIZE]) */
	/*     printf("Buffer checkout test 1 PASSED.\n"); */
	/* else */
	/*     printf("Buffer checkout test 1 FAILED.\n"); */
	/* printfflush(); */
	    
	
	call CAMBuffer.releaseBuffer(currentBuff[0]);

	currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.getEarliest();
	if (currentBuff[CAM_BUFFER_SIZE]) {
	    if (currentBuff[CAM_BUFFER_SIZE]->alarmtime == 1) 
		printf("Buffer checkin test 4 PASSED (correct time).\n");
	    else
		printf("Buffer checkin test 4 PASSED (incorrect time).\n");
	}
	else
	    printf("Buffer checkin test 4 FAILED.\n");
	printfflush();
	    
	currentBuff[CAM_BUFFER_SIZE] = call CAMBuffer.checkOutBuffer();
	if (currentBuff[CAM_BUFFER_SIZE])
	    printf("Buffer checkout test 2 PASSED.\n");
	else
	    printf("Buffer checkout test 2 FAILED.\n");
	printfflush();
	    
    }
}
