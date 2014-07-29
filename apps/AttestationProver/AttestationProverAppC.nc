/*  Configuration file for the AttestationProverC mock attestation module in TinyOS
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

#include "TinyAttest.h"

configuration AttestationProverAppC {}

implementation {
  components MainC, DriverC as App, AttestationProverC, LedsC;
  components new TimerMilliC() as Timer;
  components new AMSenderC(AM_AT_RESPONSE_MSG);
  components new AMReceiverC(AM_AT_CHALLENGE_MSG);
  components ActiveMessageC;
  components RandomC;

  App.Boot -> MainC.Boot;

  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.Packet -> AMSenderC;
  App.Attest -> AttestationProverC;

  AttestationProverC.Timer -> Timer;
  AttestationProverC.Random -> RandomC;
}
