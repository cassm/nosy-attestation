/*  Configuration for a basic collector network node
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

configuration MeasurementCollectorAppC {
}
implementation {
  components MeasurementCollectorC as App, MainC, LedsC, ActiveMessageC;
  components DelugeC;
  components CollectionC, DisseminationC;
  components new CollectionSenderC(AM_DATAREADING),
    new DisseminatorC(dataSettings_t, AM_DATASETTINGS),
    new SensirionSht11C() as TempAndHumid,
    new TimerMilliC() as Timer,
    new TimerMilliC() as BusyTimer;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.CommControl -> ActiveMessageC;
  App.CollectionControl -> CollectionC;
  App.DisseminationControl -> DisseminationC;
  App.DataSettings -> DisseminatorC;

  App.Timer -> Timer;
  App.Temperature -> TempAndHumid.Temperature;
  App.Humidity -> TempAndHumid.Humidity;
  App.Data -> CollectionSenderC;
}
