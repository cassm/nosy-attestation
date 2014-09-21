#include "CAM.h"
#include "printf.h"

configuration LSLTestAppC {}

implementation {
    components MainC,
	LSLTestC as App,
	new AMSnooperC(CAMMSG),
	LinkStrengthLogC,        
	ActiveMessageC,
	PrintfC,
	SerialStartC;
    
    App.Boot -> MainC;
    App.LinkStrengthLog -> LinkStrengthLogC;
    App.Snoop -> AMSnooperC;
    App.AMControl -> ActiveMessageC;
}
