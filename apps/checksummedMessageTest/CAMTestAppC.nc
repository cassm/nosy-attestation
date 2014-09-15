#include "CAM.h"
#include "printf.h"

configuration CAMTestAppC {
} 

implementation {
    components MainC, 
	CAMTestC as App, 
	new CAMUnitC(TESTMSG), 
	new TimerMilliC() as Timer, 
	ActiveMessageC,
	new AODVStubC();

    
    App.Boot -> MainC;
    App.AMSend -> CAMUnitC;
    App.Timer -> Timer;
    App.RouteFinder -> AODVStubC;
    App.Receiver -> CAMUnitC;
    App.AMControl -> ActiveMessageC;
}
