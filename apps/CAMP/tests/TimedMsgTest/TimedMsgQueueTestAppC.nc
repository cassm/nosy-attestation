#include "printf.h"

configuration TimedMsgQueueTestAppC {}
implementation {
    components MainC, 
	PrintfC,
	SerialStartC,
	TimedMsgQueueTestC as App,
	new TimedMsgQueueC() as Queue1,
        new TimedMsgQueueC() as Queue2;
    App.Boot -> MainC;
    App.Queue1 -> Queue1;
    App.Queue2 -> Queue2;
}
