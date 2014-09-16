#include "CAM.h"
#include "printf.h"

configuration SendStubC {
    provides interface AMSend;
}
implementation {
    components PrintfC;
    components SerialStartC;
    components SendStubP;
    components new TimerMilliC();
    AMSend = SendStubP;
    SendStubP.Timer -> TimerMilliC;
}
