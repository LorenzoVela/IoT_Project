#include "Timer.h"
#include "SmartBracelet.h"
//#include <stdio.h>

module SmartBraceletC @safe() {
	uses {
	/****** INTERFACES *****/
    	interface Boot;
    	
    	//interface for packets' ack
    	interface PacketAcknowledgements;
    
    	//interfaces for communication
    	interface SplitControl;
    	interface AMSend;
    	interface Receive;
    	interface Packet;
    	interface AMPacket;
    	
    	//interfaces for timer
    	interface Timer<TMilli> as PairingTimer;
    	interface Timer<TMilli> as Timer10;
    	interface Timer<TMilli> as Timer60;
    
    	//interface used to perform sensor reading, to get the value from a sensor
    	interface Read<sensorState>;
  
  	}
}

implementation {
  
  // Radio control
	bool busy = FALSE;
  	uint16_t msgCount = 1; //changed name
  	uint8_t threshold = 0;
  	uint8_t source;
  	uint8_t sender;
  	message_t packet;
  	am_addr_t pairDevice;

	static const char *key[] = {"wcru2p8ylwr6nbv584re","wcru2p8ylwr6nbv584re","fhhnswlfojnfna971m14","fhhnswlfojnfna971m14"}; //key[0] = key[1]
  	// Current phase
  	uint8_t phase = 1; //1 = pre-pairing, 2 = pairing completed, 3 = operational, changed
  
  	// Sensors
  	//bool sensors_read_completed = FALSE;
  
  	sensorState state;
  	sensorState lastPos;
  
  




  	void pairingSucc();
  	void sendMessage();
  
  	//***************** Boot interface ********************//
  	event void Boot.booted() {
    	call SplitControl.start();
  	}

  // called when radio is ready
  
  //NIENTE DA FARE
  	event void SplitControl.startDone(error_t err) {
    	if (err == SUCCESS) {
     		dbg("Radio", "Radio device ready\n");
      		dbg("Pairing", "Pairing phase started\n");
      		// Start pairing phase
      		call PairingTimer.startPeriodic(250);
    	} else {
      		call SplitControl.start();
    	  }
  	}
  //NIENTE DA FARE
  	event void SplitControl.stopDone(error_t err) {}
  
//NIENTE DA FARE
  	event void PairingTimer.fired() {
    	dbg("TimerPairing", "TimerPairing: timer fired at time %s\n", sim_time_string());
    	if (!busy) {
      		sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));
      		// Fill payload
      		message->type = 1; // 0 for pairing phase
      		message->id = msgCount;
      		//The node ID is divided by 2 so every 2 nodes will be the same number (0/2=0 and 1/2=0)
      		//we get the same key for every 2 nodes: parent and child
      		strcpy(message->content, key[TOS_NODE_ID]);
      		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(sb_msg_t)) == SUCCESS) {
      			msgCount++;
	      		dbg("Radio", "Radio: sending broadcast pairing packet with key=%s\n", key[TOS_NODE_ID]);
	      		//dbg("Radio", "TEST DEBUGGGZGZGGZ, key=%s\n", message->data);
	      		busy = TRUE;
      		}
    	}
  	}
  
  	// Timer10s fired
  	//NIENTE DA FARE
  	event void Timer10.fired() {
    	dbg("Timer10s", "Timer10s: timer fired at time %s\n", sim_time_string());
    	//call PositionSensor.read();
    	call Read.read();
  	}

  	// Timer60s fired
  	//NIENTE DA FARE
  	event void Timer60.fired() {
    	dbg("Timer60s", "Timer60s: timer fired at time %s\n", sim_time_string());
    	dbg("Timer60s", "ALERT: MISSING\n");
    	dbg("Timer60s","Last known location was X: %hhu, Y: %hhu\n", lastPos.X, lastPos.Y);
  	}

 
  	//NIENTE DA FARE
  	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    	if (&packet == bufPtr && error == SUCCESS) {
      		dbg("Radio_sent", "Packet sent, phase = %hu\n",phase);
      		busy = FALSE;
      		
      		if (phase == 2){
      			//if (call PacketAcknowledgements.wasAcked(bufPtr)){
      				//dbg("Radio", "Sono entrato qui e sono il moteeee %hu\n", TOS_NODE_ID);
        			phase = 3; // Pairing phase 1 completed
        			//dbg("Radio_ack", "Pairing ack received at time %s\n", sim_time_string());
        		
        			// Start operational phase
        			if (TOS_NODE_ID % 2 == 0){
          				// Parent bracelet
          				dbg("OperationalMode","------>Parent bracelet<------\n");
          				call Timer60.startOneShot(60000);
        			} else {
          				// Child bracelet
          				dbg("OperationalMode","------>Child bracelet<------\n");
          				call Timer10.startPeriodic(10000);
        	  		}
      			//}
      		
      		}
      		//phase == 3 in this else
      		else if (phase == 3 && call PacketAcknowledgements.wasAcked(bufPtr)){
      			dbg("Radio_ack", "INFO ack received at time %s\n", sim_time_string());
      		}
      		else if (phase == 3){
      			// Phase == 2 and ack not received
        		dbg("Radio_ack", "INFO ack not received at time %s\n", sim_time_string());
        		sendMessage();
      		}
    	}
  	}
  






   //NIENTE DA FARE
  	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    	sb_msg_t* message = (sb_msg_t*)payload;
    	//uint8_t source = call AMPacket.source( bufPtr );
    	// Print data of the received packet
    	//dbg("Radio", "C'è qualcosa qui?\n");
    	if(call AMPacket.destination( bufPtr ) == AM_BROADCAST_ADDR){ //received a broadcast message for initializing the connection
    		if(strcmp(message->content, key[TOS_NODE_ID]) == 0 ){ //Oh, it's a message from my buddy
    			pairDevice = call AMPacket.source( bufPtr );
    			dbg("Radio", "I'm mote %hhu and the key received is %s\n", TOS_NODE_ID, message->content); 
    			dbg("Radio", "Sending confirmation packet to the other mote that is number %hhu\n", pairDevice);
    			//pairDevice = call AMPacket.source( bufPtr );
    			call PairingTimer.stop(); //se va male poi capire che succede
    			phase = 2;
    			pairingSucc();
    			//dbg("Radio", "178\n");
    		}
    	}
    	else if(call AMPacket.destination( bufPtr ) == TOS_NODE_ID && strcmp(message->content, key[TOS_NODE_ID]) == 0 && phase == 1){ //buddy is sending a message to me and wants to pair
    		dbg("Radio","Eureka?\n");
    		sender = call AMPacket.source( bufPtr);
    		phase = 2;
  			call PairingTimer.stop();
  			dbg("Radio", "Content is %s and my key is %s, sender was %hhu\n", message->content, key[TOS_NODE_ID], sender);
  			dbg("Radio", "Mote %hhu is paired with %hhu\n", TOS_NODE_ID, sender);
  			//call PacketAcknowledgements.requestAck( &packet );
  			if (call AMSend.send(sender, &packet, sizeof(sb_msg_t)) == SUCCESS) {
      			dbg("Radio", "Radio: pairing complete, let's start sent to node %hhu\n", sender);	
      		}
      		//else{
      		//	dbg("Radio", "Error 189\n");
      		//}
    	}
    	else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && message->type == 3) {
			// Enters if the packet is for this destination and if msg_type == 2
			sender = call AMPacket.source( bufPtr);
			pairDevice = call AMPacket.source( bufPtr);
		  	dbg("Radio_pack","INFO message received\n");
		  	dbg("Info", "Position X: %hhu, Y: %hhu\n", message->X, message->Y);
		  	dbg("Info", "Sensor status: %s\n", message->content);
		  	lastPos.X = message->X;
		  	lastPos.Y = message->Y;
		  	call Timer60.startOneShot(60000);
		  
		  	// check if FALLING
		  	if (strcmp(message->content, "FALLING") == 0){
		    	dbg("Info", "ALERT: FALLING!\n");
	 	    }
    	}
    	return bufPtr;
    }
    	
    	
   /* 	
    	
    	
    	
    	if(strcmp(message->content, key[TOS_NODE_ID]) == 0){ //pairing phase
	  	
	  		dbg("Radio_pack","PayloadXXXX: type: %hu, id: %hhu, content: %s\n", message->type, message->id, message->content);
	  		dbg("Radio_pack","Received a message from mote: %hhu\n", source);
    
    		if (call AMPacket.destination( bufPtr ) == AM_BROADCAST_ADDR && phase == 1 && strcmp(message->content, key[TOS_NODE_ID]) == 0){ //changed here
      			// controlla che sia un broadcast e che siamo nella fase di pairing phase == 0
      			// e che la chiave corrisponda a quella di questo dispositivo
      
		  		pairDevice = call AMPacket.source( bufPtr );
		  		phase = 2; // 1 for confirmation of pairing phase
		  		dbg("Radio_pack","Message for pairing phase 0 received. Address: %hhu\n", pairDevice);
		  		call PairingTimer.stop();
		  		pairingSucc();
		
			} else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && message->type == 2 && strcmp(message->content, key[TOS_NODE_ID]) == 0) {
		  		// Enters if the packet is for this destination and if the msg_type == 1
		  		dbg("Radio_pack","Message for pairing phase 1 received\n");
		  		//call PairingTimer.stop();
		  
			} else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && message->type == 3 && strcmp(message->content, key[TOS_NODE_ID]) == 0) {
		  		// Enters if the packet is for this destination and if msg_type == 2
		  		dbg("Radio_pack","INFO message received\n");
		  		dbg("Info", "Position X: %hhu, Y: %hhu\n", message->X, message->Y);
		  		dbg("Info", "Sensor status: %s\n", message->content);
		  		lastPos.X = message->X;
		  		lastPos.Y = message->Y;
		  		call Timer60.startOneShot(60000);
		  
		  		// check if FALLING
		  		if (strcmp(message->content, "FALLING") == 0){
		    		dbg("Info", "ALERT: FALLING!\n");
	 	      	}
    		}
    	}
    	return bufPtr;
  	}

 

*/


	//NIENTE DA FARE
  	event void Read.readDone(error_t result, sensorState localState) {
    	state = localState;
    	dbg("Sensors", "Sensor status: %s\n", state.stateName);
    	dbg("Sensors", "Position X: %hhu, Y: %hhu\n", localState.X, localState.Y);
      	sendMessage();		  		
  	}







  	// Send confirmation in phase 1
  	//NIENTE DA FARE
  	void pairingSucc(){
  		//dbg("Radio", "MA ENTRA QUI??\n");
    	//msgCount++;
    	//dbg("Radio","293\n");
    	uint8_t attempts = 0;
    	if (!busy || 1) {
      		sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));
      	
      		// Fill payload
      		message->type = 2; 
      		message->id = msgCount;
      		
      		strcpy(message->content, key[TOS_NODE_ID]);
      		//dbg("Radio", "Sono mote: %hhu e sto mandando conferma al mote: %hhu\n", TOS_NODE_ID, pairDevice);
      // Require ack
      		//call PacketAcknowledgements.requestAck( &packet );
      		while (attempts < 4){
      			//dbg("Radio","305 and value of pairDevice is %hhu\n", pairDevice);
      			if (call AMSend.send(pairDevice, &packet, sizeof(sb_msg_t)) == SUCCESS) {
        dbg("Radio", "Radio: sending pairing confirmation to node %hhu\n", pairDevice);	
        busy = TRUE;
      				attempts = 5;	
        			busy = TRUE;
      			}
      			else{
      				dbg("Radio", "Error in sending confirmation packet to mote %hhu\n", pairDevice);
      				//dbg("Radio", "Pair device is: %hu\n", pairDevice);
      				attempts++;
      				//pairingSucc();
      			}
      		}
    	}
  	}
  
  	// Send INFO message from child's bracelet
  	//NIENTE DA FARE
  	void sendMessage(){
    	msgCount++;
      	if (!busy) {
      		//if(threshold < 5){
      			//threshold = threshold + 1;
        		sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));
        
        		// Fill payload
        		message->type = 3; // 2 for INFO packet
        		message->id = msgCount;
        		message->X = state.X;
        		message->Y = state.Y;
        		strcpy(message->content, state.stateName);
        
        		// Require ack
        		call PacketAcknowledgements.requestAck( &packet );
        		//threshold = threshold + 1;
        		if (call AMSend.send(sender, &packet, sizeof(sb_msg_t)) == SUCCESS) {
          			dbg("Radio", "Radio: sending INFO packet to node %hhu\n", sender);	
          			//dbg("Radio", "test key1 %s\n\n", key[1]);
          			busy = TRUE;
        		}
      		//}
      		//else{
      		//	threshold = 0;
      		//}
      	
      	} 
  	} 
}




