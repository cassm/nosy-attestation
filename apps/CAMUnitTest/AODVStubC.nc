generic configuration AODVStubC() {
    provides interface RouteFinder;
}
implementation {
    components new AODVStubP(), 
	new TimerMilliC() as Timer;
    RouteFinder = AODVStubP;
    AODVStubP.Timer->Timer;
}
