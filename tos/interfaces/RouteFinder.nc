#include "CAM.h"

interface RouteFinder {
    event void nextHopFound( uint8_t nextHop, uint8_t msgId, uint8_t src, error_t ok );
    command error_t getNextHop( uint8_t dest_ID , uint8_t msg_ID , uint8_t src_ID );
    command error_t hopFailed( uint8_t dest_ID, uint8_t next_ID, uint8_t src_ID , uint8_t msg_ID );
    command uint8_t checkRouting(checksummed_msg_t *payload) {
}
