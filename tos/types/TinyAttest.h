/*  Defines global attestation result codes for TinyOS
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

#ifndef TINY_ATTEST_H_INCLUDED
#define TINY_ATTEST_H_INCLUDED

#ifdef NESC
#define NESC_COMBINE(x) @combine(x)
#else
#define NESC_COMBINE(x)
#endif

// message types
enum { AM_AT_CHALLENGE_MSG = 42, AM_AT_RESPONSE_MSG = 43 };

// response codes
enum {
  ATTSUCCESS        =  180,          
  ATTFAIL           =  181,            // Generic condition: backwards compatible
  ATTNORESPONSE     =  182,            // Node did not respond
  ATTTIMEDOUT       =  183             // Request timed out
};


// instruction codes
enum {
  ATTEST = 44,
  CANCEL = 45
};

// challenge/response message structurey
typedef nx_struct attestationChallenge {
  nx_uint16_t who;
  nx_uint16_t payload;
  nx_uint16_t instruction;
} attestationChallenge_t;


  typedef uint8_t attestationResult_t NESC_COMBINE("attcombine");

  attestationResult_t attcombine(attestationResult_t r1, attestationResult_t r2) @safe()
  /* Returns: r1 if r1 == r2, FAIL otherwise. This is the standard error
     combination function: two successes, or two identical errors are
     preserved, while conflicting errors are represented by FAIL.
  */
{
  return r1 == r2 ? r1 : FAIL;
}
 
#endif
