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
  }
}

implementation {
  uint8_t testVal;
  error_t error;
  message_t msgbuff;
  bool sending = FALSE;
  dataReading_t* payload;
  dataSettings_t* settingsBuff;

  bool TEMP_READ = FALSE,
    HUM_READ = FALSE;

  uint8_t INVALID_READING = 78;

  uint16_t samplePeriod = 3000,
    retrytime = 50,
    readings[2];

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
      call Leds.led1On();
      call Timer.startPeriodic(samplePeriod);
    }
  }

  event void CommControl.stopDone(error_t error) {}

  task void send() {
    if (!sending) {
      if ( call Data.send(&msgbuff, sizeof(dataReading_t)) != SUCCESS) {
	call Leds.led0On();
      }
      else {
	sending =TRUE;
	call Leds.led1On();
      }
    }
  }

  event void DataSettings.changed() {
    call Leds.set(0x7);
    settingsBuff = call DataSettings.get();
    testVal = settingsBuff->testVal;
    samplePeriod = settingsBuff->sampleInterval;
    call Timer.stop();
    call Timer.startPeriodic(samplePeriod);
  }

  task void write() {
    TEMP_READ = FALSE;
    HUM_READ = FALSE;

    call Leds.led2Off();

   payload = (dataReading_t*) call Data.getPayload(&msgbuff, sizeof(dataReading_t));

   payload->testVal = testVal;
   payload->who = TOS_NODE_ID;
   payload->temperature = readings[0];
   payload->humidity = readings[1];
    
   post send();
  }

  event void Data.sendDone(message_t* msg, error_t error) {
    call Leds.set(0);
    sending = FALSE;
  }

  event void Timer.fired() {
    call Leds.set(0);
    call Leds.led1On();

    if (call Temperature.read() != SUCCESS) {
      readings[0] = 0;
      TEMP_READ = TRUE;
    }

    if (call Humidity.read() != SUCCESS) {
      readings[1] = 0;
      HUM_READ = TRUE;
    }
    if (TEMP_READ && HUM_READ)
      post write();
  }

  event void Temperature.readDone(error_t error, uint16_t val) {
    if (error == SUCCESS) {
      readings[0] = val;
    }
    else {
      readings[0] = 0;
    }

    TEMP_READ = TRUE;

    if (TEMP_READ && HUM_READ)
      post write();
  }

  event void Humidity.readDone(error_t error, uint16_t val) {
    if (error == SUCCESS) {
      readings[1] = val;
    }
    else {
      readings[1] = 0;
    }

    HUM_READ = TRUE;

    if (TEMP_READ && HUM_READ)
      post write();
  }
}
