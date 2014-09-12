#include "CAM.h"

module RouteFindTestC {
    uses {
	interface Boot;
	interface RouteFinder;
	interface Timer<TMilli> as Timer;
    }
}

implementation {
    uint8_t i = 0;
    uint8_t result;
    
    event void Boot.booted() {
	signal Timer.fired();
    }

    event void Timer.fired() {
	if (i < 11) {
	    call RouteFinder.getNextHop(i, 35, TOS_NODE_ID);
	}
    }

    event void RouteFinder.nextHopFound( uint8_t next_id, uint8_t msg_ID, uint8_t src_ID, error_t ok ) {
	printf("%d -> %d :: %d\n", TOS_NODE_ID, i++, next_id);
	printfflush();
	call Timer.startOneShot(800);
    }
}
