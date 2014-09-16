generic configuration CAMBufferC() {
    provides interface CAMBuffer;
}
implementation {
    components new CAMBufferP();
    CAMBuffer = CAMBufferP;
}
