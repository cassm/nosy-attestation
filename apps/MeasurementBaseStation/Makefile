COMPONENT=MeasurementBaseStationAppC
CFLAGS += -DDELUGE_BASESTATION -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/le -I%T/lib/net/drip -DLOW_POWER_LISTENING  
# BUILD_EXTRA_DEPS += BaseStationCommunicator 
# CLEAN_EXTRA = BaseStationCommunicator $(patsubst %, BaseStationCommunicator%, .c .h) dataReading*
BOOTLOADER=tosboot
include $(MAKERULES)
# TOSDIR = /opt/tinyos-2.1.2/tos/
# GCC_INCLUDE = $(`find /opt/tinyos-2.1.2/tos/ -type d | sed s/^/-I\ /`)
# OTHERCONST = -I $(TOSDIR)types/ -I $(TOSDIR)platforms/telosb/mac/tkn154/ -I $(TOSDIR)platforms/telosb/mac/tkn154/timer/ -I $(TOSDIR)/lib/serial/ -I $(TOSDIR)/lib/mac/tkn154/ -I $(TOSDIR)/chips/cc2420_tkn154/ -I $(TOSDIR)/../support/sdk/c/sf/


# BaseStationCommunicator: CFLAGS   += -I/opt/tinyos-2.x/support/sdk/c/sf -g --std=c99
# BaseStationCommunicator: LDFLAGS  += -L/opt/tinyos-2.x/support/sdk/c/sf -g

# BaseStationCommunicator.o: BaseStationCommunicator.cpp
# 	g++ -c $(OTHERCONST) $(CXXFLAGS) BaseStationCommunicator.cpp -o BaseStationCommunicator.o 

# BaseStationCommunicator: BaseStationCommunicator.o dataReading.o
# 	g++ -o $@ $(LDFLAGS) $^ -lmote

# dataReading.c: Collect.h
# 	mig -o dataReading.h c $^ dataReading

# idfk

#	cat dataReading.h | sed "s/AM_DATAREADING = [0-9]*/`ncg c Collect.h AM_BLAH_SERIAL_MSG | grep AM_BLAH_SERIAL_MSG`/" > serread.h.tmp
#	mv serread.h.tmp serread.h







#CLEAN_EXTRA = *.o dataReading.h BaseStationCommunicator

#dataReading.h:
#	mig c -target=telosb -c-classname=dataReading Collect.h dataReading -o $@

#BaseStationCommunicator: BaseStationCommunicator.cpp dataReading.h
#	g++ -g -Wall $(GCC_INCLUDE) BaseStationCommunicator.cpp -o BaseStationCommunicator

