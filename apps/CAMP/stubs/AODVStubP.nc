generic module AODVStubP() {
    provides interface RouteFinder;
    uses interface Timer<TMilli> as Timer;
}

implementation {
    bool busy = FALSE;
    uint8_t reqDest, reqSrc, reqMsgId;
    
    task void findRoute() {
	if ( reqDest < TOS_NODE_ID ) {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID - 1, reqMsgId, reqSrc, SUCCESS );
	}
	else if ( reqDest > TOS_NODE_ID ) {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID + 1, reqMsgId, reqSrc, SUCCESS );
	}
	else {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID, reqMsgId, reqSrc, SUCCESS );
	}
	busy = FALSE;
    }

    command error_t RouteFinder.getNextHop( uint8_t dest_ID , uint8_t msg_ID , uint8_t src_ID ) {
	if (busy) return FAIL;
	busy = TRUE;

	reqDest = dest_ID;
	reqMsgId = msg_ID;
	reqSrc = src_ID;
	call Timer.startOneShot(ROUTING_DELAY);
	return SUCCESS;
    }

    event void Timer.fired() {
	post findRoute();
    }

    command error_t RouteFinder.hopFailed( uint8_t dest_ID, uint8_t next_ID, uint8_t src_ID , uint8_t msg_ID ) {
	if (busy) return FAIL;
	busy = TRUE;

	// whatevs
	reqDest = dest_ID;
	reqMsgId = msg_ID;
	reqSrc = src_ID;
	post findRoute();
	return SUCCESS;
    }
}
