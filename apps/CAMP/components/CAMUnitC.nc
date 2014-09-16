#include "CAM.h"

generic configuration CAMUnitC(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
	interface StdControl as ReceiveControl;
    }
}

implementation {
    components new CAMUnitP(AMId) as App,
	LedsC,
	new TimerMilliC() as Timer,
//	new AMSenderC(CAMMSG) as SubSend,
	SendStubC as SubSend,
//	new AMReceiverC(CAMMSG) as SubReceive,
	ReceiveStubC as SubReceive,
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
    ReceiveControl = SubReceive.ReceiveControl;

    App.SendBuffer -> CAMBufferC;
    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.Random -> RandomC;    
    App.RouteFinder -> AODVStubC;

}

    

