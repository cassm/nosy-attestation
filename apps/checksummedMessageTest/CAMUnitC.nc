#include "CAM.h"

generic configuration CAMUnitC(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
    }
}

implementation {
    components new CAMUnitP(AMId) as App;
    components LedsC;
    components new CAMSenderC(AMId);
    components new CAMReceiverC(AMId);
    components new AMSnooperC(CAMMSG);
    components new CAMBufferC();

    components new TimerMilliC() as Timer;
    
    
    AMSend = CAMSenderC;
    Receive = CAMReceiverC;
    
    App.CAMBuffer -> CAMBufferC.CAMBuffer;
    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
}

    

