/*  Module implementation for a basic collector network node
 *
 *  Copyright (C) 2014 Cass May
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "Collect.h"
#include "attestation.h"

module MeasurementCollectorC {
    uses {
	interface Boot;
	interface Leds;
	interface Send as Data;
	interface DisseminationValue<dataSettings_t> as DataSettings;
	interface SplitControl as CommControl; 
	interface StdControl as CollectionControl;
	interface StdControl as DisseminationControl;
	interface Timer<TMilli> as Timer;
	interface Read<uint16_t> as Temperature;
	interface Read<uint16_t> as Humidity;
	interface Read<uint16_t> as FullSpectrum;
	interface Read<uint16_t> as PhotoSpectrum;
	interface Send as AttestationResponseSender;
	interface DisseminationValue<AttestationRequestMsg> as AttestationRequestReceiver;
	interface DisseminationValue<attestationNotice_t> as AttestationNotice;
    }
}

implementation {
    bool attestationTime = FALSE;
    bool attestationSending = FALSE;
    uint8_t testVal;
    error_t error;
    message_t msgbuff;
    message_t attestationBuffer;
    bool sending = FALSE;
    dataReading_t* payload;
    dataSettings_t* settingsBuff;

    AttestationRequestMsg* attestationRequestBuffer;
    attestationNotice_t* attestationNoticeBuffer;
    AttestationResponseMsg* response;

    enum { TEMP_READ = 0x1,
	   HUM_READ = 0x2,
	   FULLSPECTRUM_READ = 0x4,
	   PHOTOSPECTRUM_READ = 0x8,
	   ALL_READ = TEMP_READ & HUM_READ & FULLSPECTRUM_READ & PHOTOSPECTRUM_READ };

    uint8_t readingsDone = 0x0;

    uint8_t INVALID_READING = 78;

    uint16_t samplePeriod = 3000,
	retrytime = 50,
	readings[4];

    task void sendReading();
    task void writeReading();
    
    void sendAttestationResponse(uint32_t nonce, uint8_t who);

    uint32_t attestation(uint32_t nonce, uint32_t max) {
	uint16_t i;
	uint32_t checksum;
	uint8_t byte;

	checksum = 0;

	for( i = PROG_MEM_START ; i < max ; i++ ) {
	    byte = pgm_read_byte_far(i);
	    if (nonce % byte & 0x1) { 
		checksum = (checksum + byte) % 4294967296; // 2^32
	    }
	}

	// todo: make the nonce do anything

	return checksum;
    }

    event void Boot.booted() {
	call CommControl.start();
    }

    event void CommControl.startDone(error_t ok) { 
	if (ok != SUCCESS) {
	    call CommControl.start();
	}
	else {
	    call CollectionControl.start();
	    call DisseminationControl.start();
	    call Timer.startPeriodic(samplePeriod);
	}
    }

    event void CommControl.stopDone(error_t error) {}

    event void DataSettings.changed() {
	call Leds.set(0x7);
	settingsBuff = call DataSettings.get();
	testVal = settingsBuff->testVal;
	samplePeriod = settingsBuff->sampleInterval;
	call Timer.stop();
	call Timer.startPeriodic(samplePeriod);
    }


    event void AttestationNotice.changed() {
	attestationNoticeBuffer = call AttestationNotice.get();
	attestationTime = attestationNoticeBuffer->begin;
	if (attestationTime) {
	    call Leds.led2On();
	}
	else {
	   call Leds.led2Off();
	}   
    }

    event void AttestationRequestReceiver.changed() {
	attestationRequestBuffer = call AttestationRequestReceiver.get();
	if (attestationRequestBuffer->who == TOS_NODE_ID) {
	    sendAttestationResponse(attestationRequestBuffer->nonce, attestationRequestBuffer->who);
	}
    }

    void sendAttestationResponse(uint32_t nonce, uint8_t who) {
	uint32_t checksum;
	call Leds.led0On();
	atomic {
	    checksum = attestation(nonce, PROG_MEM_END);
	}
	if(!attestationSending) {
	    response = (AttestationResponseMsg*)(call AttestationResponseSender.getPayload(&attestationBuffer, sizeof(AttestationResponseMsg)));
	    call Leds.led1On();
	    response->nonce = nonce;
	    response->who = who;
	    response->checksum = (uint32_t) checksum;

	    if(call AttestationResponseSender.send(&attestationBuffer, sizeof(AttestationResponseMsg)) == SUCCESS) {
		attestationSending = TRUE;
	    }
	}
    }

    event void AttestationResponseSender.sendDone(message_t *msg, error_t error) {
	if (msg == &attestationBuffer)
	    call Leds.led0Off();
	    call Leds.led1Off();
	    attestationSending = FALSE;
    }



// *********  READING SENDING APPARATUS BEGINS HERE *********** 

    task void sendReading() {
	call Leds.led0On();
	    if (!sending) {
		if ( call Data.send(&msgbuff, sizeof(dataReading_t)) == SUCCESS) {
		    sending =TRUE;
		}
	    }
    }

    event void Data.sendDone(message_t* msg, error_t error) {
	call Leds.led0Off();
	sending = FALSE;
    }


    event void Timer.fired() {
	call Leds.led1On();

	if (call Temperature.read() != SUCCESS) {
	    readings[0] = 0;
	    readingsDone &= TEMP_READ;
	}

	if (call Humidity.read() != SUCCESS) {
	    readings[1] = 0;
	    readingsDone &= HUM_READ;
	}

	if (call FullSpectrum.read() != SUCCESS) {
	    readings[2] = 0;
	    readingsDone &= FULLSPECTRUM_READ;
	}

	if (call PhotoSpectrum.read() != SUCCESS) {
	    readings[3] = 0;
	    readingsDone &= PHOTOSPECTRUM_READ;
	}

	if (readingsDone == ALL_READ)
	    post writeReading();
    }

    event void Temperature.readDone(error_t error, uint16_t val) {
	if (error == SUCCESS) {
	    readings[0] = val;
	}
	else {
	    readings[0] = 0;
	}

	readingsDone &= TEMP_READ;

	if (readingsDone == ALL_READ)
	    post writeReading();
    }

    event void Humidity.readDone(error_t error, uint16_t val) {
	if (error == SUCCESS) {
	    readings[1] = val;
	}
	else {
	    readings[1] = 0;
	}

	readingsDone &= HUM_READ;

	if (readingsDone == ALL_READ)
	    post writeReading();
    }

    event void FullSpectrum.readDone(error_t error, uint16_t val) {
	if (error == SUCCESS) {
	    readings[2] = val;
	}
	else {
	    readings[2] = 0;
	}

	readingsDone &= FULLSPECTRUM_READ;

	if (readingsDone == ALL_READ)
	    post writeReading();
    }

    event void PhotoSpectrum.readDone(error_t error, uint16_t val) {
	if (error == SUCCESS) {
	    readings[3] = val;
	}
	else {
	    readings[3] = 0;
	}

	readingsDone &= PHOTOSPECTRUM_READ;

	if (readingsDone == ALL_READ)
	    post writeReading();
    }
    
    task void writeReading() {

	readingsDone = 0x0;
      
	call Leds.led1Off();

	payload = (dataReading_t*) call Data.getPayload(&msgbuff, sizeof(dataReading_t));

	payload->testVal = testVal;
	payload->who = TOS_NODE_ID;
	payload->temperature = readings[0];
	payload->humidity = readings[1];
	payload->fullSpectrum = readings[2];
	payload->photoSpectrum = readings[3];
	if (!attestationTime) 
	    post sendReading();
    }

}
