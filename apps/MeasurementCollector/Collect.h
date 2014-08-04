/*  Data types for a basic collector network for humidity and temperature
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.x
 */

#ifndef COLLECT_H_INCLUDED
#define COLLECT_H_INCLUDED

enum { AM_DATAREADING = 52,
       DATA_COL_UART = 53,
       AM_DATASETTINGS = 54 
};

typedef nx_struct dataSettings {
  nx_uint8_t testVal;
  nx_uint16_t sampleInterval;
} dataSettings_t;

typedef nx_struct dataReading {
  nx_uint8_t testVal;
  nx_uint8_t who;
  nx_uint16_t temperature,
    humidity;
} dataReading_t;

#endif
