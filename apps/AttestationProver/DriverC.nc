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

module DriverC {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Leds;
    interface Packet;
    interface Attest;
  }
}

implementation {
  message_t msgBuff;
  attestationChallenge_t challenge;
  attestationChallenge_t *newChallenge;
  bool radioBusy = FALSE;
  bool attestationBusy = FALSE;
  nx_uint16_t verifierID;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.start();
    }
  }

  task void runAttestation() { 
    call Leds.led0On();

    if (challenge.instruction == CANCEL) {
      call Leds.led0Off();  
      call Attest.cancel(challenge.who);
    }
    else if (challenge.instruction == ATTEST) {
      call Attest.attest(challenge.who, &challenge);
    }
    else {
      call Leds.led2On();
    }  
  }
    
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    if (len != sizeof(attestationChallenge_t)) {return msg;}
    newChallenge = payload;
    challenge.who = newChallenge->who;
    challenge.payload = newChallenge->payload;
    challenge.instruction = newChallenge->instruction;
    verifierID = challenge.who;
    attestationBusy = TRUE;
    post runAttestation();
    return msg;
  }

  event void Attest.attestationDone(attestationChallenge_t *response, attestationResult_t result) {
    attestationBusy = FALSE;
    newChallenge = call AMSend.getPayload(&msgBuff, sizeof(attestationChallenge_t));
    call Leds.led0Off();
    call Leds.led2On();
    if (newChallenge && !radioBusy) {
      newChallenge->instruction = result; 
      newChallenge->who = response->who;
      newChallenge->payload = response->payload;
      if (call AMSend.send(response->who, &msgBuff, sizeof(attestationChallenge_t)) == SUCCESS)
        radioBusy = TRUE;
    }
  }
  
  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
    
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    call Leds.led2Off();
    radioBusy = FALSE; 
  }
}