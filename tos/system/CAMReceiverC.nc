#include "CAM.h"

generic configuration CAMReceiverC(am_id_t AMId) {
    provides {
	interface Receive;	
    }
}


implementation { 
    components new AMReceiverC(CAMMSG), new CAMReceiverP(AMId), LedsC;

    Receive = CAMReceiverP;
    CAMReceiverP.SubReceive->AMReceiverC;
    CAMReceiverP.Leds->LedsC;
}
    
