configuration AODVStubC {
    provides interface RouteFinder;
    provides interface SplitControl;
}
implementation {
    components AODVStubP, 
	new TimerMilliC() as Timer;
    RouteFinder = AODVStubP;
    SplitControl = AODVStubP;
    AODVStubP.Timer->Timer;
}
