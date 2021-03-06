#include "CAM.h"

configuration CAMUnitC {
    provides {
	interface AMSend;
	interface CAMReceive;
	interface SplitControl;
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
	new TimerMilliC() as ReportTimer,

	new MsgQueueC() as RoutingQueue,
	new MsgQueueC() as SendingQueue,
	new MsgQueueC() as HeardQueue,
	new MsgQueueC() as ReceivedQueue,
	new MsgQueueC() as ReportingQueue,
	new MsgQueueC() as ValidationQueue,
	new TimedMsgQueueC() as ListeningQueue,
	new TimedMsgQueueC() as TimeoutQueue,

	new AMSenderC(CAMMSG) as SubSend,
	//SendStubC as SubSend,
	new AMReceiverC(CAMMSG) as SubReceive,
	//ReceiveStubC as SubReceive,
	new AMSnooperC(CAMMSG),
        ActiveMessageC,
	new AMSenderC(REPORTMSG) as ReportSend,
	new AMSenderC(DIGESTMSG) as DigestSend,
	new AMReceiverC(DIGESTMSG) as DigestReceive,
	new AMReceiverC(REPORTMSG) as ReportReceive,

	LinkStrengthLogC as LinkStrengthLog,
	LinkControlC as LinkControl,

	AODVStubC as RouteFinder,
	PrintfC,
	SerialStartC,
	RandomC;
   
    AMSend = App.AMSend;
    CAMReceive = App.CAMReceive;
    SplitControl = App.SplitControl;

    App.AODVControl -> RouteFinder.SplitControl;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;
    App.AMControl -> ActiveMessageC;
    App.ReportSend -> ReportSend;
    App.DigestSend -> DigestSend;
    App.DigestReceive -> DigestReceive;
    App.ReportReceive -> ReportReceive;

    App.LinkStrengthLog -> LinkStrengthLog;
    App.LinkControl -> LinkControl;
    App.LinkSplitControl -> LinkControl;

    App.RoutingQueue->RoutingQueue;
    App.SendingQueue->SendingQueue;
    App.HeardQueue->HeardQueue;
    App.ReceivedQueue->ReceivedQueue;
    App.ReportingQueue->ReportingQueue;
    App.ListeningQueue->ListeningQueue;
    App.TimeoutQueue->TimeoutQueue;
    App.ValidationQueue->ValidationQueue;

    App.ListeningTimer->ListeningTimer;
    App.LightTimer->LightTimer;
    App.ReportTimer->ReportTimer;
    // testing only
    //ReceiveControl = SubReceive.ReceiveControl;

    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.SysTime -> SysTime;
    App.Random -> RandomC;    
    App.RouteFinder -> RouteFinder;
}

    

