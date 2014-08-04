#include <stdint.h>
#include <stdio.h>
#include "dataReading.h"
#include "serialsource.h"

int main(void)
{
    struct serial_source* port = open_serial_source("/dev/ttyUSB0", 112500,
						    0, NULL);

    if(port == NULL)
    {
	fprintf(stderr, "Couldn't open port\n");
	return -1;
    }

  
    while(1)
    {
    int len;
    void* packet = read_serial_packet(port, &len);
    if(packet == NULL)
	break;

    if(((unsigned char*)packet)[7] == AM_DATAREADING)
    {
	struct tmsg msg = {.data = packet+len-DATAREADING_SIZE, .len = len};
	printf("Temp: %d\n", dataReading_temperature_get(&msg)); // this is one of the functions defined in the generated serread.h file
    }
}

    close_serial_source(port);
return 0;
}
