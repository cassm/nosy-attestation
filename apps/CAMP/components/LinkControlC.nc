configuration LinkControlC {
    provides interface LinkControl;
}

implementation {
    components LinkControlP as App,

	new CAMSenderC(LINKVALMSG),
	new CAMReceiverC(LINKVALMSG),

	new LVMsgQueueC() as ValidationQueue,
	new LVTimedMsgQueueC() as QueryQueue,
        new TimerMilliC() as Timer,
	LocalTimeMilliC as SysTime;

    LinkControl = App;
    App.AMSend->CAMSenderC;
    App.Receive->CAMReceiverC;
    App.ValidationQueue -> ValidationQueue;
    App.QueryQueue -> QueryQueue;
    App.Timer -> Timer;
    App.SysTime -> SysTime;
}
