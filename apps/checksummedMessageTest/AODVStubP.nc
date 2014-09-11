generic module AODVStubP() {
    provides interface RouteFinder;
}

implementation {
    uint8_t currentReq;
    
    task void findRoute() {
	if ( currentReq < TOS_NODE_ID ) {
	    signal nextHopFound( currentReq, currentReq - 1, , uint8_t msg_ID, SUCCESS );
	}
	if ( currentReq > TOS_NODE_ID ) {
	    signal nextHopFound( currentReq, currentReq + 1, uint8_t msg_ID, SUCCESS );
	}
	else {
	    signal nextHopFound( currentReq, currentReq, uint8_t msg_ID, SUCCESS );
	}
    }

    command error_t getNextHop( uint8_t dest_ID , uint8_t msg_ID ) {
	currentReq = dest;
	post findRoute;
	return SUCCESS;
    }

    command error_t hopFailed( uint8_t dest_ID, uint8_t next_ID, , uint8_t msg_ID ) {
	// whatevs
	currentReq = dest;
	post findRoute;
	return SUCCESS;
    }
}
