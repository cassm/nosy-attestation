#include "CAM.h"
#include "printf.h"

configuration CAMUnitTestAppC {
}
implementation {
    components MainC,
	CAMUnitTestC as App,
	new CAMUnitC(TESTMSG),
	PrintfC,
	SerialStartC;

    App.Boot -> MainC;
    App.AMSend -> CAMUnitC;
    App.Receive -> CAMUnitC;
    App.StdControl -> CAMUnitC;
}

