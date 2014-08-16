#include "CAM.h"

generic configuration CAMSenderC(am_id_t AMId) {
    provides {
	interface AMSend;
    }
}

implementation { 
    components new AMSenderC(CAMMSG), new CAMSenderP(AMId);

    AMSend = CAMSenderP;
    CAMSenderP.SubSend->AMSenderC;
}
    
