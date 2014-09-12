generic module AODVStubP() {
    provides interface RouteFinder;
    uses interface Timer<TMilli> as Timer;
}

implementation {
    bool BUSY = FALSE;
    uint8_t reqDest, reqSrc, reqMsgId;
    
    task void findRoute() {
	if ( reqDest < TOS_NODE_ID ) {
	    signal nextHopFound( TOS_NODE_ID - 1, reqMsgId, reqSrc, SUCCESS );
	}
	if ( reqDest > TOS_NODE_ID ) {
	    signal nextHopFound( TOS_NODE_ID + 1, reqMsgId, reqSrc, SUCCESS );
	}
	else {
	    signal nextHopFound( TOS_NODE_ID, reqMsgId, reqSrc, SUCCESS );
	}
	BUSY = FALSE;
    }

    command error_t getNextHop( uint8_t dest_ID , uint8_t msg_ID , uint8_t src_ID ) {
	if (BUSY) return FAIL;
	BUSY = TRUE;

	reqDest = dest_ID;
	reqMsgId = msg_ID;
	reqSrc = src_ID;
	call Timer.startOneShot(500);
	return SUCCESS;
    }

    event void Timer.fired() {
	post findRoute;
    }

    command error_t hopFailed( uint8_t dest_ID, uint8_t next_ID, uint8_t src_ID , uint8_t msg_ID ) {
	if (BUSY) return FAIL;
	BUSY = TRUE;

	// whatevs
	reqDest = dest;
	reqMsgId = msg_ID;
	reqSrc = src_ID;
	post findRoute;
	return SUCCESS;
    }
}
