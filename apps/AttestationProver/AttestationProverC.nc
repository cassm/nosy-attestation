/*  Mock prover module for use with the Attest interface in TinyOS.
 *  Intended for use with AttestationVerifierAppC
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

module AttestationProverC {
  uses {
    interface Timer<TMilli> as Timer;
    interface Random;
  }
  provides interface Attest;
}

implementation {
  bool attesting = FALSE;
  attestationChallenge_t responseBuffer;

  command error_t Attest.attest(nx_uint16_t nodeID, attestationChallenge_t *challenge) {
    
    // only allow one attestation at a time
    if (attesting) {
      return EALREADY;
    } 
    
    // we are now busy
    attesting = TRUE;

    // assume we are the addressed node
    responseBuffer.who = nodeID;
    
    // perform a token calculation on the challenge
    responseBuffer.payload = (challenge->payload * 328) % 31823;

    // simulate a processing time of 0 to 32768ms
    call Timer.startOneShot(call Random.rand16() / 2);

    return SUCCESS;
  }

  event void Timer.fired() {
    // we are no longer busy
    attesting = FALSE;

    // signal attestation complete
    signal Attest.attestationDone(&responseBuffer, SUCCESS);
  }

  command error_t Attest.cancel(nx_uint16_t nodeID) {
    // if not attesting, cannot cancel
    if (!attesting) { 
      return EALREADY;
    }
   
    // Otherwise, cancel the timer, and return the appropriate error code 
    call Timer.stop();
    signal Attest.attestationDone(NULL, ECANCEL);
    
    return SUCCESS;
  }
}