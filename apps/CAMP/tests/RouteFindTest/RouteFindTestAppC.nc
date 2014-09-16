#include "printf.h"

configuration RouteFindTestAppC {}

implementation {
    components MainC, 
	RouteFindTestC as App,
	new AODVStubC(),
	new TimerMilliC() as Timer,
	PrintfC, 
	SerialStartC;

    App.Boot -> MainC;
    App.RouteFinder -> AODVStubC;
    App.Timer -> Timer;
}
