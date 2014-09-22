generic configuration CAMReceiverC(am_id_t AMId) {
    provides interface Receive;
}
implementation {
    components new CAMReceiverP(AMId),
	CAMUnitC;
    Receive = CAMReceiverP.Receive;
    CAMReceiverP.SubReceive -> CAMUnitC;
}
