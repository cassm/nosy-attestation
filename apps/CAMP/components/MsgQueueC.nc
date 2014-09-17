configuration MsgQueueC {
    provides interface MsgQueue;
}
implementation {
    components MsgQueueP; 
    MsgQueue = MgQueueP;
}
