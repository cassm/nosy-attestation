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

module MeasurementBaseStationC {
  uses {
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;    
    interface StdControl as CollectionControl;
    interface StdControl as DisseminationControl;
    interface Leds;
    interface Boot;
    interface RootControl;
    interface Receive as ReceiveReading;

    interface DisseminationUpdate<dataSettings_t> as DataSettings;
    interface AMSend as UartSend;
    //interface Receive as DataSettingsReceive;
    interface Timer<TMilli> as SwitchTimer;
  }
}

implementation {
  dataSettings_t settBuff;
  dataReading_t radioDataBuff, 
    serialDataBuff;
  message_t radioMsgBuff,
    serialMsgBuff;
  dataReading_t *radioPayload;
  dataReading_t *serialPayload;
  bool radioBusy = FALSE,
    serialBusy = FALSE,
    serialStarted = FALSE;

  task void uartSendTask();

  event void Boot.booted() {
    call Leds.led2On();
    call RadioControl.start();
    call SerialControl.start();
  }

  event void RadioControl.startDone(error_t ok) {
    if (ok != SUCCESS) 
      call RadioControl.start();
    else {
      call CollectionControl.start();
      call DisseminationControl.start();
      call RootControl.setRoot();
      call SwitchTimer.startOneShot(30000);
    }
  }

  event void SwitchTimer.fired() {
    settBuff.testVal = 55;
    settBuff.sampleInterval = 10000;
    call DataSettings.change(&settBuff);
  }

  event void SerialControl.startDone(error_t ok) {
    serialStarted = TRUE;
  }

  event void RadioControl.stopDone(error_t error) {}

  event void SerialControl.stopDone(error_t error) {}

  task void uartSendTask() {
    call Leds.led1Off();
    call Leds.led0On();
    if (serialStarted && !serialBusy) {
      serialPayload = call UartSend.getPayload(&serialMsgBuff, sizeof(dataReading_t));
      if (serialPayload) {
	*serialPayload = serialDataBuff;
	if (call UartSend.send(AM_BROADCAST_ADDR, &serialMsgBuff, sizeof(dataReading_t)))
	    serialBusy = FALSE;
      }
    }
  }

  event void UartSend.sendDone(message_t *msg, error_t error) {
    serialBusy = FALSE;
    call Leds.led0Off();
  }
  
  event message_t *ReceiveReading.receive(message_t *msg, void *payload, uint8_t len) {
    call Leds.led1On();
    radioPayload = payload;
    serialDataBuff.who = radioPayload->who;
    serialDataBuff.temperature = radioPayload->temperature;
    serialDataBuff.humidity = radioPayload->humidity;
    post uartSendTask();
    return msg;
  }
}    
