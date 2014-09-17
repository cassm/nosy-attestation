#include "CAM.h"

generic module TimedMsgQueueP() {
    provides interface TimedMsgQueue;
}
implementation {
    // 255 is reserved as the error val for an empty buffer. This limits the queue length to 254.
    enum { BUFFEREMPTY = 255 };
    message_t queue[CAM_QUEUE_SIZE];
    bool inUse[CAM_QUEUE_SIZE];
    uint32_t alarmTime[CAM_QUEUE_SIZE];
    uint8_t i;

    uint8_t getEarliestSlot() {
	uint32_t min;
	uint32_t halfMax = (~0) / 2;
	bool found = FALSE;
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    if ( !found || alarmTime[i] < alarmTime[min] || (alarmTime[i] - alarmTime[min] > halfMax) ) {
		found = TRUE;
		min = i;
	    }
	}

	if ( !found )
	    return BUFFEREMPTY;

	return min;
    }

    command error_t TimedMsgQueue.initialise() {
	for ( i = 0 ; i < CAM_QUEUE_SIZE ; i++ ) {
	    inUse[i] = FALSE;
	}
    }

    command uint32_t getEarliestTime() {
	uint8_t result = getEarliestSlot();

	// 0 is reserved as the error val for an empty buffer. This occasionally causes
	// alarm timing to slip by 1ms.
	if ( result == BUFFEREMPTY )
	    return 0;
	else if ( alarmTime[result] == 0 )
	    return 1;
	else
	    return alarmTime[result];
    }

    
