#include "CAM.h"
#include "printf.h"

configuration PongAppC {}
implementation {
    components MainC,
	PongC as App,
	ActiveMessageC,
	new TimerMilliC() as Timer,
	new CAMUnitC(TESTMSG),
	PrintfC, 
	SerialStartC;
    App.Boot -> MainC;
    App.RadioControl -> ActiveMessageC;
    App.AMSend -> CAMUnitC;
    App.Receive -> CAMUnitC;
    App.Timer -> Timer;
    App.CAMControl -> CAMUnitC;
}
	  
