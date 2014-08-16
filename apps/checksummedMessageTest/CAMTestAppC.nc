#include "CAM.h"

configuration CAMTestAppC {
} 

implementation {
    components MainC, CAMTestC as App, new CAMUnitC(TESTMSG), LedsC, new TimerMilliC() as SendTimer, new TimerMilliC() as LightTimer, ActiveMessageC;

    
    App.Boot -> MainC;
    App.AMSend -> CAMUnitC;
    App.Leds -> LedsC;
    App.SendTimer -> SendTimer;
    App.LightTimer -> LightTimer;
    App.Receiver -> CAMUnitC;
    App.AMControl -> ActiveMessageC;
}
