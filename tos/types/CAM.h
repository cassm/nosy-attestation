#ifndef CAM_H
#define CAM_H

#include "message.h"

enum { CAMMSG = 97,
       TESTMSG = 98,
       MAX_PAYLOAD = (TOSH_DATA_LENGTH - 9),
       CAM_TIMEOUT = 50,
       CAM_RETRIES = 3,

       CAM_SUCCESS = 0,
       CAM_RETRY = 1,
       CAM_ABORT = 2,

       CAM_BUFFER_SIZE = 10,
       CAM_MAX_RETRIES = 3
};

typedef nx_struct cam_ack_msg_t {
    nx_uint8_t dsn;
    nx_uint8_t status;
} cam_ack_msg_t;

typedef nx_struct cam_buffer_t {
    nx_uint32_t alarmtime;
    nx_bool inUse;
    nx_bool locked;
    message_t message;
    nx_uint8_t retries;
} cam_buffer_t;

// note - this type reduces the maximum data payload by 4 bytes, due to checksum size.
typedef nx_struct checksummed_msg_t {
    nx_uint32_t checksum;
    nx_uint8_t ID;
    nx_uint8_t dest;
    nx_uint8_t src;
    nx_uint8_t type;
    nx_uint8_t len;
    nx_uint8_t data[MAX_PAYLOAD];
} checksummed_msg_t;

typedef nx_struct testmsg_t {
    nx_uint8_t val1;
    nx_uint32_t val2;
} testmsg_t;

// N.B. - This function only performs correctly on 
uint32_t checksum_msg(message_t *msg) {
    uint32_t checksum = 0;
    uint8_t i;
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
