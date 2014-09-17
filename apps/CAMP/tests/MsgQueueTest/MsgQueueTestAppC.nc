#include "printf.h"

configuration MsgQueueTestAppC {}
implementation {
    components MainC, 
	PrintfC,
	SerialStartC,
	MsgQueueTestC as App,
	new MsgQueueC() as Queue1,
        new MsgQueueC() as Queue2;
    App.Boot -> MainC;
    App.Queue1 -> Queue1;
    App.Queue2 -> Queue2;
}
