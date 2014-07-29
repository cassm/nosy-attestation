/*  Configuration for a basic collector network base station
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

configuration MeasurementBaseStationAppC {}

implementation {
  components MainC, LedsC;
  components MeasurementBaseStationC as App;
  components SerialActiveMessageC as Serial;
  components CollectionC, ActiveMessageC;
  components new SerialAMSenderC(DATA_COL_UART) as UartSend;
  //components new SerialAMReceiverC(DATA_COL_UART) as UartReceive;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> Serial;
  App.CollectionControl -> CollectionC;
  App.RootControl -> CollectionC;
  
  App.UartSend -> UartSend;
  //BaseStationP.UartReceive -> UartReceive;
  
  App.ReceiveReading -> CollectionC.Receive[DATA_COL];
}
