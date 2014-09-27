#include "CAM.h"

interface RouteFinder {
    event void nextHopFound( uint8_t nextHop, uint8_t dest );
    command error_t getNextHop( uint8_t dest );
    command error_t hopFailed( uint8_t nektHop, uint8_t dest );
    command uint8_t checkRouting( checksummed_msg_t *payload );
}
