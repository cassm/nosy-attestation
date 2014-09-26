#include "CAM.h"
#include "printf.h"

configuration PongAppC {}
implementation {
    components MainC,
//	DelugeC,
	PongC as App,
	ActiveMessageC,
	new TimerMilliC() as Timer,
	CAMUnitC,
	new CAMSenderC(TESTMSG),
	new CAMReceiverC(TESTMSG),
	PrintfC, 
	SerialStartC;
    App.Boot -> MainC;
    App.RadioControl -> ActiveMessageC;
    App.AMSend -> CAMSenderC;
    App.Receive -> CAMReceiverC;
    App.Timer -> Timer;
    App.CAMControl -> CAMUnitC;
}
	  
