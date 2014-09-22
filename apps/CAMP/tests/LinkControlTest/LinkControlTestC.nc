#include "printf.h"

module LinkControlTestC {
    uses interface Boot;
    uses interface LinkControl;
    uses interface SplitControl;
    uses interface StdControl as CAMControl;
    uses interface Timer<TMilli> as Timer;
}
implementation {
    uint8_t i;

    event void Boot.booted() {
	i = 0;
	call CAMControl.start();
	call SplitControl.start();
    }
    event void SplitControl.stopDone(error_t result) {}
    event void SplitControl.startDone(error_t result) {
	if ( result == SUCCESS )
	    if (TOS_NODE_ID == 4)
		signal Timer.fired();

//	    call Timer.startPeriodic(1000);
	else 
	    call SplitControl.start();
    }

    event void LinkControl.ValidationDone( uint8_t src, uint8_t dest, uint8_t status ) {
	printf("Validation Done!: %d -> %d :: %d\n", src, dest, status);
	printf("Status reads: %d\n\n", call LinkControl.isPermitted(src, dest));
	printfflush();
	call Timer.startOneShot(1000);
    }

    event void Timer.fired() {
	call LinkControl.ValidateLink(0,i++); 
    }
}
