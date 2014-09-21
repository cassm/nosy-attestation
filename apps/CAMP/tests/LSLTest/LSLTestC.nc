module LSLTestC {
    uses {
	interface Boot;
	interface LinkStrengthLog;
	interface Receive as Snoop;
	interface SplitControl as AMControl;
   }
}

implementation {
    event void Boot.booted() {
	call AMControl.start();
    }

    event void AMControl.startDone(error_t err) {
	if (err != SUCCESS) {
	    call AMControl.start();
	}
	else {
	    printf("started\n");
	    printfflush();
	}	    
    }

    event void AMControl.stopDone(error_t err) {
	// do nothing
    }


    event message_t *Snoop.receive(message_t *msg, void *payload, uint8_t len) {
	uint8_t src = call LinkStrengthLog.update(msg);

	printf("%d: %d\n", src, call LinkStrengthLog.getLqi(src));
	printfflush();
	return msg;
    }
}
