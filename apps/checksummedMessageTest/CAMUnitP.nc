#include "CAM.h"

generic module CAMUnitP(am_id_t AMId) {
    uses {
	interface Receive as Snoop;
	interface Leds;
	interface Timer<TMilli> as Timer;
    }
}

implementation {
    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	call Leds.set(0x7);
	call Timer.startOneShot(1000);
	return msg;
    }

    event void Timer.fired() {
	call Leds.set(0x0);
    }
}
