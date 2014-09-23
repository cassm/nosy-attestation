#ifndef CAM_H
#define CAM_H

#include "message.h"

enum { DIGESTMSG = 95,
       REPORTMSG = 96,
       CAMMSG = 97,
       TESTMSG = 98,
       LINKVALMSG = 99,
       MAX_PAYLOAD = (TOSH_DATA_LENGTH - 13),
       CAM_TIMEOUT = 50,
       CAM_RETRIES = 3,

       BASE_STATION_ID = 0,

       UNKNOWN = 0,
       PERMITTED = 1,
       FORBIDDEN = 2,
       INVALID = 3,
       GOOD = 4,
       BAD = 5,
       NONOPTIMAL = 6,
       UPSTREAM = 7,
       DROPPED = 8,

       CAM_QUEUE_SIZE = 10,
       CAM_MAX_RETRIES = 3,

       LQI_DIFF_THRESHOLD = 25,

       MAX_NETWORK_SIZE = 10,

       ROUTING_DELAY = 80,
       CAM_FWD_TIMEOUT = 1250,
       CAM_EAVESDROPPING_TIMEOUT = 1500,
       SIGFLASH_DURATION = 1000


};

nx_struct msg_digest_t {
    nx_uint16_t h_src; 
    nx_uint8_t h_dest;
    nx_uint8_t h_len;

    nx_uint8_t src;
    nx_uint8_t prev;
    nx_uint8_t curr;
    nx_uint8_t next;
    nx_uint8_t dest;

    nx_uint8_t type;
    nx_uint8_t id;
    nx_uint8_t len;
    nx_uint8_t lqi;
} msg_digest_t;

nx_struct msg_analytics_t {
    // internal checks
    nx_bool headers_agree;
    nx_bool valid_len;
    nx_bool anomalous_lqi;
    nx_bool first_time_heard;
    nx_bool checksum_correct;

    // buffer checks
    nx_uint8_t checksum_matches;
    nx_uint8_t payload_matches;
    
    // routing checks
    nx_uint8_t valid_routing;
    nx_uint8_t link_status;
} msg_analytics_t;

typedef union msg_report_t {
    msg_digest_t digest;
    msg_analysis_t analytics;
}

typedef nx_struct link_validation_msg_t {
    nx_uint8_t src;
    nx_uint8_t dest;
    nx_uint8_t status;
} link_validation_msg_t;

typedef nx_struct cam_ack_msg_t {
    nx_uint8_t dsn;
    nx_uint8_t status;
} cam_ack_msg_t;

typedef nx_struct cam_buffer_t {
    nx_uint8_t index;
    nx_bool inUse;
    message_t message;
} cam_buffer_t;

// note - this type reduces the maximum data payload by 4 bytes, due to checksum size.
typedef nx_struct checksummed_msg_t {
    nx_uint32_t checksum;
    nx_uint8_t ID;

    nx_uint8_t src;
    nx_uint8_t dest;

    nx_uint8_t prev;
    nx_uint8_t curr;
    nx_uint8_t next;

    nx_uint8_t type;
    nx_uint8_t len;
    nx_uint8_t data[MAX_PAYLOAD];
    nx_uint8_t retry;
} checksummed_msg_t;

typedef nx_struct testmsg_t {
    nx_uint8_t val1;
    nx_uint32_t val2;
} testmsg_t;

bool inChronologicalOrder(uint32_t t1, uint32_t t2) {
    // if a time is more than 0.75*2^32 ms later, assume instead that it is less than 0.25*2^32 ms 
    // earlier. This deals with intervals which span a wrap.

    // find earliest time, accounting for wraps


    uint32_t wrapThreshold = -1;
    wrapThreshold /= 4;
  
    return ( (t1 < t2 && (t1 - t2 > wrapThreshold * 3))
	     || t1 - t2 > wrapThreshold );
}

// N.B. - This function only performs correctly on 
uint32_t checksum_msg(message_t *msg) {
    uint32_t checksum = 0;

    checksummed_msg_t *payload;

    // TODO: cut down checksum to only parity-checked parts of message

    // checksum header
    for ( i = 0 ; i < sizeof(message_header_t) ; i++ )
	checksum += (uint8_t) *(msg->header+i);

    // checksum footer
    for ( i = 0 ; i < sizeof(message_footer_t) ; i++ )
	checksum += (uint8_t) *(msg->footer+i);
/*
    // checksum metadata
    for ( i = 0 ; i < sizeof(message_metadata_t) ; i++ )
	checksum += (uint8_t) *(msg->metadata+i);

    // discard timestamp from check
    cc2420_metadata_t *metadata;
    metadata = (cc2420_metadata_t*) &(msg->metadata);
    checksum -= metadata->timestamp;

*/
    // checksum data
    payload = (checksummed_msg_t*) msg->data;

    checksum += payload->type;
    checksum += payload->len;
    for ( i = 0 ; i < MAX_PAYLOAD ; i++ )
	checksum += *(payload->data + i);

    return checksum;
}

#endif
