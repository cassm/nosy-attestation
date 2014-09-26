#include "CAM.h"

module PacketCheckerP {
    provides interface PacketChecker;
    uses interface LinkStrengthLog;
    uses interface LinkControl;
}
implementation {
    command uint8_t checkConsistency(message_t *msg) {
	message_t reportBuffer;
	report_msg_t *reportPayload;

	cc2420_header_t *headerPtr;
	
	checksummed_message_t *payload;
	
	headerPtr = &((message_header_t*)msg->header)->cc2420;
	payload = (checksummed_message_t*) msg->data;
	reportPayload = &reportBuffer.data;

	

	if ( headerPtr->src != payload->curr ) {
	}

	if ( headerPtr->dest != payload->next ) {
	}

	// check if this sender has been heard from for the first time
	if ( !LinkStrengthLog.getLqi(headerPtr->src) ) {
	}

	// check if sender has abnormal LQI
	if ( LinkStrengthLog.getLqiDiff(msg) > LQI_DIFF_THRESHOLD ) {
	}

	// check checksum
	if ( checksum_msg(msg) != payload->checksum ) {
	    // do some kind of thing
	}
    } 
}
