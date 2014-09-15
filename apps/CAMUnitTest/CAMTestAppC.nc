#include "CAM.h"
#include "printf.h"

configuration CAMTestAppC {
} 

implementation {
    components MainC, 
	CAMTestC as App, 
	new CAMUnitC(TESTMSG), 
	new TimerMilliC() as Timer, 
	PrintfC,
	SerialStartC;

    
    App.Boot -> MainC;
    App.AMSend -> CAMUnitC;
    App.Timer -> Timer;
}
