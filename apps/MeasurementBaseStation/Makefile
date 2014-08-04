COMPONENT=MeasurementBaseStationAppC
CFLAGS += -DDELUGE_BASESTATION -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/le -I%T/lib/net/drip -DLOW_POWER_LISTENING  
BUILD_EXTRA_DEPS += DataReading.py DataSettings.py
CLEAN_EXTRA = DataReading.py DataSettings.py
BOOTLOADER=tosboot
include $(MAKERULES)

DataReading.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DataReading Collect.h dataReading -o DataReading.py

DataSettings.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DataSettings Collect.h dataSettings -o DataSettings.py
