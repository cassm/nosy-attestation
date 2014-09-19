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

	new TimerMilliC() as ListeningTimer,

	new MsgQueueC() as RoutingQueue,
	new MsgQueueC() as SendingQueue,
	new MsgQueueC() as HeardQueue,
	new TimedMsgQueueC() as ListeningQueue,
	new TimedMsgQueueC() as TimeoutQueue,

	new AMSenderC(CAMMSG) as SubSend,
	//SendStubC as SubSend,
	new AMReceiverC(CAMMSG) as SubReceive,
	//ReceiveStubC as SubReceive,
	new AMSnooperC(CAMMSG),

	new AODVStubC(),
	PrintfC,
	SerialStartC,
	RandomC;
   
    AMSend = App.AMSend;
    Receive = App.Receive;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;

    App.RoutingQueue->RoutingQueue;
    App.SendingQueue->SendingQueue;
    App.ListeningQueue->ListeningQueue;

    // testing only
    //ReceiveControl = SubReceive.ReceiveControl;

    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.SysTime -> SysTime;
    App.AlarmTimer -> AlarmTimer;
    App.LightTimer -> LightTimer;
    App.Random -> RandomC;    
    App.RouteFinder -> AODVStubC;
}

    

