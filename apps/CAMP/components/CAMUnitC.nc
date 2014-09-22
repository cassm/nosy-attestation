#include "CAM.h"

configuration CAMUnitC {
    provides {
	interface AMSend;
	interface Receive;
	interface StdControl;
	// testing only
	//interface StdControl as ReceiveControl;
    }
}

implementation {
    components CAMUnitP as App,
	LedsC,
	LocalTimeMilliC as SysTime,

	new TimerMilliC() as ListeningTimer,
	new TimerMilliC() as LightTimer,

	new MsgQueueC() as RoutingQueue,
	new MsgQueueC() as SendingQueue,
	new MsgQueueC() as HeardQueue,
	new MsgQueueC() as ReceivedQueue,
	new TimedMsgQueueC() as ListeningQueue,
	new TimedMsgQueueC() as TimeoutQueue,

	new AMSenderC(CAMMSG) as SubSend,
	//SendStubC as SubSend,
	new AMReceiverC(CAMMSG) as SubReceive,
	//ReceiveStubC as SubReceive,
	new AMSnooperC(CAMMSG),
        ActiveMessageC,

	new AODVStubC(),
	PrintfC,
	SerialStartC,
	RandomC;
   
    AMSend = App.AMSend;
    Receive = App.Receive;
    StdControl = App.StdControl;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;
    App.AMControl -> ActiveMessageC;

    App.RoutingQueue->RoutingQueue;
    App.SendingQueue->SendingQueue;
    App.HeardQueue->HeardQueue;
    App.ReceivedQueue->ReceivedQueue;
    App.ListeningQueue->ListeningQueue;
    App.TimeoutQueue->TimeoutQueue;

    App.ListeningTimer->ListeningTimer;
    App.LightTimer->LightTimer;

    // testing only
    //ReceiveControl = SubReceive.ReceiveControl;

    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.SysTime -> SysTime;
    App.Random -> RandomC;    
    App.RouteFinder -> AODVStubC;
}

    

