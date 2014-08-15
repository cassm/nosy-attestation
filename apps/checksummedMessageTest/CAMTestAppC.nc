#include "CAM.h"

configuration CAMTestAppC {
} 

implementation {
    components MainC, CAMTestC as App, new CAMSenderC(TESTMSG), LedsC, new TimerMilliC() as SendTimer, new TimerMilliC() as LightTimer, new CAMReceiverC(TESTMSG) as RedReceiver, new CAMReceiverC(TESTMSG) as GreenReceiver, ActiveMessageC;

    
    App.Boot -> MainC;
    App.AMSend -> CAMSenderC;
    App.Leds -> LedsC;
    App.SendTimer -> SendTimer;
    App.LightTimer -> LightTimer;
    App.RedReceiver -> RedReceiver;
    App.GreenReceiver -> GreenReceiver;
    App.AMControl -> ActiveMessageC;
}
