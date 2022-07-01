#include "SmartBracelet.h"

configuration SmartBraceletAppC {}

implementation {

	/****** COMPONENTS *****/
	components MainC, SmartBraceletC as App;
  
  	components new AMSenderC(AM_RADIO_TYPE);
  	components new AMReceiverC(AM_RADIO_TYPE);
  	components ActiveMessageC;
  
  	components new TimerMilliC() as Timer10;
  	components new TimerMilliC() as Timer60;
  	components new TimerMilliC() as PairingTimer;
  
  	components new FakeSensorC();

	/****** INTERFACES *****/
  	// Boot interface
  	App.Boot -> MainC.Boot;
  
  	// Radio interafaces
  	App.AMSend -> AMSenderC;
  	App.Receive -> AMReceiverC;
  	App.SplitControl -> ActiveMessageC;
  
  	App.Packet -> AMSenderC;
  	App.AMPacket -> AMSenderC;
  	App.PacketAcknowledgements -> AMSenderC.Acks;//ActiveMessageC;

  	// Timer interfaces
  	App.Timer10 -> Timer10;
  	App.Timer60 -> Timer60;
  	App.PairingTimer -> PairingTimer;
  
  	//Fake Sensor read
  	App.Read -> FakeSensorC;
}


