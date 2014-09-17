generic configuration MsgQueueC() {
    provides interface MsgQueue;
}
implementation {
    components new MsgQueueP(); 
    MsgQueue = MsgQueueP;
}
