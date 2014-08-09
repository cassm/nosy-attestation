COMPONENT=MeasurementBaseStationAppC
CFLAGS += -DDELUGE_BASESTATION -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/le -I%T/lib/net/drip -DLOW_POWER_LISTENING  
BUILD_EXTRA_DEPS += DataReading.py DataSettings.py AttestationRequest.py AttestationResponse.py
CLEAN_EXTRA = DataReading.py DataSettings.py AttestationRequest.py AttestationResponse.py
BOOTLOADER=tosboot
include $(MAKERULES)

AttestationRequest.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=AttestationRequest Collect.h AttestationRequestMsg -o AttestationRequest.py

AttestationResponse.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=AttestationResponse Collect.h AttestationResponseMsg -o AttestationResponse.py

DataReading.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DataReading Collect.h dataReading -o DataReading.py

DataSettings.py: Collect.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DataSettings Collect.h dataSettings -o DataSettings.py
