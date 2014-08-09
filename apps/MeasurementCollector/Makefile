COMPONENT=MeasurementCollectorAppC
CFLAGS += -DLOW_POWER_LISTENING -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/le -I%T/lib/net/drip
BUILD_EXTRA_DEPS += dataReading.class
CLEAN_EXTRA = *.class dataReading.java
BOOTLOADER = tosboot

dataReading.class: $(wildcard *.java) dataReading.java
	javac *.java

dataReading.java:
	mig java -target=null -java-classname=dataReading Collect.h dataReading -o $@

include $(MAKERULES)

PFLAGS += -DSENSOR attestation.c
