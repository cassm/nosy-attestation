#include "CAM.h"
#include "printf.h"

configuration ReceiveStubC {
    provides interface StdControl as ReceiveControl;
    provides interface Receive;
}
implementation {
    components ReceiveStubP as App,
	new TimerMilliC() as Timer;

    ReceiveControl = App.ReceiveControl;
    Receive = App.Receive;
    App.Timer -> Timer;
}
