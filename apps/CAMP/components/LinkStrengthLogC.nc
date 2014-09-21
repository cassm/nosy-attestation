configuration LinkStrengthLogC {
    provides interface LinkStrengthLog;
}
implementation {
    components LinkStrengthLogP;
    LinkStrengthLog = LinkStrengthLogP;
}
