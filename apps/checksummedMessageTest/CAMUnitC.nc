#include "CAM.h"

generic configuration CAMUnitC(am_id_t AMId) {
    provides {
	interface AMSend;
	interface Receive;
    }
}

implementation {
    components new CAMUnitP(AMId) as App;
    components LedsC;
    components new TimerMilliC() as Timer;
    components new AMSenderC(CAMMSG) as SubSend;
    components new AMReceiverC(CAMMSG) as SubReceive;
    components new AMSnooperC(CAMMSG);
    components new CAMBufferC();
    components new AODVStubC();
    components new RandomC();
   
    AMSend = App.AMSend;
    Receive = App.Receive;

    App.SubSend -> SubSend;
    App.SubReceive -> SubReceive;
    
    App.CAMBuffer -> CAMBufferC;
    App.Snoop -> AMSnooperC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.Random = RandomC;    
    App.RouteFinder -> AODVStubC;

}

    

