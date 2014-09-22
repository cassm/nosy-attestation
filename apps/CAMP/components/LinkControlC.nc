configuration LinkControlC {
    provides interface LinkControl;
}

implementation {
    components LinkControlP as App,

	// do the camsenderc and camreceiverc
	new AMSenderC(LINKVALMSG),
	new AMReceiverC(LINKVALMSG),

	new LVMsgQueueC() as ValidationQueue,
	new LVTimedMsgQueueC() as QueryQueue,
        new TimerMilliC() as Timer,
	LocalTimeMilliC as SysTime;

    LinkControl = App;
    App.AMSend->AMSenderC;
    App.Receive->AMReceiverC;
    App.ValidationQueue -> ValidationQueue;
    App.QueryQueue -> QueryQueue;
    App.Timer -> Timer;
    App.SysTime -> SysTime;
}
