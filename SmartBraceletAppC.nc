#include "SmartBracelet.h"
//#include "SmartBracelet_Serial.h"

configuration SmartBraceletAppC {}

implementation {

/****** COMPONENTS *****/
  components MainC, SmartBraceletC as App;
  
  components new AMSenderC(AM_RADIO_TYPE);
  components new AMReceiverC(AM_RADIO_TYPE);
  components ActiveMessageC as TEST;
  
  components new TimerMilliC() as Timer10;
  components new TimerMilliC() as Timer60;
  components new TimerMilliC() as PairingTimer;
  
  components new FakeSensorC();
  

/****** INTERFACES *****/
  // Boot
  App.Boot -> MainC.Boot;
  
  // Radio
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.AMControl -> TEST;
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.PacketAcknowledgements -> TEST;

  // Timer
  App.PairingTimer -> PairingTimer;
  App.Timer10 -> Timer10;
  App.Timer60 -> Timer60;
  

  App.FakeSensor -> FakeSensorC;
  

}


