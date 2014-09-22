module LinkStrengthLogP { 
    provides interface LinkStrengthLog;
}
implementation {
    uint8_t strengths[256];

    command uint8_t LinkStrengthLog.update(message_t *msg) {
	message_metadata_t *metadataPtr;
	message_header_t *headerPtr;
	uint8_t src;
	uint8_t lqi;

	headerPtr = (message_header_t*) msg->header;
	metadataPtr = (message_metadata_t*) msg->metadata;

	// extract source and link quality indicator from message
	src = headerPtr->cc2420.src;
	lqi = metadataPtr->cc2420.lqi; 

	if (strengths[src] == 0) {
	    // first time we have heard from this node
	    strengths[src] = lqi;
	}

	else {
	    // low pass filter 
	    // lqi on the cc2420 varies between 50 and 110

	    // for computational simplicity, weight previous and current value 50/50
	    strengths[src] = (strengths[src] >> 1) + (lqi >> 1);
	}

	return src;
    }

    command uint8_t LinkStrengthLog.getLqiDiff(message_t *msg) {
	message_metadata_t *metadataPtr;
	message_header_t *headerPtr;
	uint8_t src;
	uint8_t lqi;
	uint8_t result;
	headerPtr = (message_header_t*) msg->header;
	metadataPtr = (message_metadata_t*) msg->metadata;

	// extract source and link quality indicator from message
	src = headerPtr->cc2420.src;
	lqi = metadataPtr->cc2420.lqi; 
	
	result = strengths[src] - lqi;

	if ( result < 0 )
	    return -1 * result;
	return result;
    }

    command uint8_t LinkStrengthLog.getLqi(uint8_t node) {
	return strengths[node];
    }
}
