configuration LinkControlTestAppC {}
implementation {
    components MainC,
	LinkControlTestC as App,
	LinkControlC,
	PrintfC,
	SerialStartC,
	new TimerMilliC() as Timer,
	CAMUnitC,
	ActiveMessageC;
    

    App.Boot -> MainC;
    App.CAMControl -> CAMUnitC;
    App.Timer -> Timer;
    App.LinkControl -> LinkControlC;
    App.SplitControl -> ActiveMessageC;
}
	    
