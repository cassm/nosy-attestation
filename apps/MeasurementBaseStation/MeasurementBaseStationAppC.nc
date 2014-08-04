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
  components DelugeC;
  components MeasurementBaseStationC as App;
  components SerialActiveMessageC as Serial;
  components CollectionC, DisseminationC, ActiveMessageC;
  components new SerialAMSenderC(AM_DATAREADING) as UartSend;
  components new DisseminatorC(dataSettings_t, AM_DATASETTINGS);
  //components new SerialAMReceiverC(DATA_SETTINGS) as DataSettingsReceive;
  
  components new TimerMilliC() as SwitchTimer;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> Serial;
  App.CollectionControl -> CollectionC;
  App.DisseminationControl -> DisseminationC;
  App.RootControl -> CollectionC;
  
  App.UartSend -> UartSend;
  //App.DataSettingsReceive -> DataSettingsReceive;
  
  App.ReceiveReading -> CollectionC.Receive[AM_DATAREADING];
  App.DataSettings -> DisseminatorC;

  App.SwitchTimer -> SwitchTimer;
}
