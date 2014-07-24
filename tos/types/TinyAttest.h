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

enum {
  SUCCESS        =  180,          
  FAIL           =  181,           // Generic condition: backwards compatible
  NORESPONSE    =  182,            // Node did not respond
  TIMEDOUT      =  183             // Request timed out
};

typedef uint8_t attestation_t NESC_COMBINE("ecombine");

error_t ecombine(error_t r1, error_t r2) @safe()
/* Returns: r1 if r1 == r2, FAIL otherwise. This is the standard error
     combination function: two successes, or two identical errors are
     preserved, while conflicting errors are represented by FAIL.
*/
{
  return r1 == r2 ? r1 : FAIL;
}
 
#endif
