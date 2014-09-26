configuration PacketCheckerC {  
    provides interface PacketChecker;
}
implementation {
    components PacketCheckerP,
	LinkCheckerC,
	LinkStrengthLogC;
    PacketChecker = PacketCheckerP;
    PacketCheckerP.LinkChecker -> LinkCheckerC;
    PacketCheckerP.LinkStrengthLog -> LinkStrengthLogC;
}
