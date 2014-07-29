#ifndef COLLECT_H_INCLUDED
#define COLLECT_H_INCLUDED

enum { DATA_COL = 52 };

typedef nx_struct dataReading {
  nx_uint8_t who;
  nx_uint16_t temperature,
    humidity;
} dataReading_t;

#endif
