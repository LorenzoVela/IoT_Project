#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

//payload of the msg
typedef nx_struct sb_msg {
	nx_uint8_t type;  //the type indicates the sensor's phase (1->pre-pairing, 2->pairing succeded, 3->operational)
  	nx_uint16_t id; 
  	nx_uint8_t content[20];  //payload of the message, used for exchanging the keys and the status of the bracelet
  	nx_uint16_t X;
  	nx_uint16_t Y;
} sb_msg_t;

typedef struct sensorState {
  	uint16_t X;
  	uint16_t Y;
  	uint8_t stateName[10];  //here is written the state of the bracelet
} sensorState;


enum {
	AM_RADIO_TYPE = 6,
};

#endif
