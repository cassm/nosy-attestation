module AODVStubP {
    provides interface RouteFinder;
    provides interface SplitControl;
    uses interface Timer<TMilli> as Timer;
}

implementation {
    bool busy = FALSE;
    uint8_t reqDest, reqSrc;
    bool starting;


    command error_t SplitControl.start() {
	starting = TRUE;
	call Timer.startOneShot(250);
	return SUCCESS;
    }

    command error_t SplitControl.stop() {}

    task void findRoute() {
	busy = FALSE;
	if ( reqDest < TOS_NODE_ID ) {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID - 1, reqDest );
	}
	else if ( reqDest > TOS_NODE_ID ) {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID + 1, reqDest );
	}
	else {
	    signal RouteFinder.nextHopFound( TOS_NODE_ID, reqSrc );
	}
    }

    command error_t RouteFinder.getNextHop( uint8_t dest_ID ) {
	if (busy) return FAIL;
	busy = TRUE;

	reqDest = dest_ID;
	call Timer.startOneShot(400);
	return SUCCESS;
    }

    event void Timer.fired() {
	if (starting) {
	    starting = FALSE;
	    signal SplitControl.startDone(SUCCESS);
	}
	post findRoute();
    }

    command error_t RouteFinder.hopFailed( uint8_t src, uint8_t dest) {
	if (busy) return FAIL;
	busy = TRUE;

	// whatevs
	reqDest = dest;
	post findRoute();
	return SUCCESS;
    }

    command uint8_t RouteFinder.checkRouting(checksummed_msg_t *payload) {
	if ( payload->src < payload->dest ) {
	    if ( payload->next < payload->curr )
		return UPSTREAM;
	    else if ( payload->next > payload->curr )
		return GOOD;
	    else
		return NONOPTIMAL;
	}
	else if ( payload->src > payload->dest ) {
	    if ( payload->next > payload->curr )
		return UPSTREAM;
	    else if ( payload->next < payload->curr )
		return GOOD;
	    else
		return NONOPTIMAL;
	}
	else {
	    if ( payload->next == payload->curr ) 
		return GOOD;
	    else
		return NONOPTIMAL;
	}
    }
}
