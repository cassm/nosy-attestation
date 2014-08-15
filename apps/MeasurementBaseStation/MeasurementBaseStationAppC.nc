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
#include "attestation.h"

configuration MeasurementBaseStationAppC {}

implementation {
    components MainC, LedsC, DelugeC, CollectionC, DisseminationC, ActiveMessageC,
   	       MeasurementBaseStationC as App,
	       SerialActiveMessageC as Serial;

    components new SerialAMSenderC(AM_DATAREADING) as UartSend,
               new DisseminatorC(dataSettings_t, AM_DATASETTINGS),
               new SerialAMReceiverC(AM_DATASETTINGS) as DataSettingsReceive,
	       
	       new DisseminatorC(attestationNotice_t, AM_ATTESTATIONNOTICE) as RadioAttestationNotice,
	       new DisseminatorC(AttestationRequestMsg, AM_ATTESTATIONREQUESTMSG) as RadioAttestationRequest,

               new SerialAMReceiverC(AM_ATTESTATIONREQUESTMSG) as SerialAttestationRequest,
               new SerialAMSenderC(AM_ATTESTATIONRESPONSEMSG) as SerialAttestationResponse,         
	       new TimerMilliC() as SwitchTimer;

    App.Boot -> MainC;
    App.Leds -> LedsC;
    
    App.SerialAttestationResponse -> SerialAttestationResponse;
    App.SerialAttestationRequest -> SerialAttestationRequest;
    App.RadioAttestationResponse -> CollectionC.Receive[AM_ATTESTATIONRESPONSEMSG];
    App.RadioAttestationRequest -> RadioAttestationRequest;
    App.RadioAttestationNotice -> RadioAttestationNotice;



    App.RadioControl -> ActiveMessageC;
    App.SerialControl -> Serial;
    App.CollectionControl -> CollectionC;
    App.DisseminationControl -> DisseminationC;
    App.RootControl -> CollectionC;
    App.UartSend -> UartSend;
    App.DataSettingsReceive -> DataSettingsReceive;
    App.ReceiveReading -> CollectionC.Receive[AM_DATAREADING];
    App.DataSettings -> DisseminatorC;
    App.SwitchTimer -> SwitchTimer;

}
