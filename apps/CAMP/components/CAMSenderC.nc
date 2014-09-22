generic configuration CAMSenderC(am_id_t AMId) {
    provides interface AMSend;
}
implementation {
    components new CAMSenderP(AMId) as App,
	CAMUnitC;
    AMSend = App;
    App.SubSend -> CAMUnitC.AMSend;
}


