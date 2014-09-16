#include "CAM.h"
#include "printf.h"

configuration CAMBufferTestAppC {}

implementation {
    components MainC,
	CAMBufferTestC as App,
	new CAMBufferC(),
	PrintfC,
	SerialStartC;

    App.Boot -> MainC;
    App.CAMBuffer -> CAMBufferC;
}
