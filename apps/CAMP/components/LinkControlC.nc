#include "printf.h"
configuration LinkControlC {
    provides interface LinkControl;
    provides interface SplitControl;
}

implementation {
    components LinkControlP as App,
	PrintfC,
	SerialStartC,

	new CAMSenderC(LINKVALMSG),
	new CAMReceiverC(LINKVALMSG),
	new AMSenderC(BEACONMSG) as BeaconSender,
	new AMReceiverC(BEACONMSG) as BeaconReceiver,
	new AMSenderC(BEACONUPDATEMSG) as BeaconUpdateSender,
	new AMReceiverC(BEACONUPDATEMSG) as BeaconUpdateReceiver,

	LinkStrengthLogC,
	LedsC,

	new MsgQueueC() as ValidationQueue,
	new TimedMsgQueueC() as QueryQueue,
        new TimerMilliC() as Timer,
	new TimerMilliC() as BeaconTimer,
	new TimerMilliC() as BeaconPhaseTimer,
	LocalTimeMilliC as SysTime;

    LinkControl = App;
    SplitControl = App;
    App.LinkStrengthLog -> LinkStrengthLogC;
    App.Leds->LedsC;
    App.AMSend -> CAMSenderC;
    App.Receive -> CAMReceiverC;
    App.BeaconSend -> BeaconSender;
    App.BeaconReceive -> BeaconReceiver;
    App.BeaconUpdateSend -> BeaconUpdateSender;
    App.BeaconUpdateReceive -> BeaconUpdateReceiver;
    App.BeaconTimer -> BeaconTimer;
    App.BeaconPhaseTimer -> BeaconPhaseTimer;
    App.ValidationQueue -> ValidationQueue;
    App.QueryQueue -> QueryQueue;
    App.Timer -> Timer;
    App.SysTime -> SysTime;
}
