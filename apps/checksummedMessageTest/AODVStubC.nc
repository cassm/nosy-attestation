generic configuration AODVStubC() {
    provides interface RouteFinder;
}
implementation {
    components new AODVStubP;    
    RouteFinder = AODVStubP;
}
