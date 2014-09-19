#include "CAM.h"

generic configuration CAMUnitC(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
	interface StdControl;
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

	//new AMSenderC(CAMMSG) as SubSend,
	SendStubC as SubSend,
	new AMReceiverC(CAMMSG) as SubReceive,
	//ReceiveStubC as SubReceive,
	new AMSnooperC(CAMMSG),

	new AODVStubC(),
	PrintfC,
	SerialStartC,
	RandomC;
   
    AMSend = App.AMSend;
    Receive = App.Receive;
    StdControl = App.StdControl;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;

    App.RoutingQueue->RoutingQueue;
    App.SendingQueue->SendingQueue;
    App.HeardQueue->HeardQueue;
    App.ListeningQueue->ListeningQueue;
    App.TimeoutQueue->TimeoutQueue;

    App.ListeningTimer->ListeningTimer;

    // testing only
    //ReceiveControl = SubReceive.ReceiveControl;

    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.SysTime -> SysTime;
    App.Random -> RandomC;    
    App.RouteFinder -> AODVStubC;
}

    

