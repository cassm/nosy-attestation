#include "CAM.h"

generic configuration CAMUnitC(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
	// testing only
	//interface StdControl as ReceiveControl;
    }
}

implementation {
    components new CAMUnitP(AMId) as App,
	LedsC,
	LocalTimeMilliC as SysTime,
	new TimerMilliC() as AlarmTimer,
	new TimerMilliC() as LightTimer,
	new AMSenderC(CAMMSG) as SubSend,
	//SendStubC as SubSend,
	new AMReceiverC(CAMMSG) as SubReceive,
	//ReceiveStubC as SubReceive,
	new AMSnooperC(CAMMSG),
	new CAMBufferC(),
	new AODVStubC(),
	PrintfC,
	SerialStartC,
	RandomC;
   
    AMSend = App.AMSend;
    Receive = App.Receive;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;

    // testing only
    //ReceiveControl = SubReceive.ReceiveControl;

    App.SendBuffer -> CAMBufferC;
    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.SysTime -> SysTime;
    App.AlarmTimer -> AlarmTimer;
    App.LightTimer -> LightTimer;
    App.Random -> RandomC;    
    App.RouteFinder -> AODVStubC;
}

    

