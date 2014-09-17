#include "CAM.h"

generic configuration TimedMsgQueueC() {
    provides interface TimedMsgQueue;
}
implementation {
    components new TimedMsgQueueP;
    TimedMsgQueue = TimedMsgQueueP;
}
