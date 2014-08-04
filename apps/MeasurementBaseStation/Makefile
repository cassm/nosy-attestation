COMPONENT=MeasurementBaseStationAppC
CFLAGS += -DDELUGE_BASESTATION -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/le -I%T/lib/net/drip -DLOW_POWER_LISTENING  
BUILD_EXTRA_DEPS += DataReading.py
CLEAN_EXTRA = DataReading.py
BOOTLOADER=tosboot
include $(MAKERULES)

DataReading.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DataReading Collect.h dataReading -o DataReading.py
