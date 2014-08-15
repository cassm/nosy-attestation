#include CAM.h

configuration CAMTestApp {
} 

implementation {
    components MainC, CAMTestC as App, new CAMSenderC(TESTMSG), LedsC, new TimerMilliC() as SendTimer, new TimerMilliC() as LightTimer, new AMReceiverC(CAMMSG) as RedReceiver, new AMReceiverC(CAMMSG) as GreenReceiver, ActiveMessageC;

    
    App.Boot -> MainC;
    App.AMSend -> CAMSenderC;
    App.Leds -> LedsC;
    App.SendTimer -> SendTimer;
    App.LightTimer -> LightTimer;
    App.RedReceiver -> RedReceiver;
    App.GreenReceiver -> GreenReceiver;
    App.AMControl -> ActiveMessageC;
}
