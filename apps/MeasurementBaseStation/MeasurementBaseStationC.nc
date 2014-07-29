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

#include "printf.h"
#include "Collect.h"

module MeasurementBaseStationC {
  uses {
    interface SplitControl as CommControl;
    interface StdControl as CollectionControl;
    interface Leds;
    interface Boot;
    interface RootControl;
    interface Receive as ReceiveReading;
  }
}

implementation {
  dataReading_t newData;
  message_t msgbuff;
  dataReading_t *dataPointer;
  bool busy = FALSE;

  event void Boot.booted() {
    call Leds.led2On();
    call CommControl.start();
  }

  event void CommControl.startDone(error_t ok) {
    if (ok != SUCCESS) 
      call CommControl.start();
    else {
      call CollectionControl.start();
      call RootControl.setRoot();
    }
  }

  event void CommControl.stopDone(error_t error) {}

  task void printData() {
    printf("\tNode %d reports: T = %d H = %d\n", newData.who, newData.temperature, newData.humidity);
    printfflush();
    call Leds.led1Off();
  }

  event message_t *ReceiveReading.receive(message_t *msg, void *payload, uint8_t len) {
    call Leds.led1On();
    dataPointer = payload;
    newData.who = dataPointer->who;
    newData.temperature = dataPointer->temperature;
    newData.humidity = dataPointer->humidity;
    post printData();
    return msg;
  }
}
    
