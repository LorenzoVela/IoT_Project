#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

// Message struct
typedef nx_struct sb_msg {
  	nx_uint8_t type;
  	nx_uint16_t id;

  	nx_uint8_t content[20];
  	nx_uint16_t X;
  	nx_uint16_t Y;
} sb_msg_t;

typedef struct sensorState {
  uint8_t stateName[10];
  uint16_t X;
  uint16_t Y;
  uint16_t coord[2];
} sensorState;


// Constants
enum {
  AM_RADIO_TYPE = 6,
};

#endif
