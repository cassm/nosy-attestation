configuration LinkControlTestAppC {}
implementation {
    components MainC,
	LinkControlTestC as App,
	LinkControlC,
	PrintfC,
	SerialStartC,
	new TimerMilliC() as Timer,
	ActiveMessageC;
    

    App.Boot -> MainC;
    App.Timer -> Timer;
    App.LinkControl -> LinkControlC;
    App.SplitControl -> ActiveMessageC;
}
	    
