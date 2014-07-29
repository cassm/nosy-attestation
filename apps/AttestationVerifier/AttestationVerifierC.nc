/*  Module for mock attestation verifier routine
 *  Intended for use with AttestationProverAppC
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

module AttestationVerifierC {
  uses {
    interface Boot;
    interface AMSend;
    interface Receive;
    interface SplitControl as AMControl;
    interface Leds;
    interface Packet;
    interface Timer<TMilli> as Timer;
  }
}

implementation {
  message_t msgBuff;
  attestationChallenge_t challenge;
  attestationChallenge_t *newChallenge;
  bool radioBusy = FALSE;

  event void Boot.booted() {
    call AMControl.start();
    challenge.who = TOS_NODE_ID;
    challenge.instruction = ATTEST;
    challenge.payload = 2383;
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call AMControl.start();
    }
    else {
      signal Timer.fired();
    }
  }

  event void Timer.fired() {
    call Leds.set(0);
    newChallenge = call AMSend.getPayload(&msgBuff, sizeof(attestationChallenge_t));
    newChallenge->who = challenge.who;
    newChallenge->payload = challenge.payload;
    newChallenge->instruction = challenge.instruction;

    call Leds.led2On();
    if (newChallenge && !radioBusy) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &msgBuff, sizeof(attestationChallenge_t)) == SUCCESS)
        radioBusy = TRUE;
    }
  }

    event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    radioBusy = FALSE; 
  }

  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    call Leds.led2Off();  		     
    call Leds.led1On();
    call Timer.startOneShot(1000);
    return msg;
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
}
