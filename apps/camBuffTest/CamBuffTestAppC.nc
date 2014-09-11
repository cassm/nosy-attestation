#include "printf.h"

configuration CamBuffTestAppC {}

implementation {
    components MainC, 
	CamBuffTestC as App,
	new CAMBufferC(),
	new TimerMilliC() as Timer,
	PrintfC, 
	SerialStartC;

    App.Boot -> MainC;
    App.CAMBuffer -> CAMBufferC;
    App.Timer -> Timer;
}
