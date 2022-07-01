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
  	uint8_t sender;
  	message_t packet;
  	am_addr_t pairDevice;

	static const char *key[] = {"wcru2p8ylwr6nbv584re","wcru2p8ylwr6nbv584re","fhhnswlfojnfna971m14","fhhnswlfojnfna971m14"}; //key[0] = key[1]
  	// Current phase
  	uint8_t phase = 1; //1 = pre-pairing, 2 = pairing completed, 3 = operational, changed
  
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
    	dbg("TimerPairing", "TimerPairing: timer fired at time %s\n", sim_time_string());  //here we send the pakcets in the broadcast phase
    	if (!busy) {
      		sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));  //create the message
      		message->type = 1; //Fill the message
      		message->id = msgCount;
      		strcpy(message->content, key[TOS_NODE_ID]);
      		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(sb_msg_t)) == SUCCESS) {
      			msgCount++;
	      		dbg("Radio", "Radio: sending broadcast pairing packet with key=%s\n", key[TOS_NODE_ID]);
	      		busy = TRUE;
      		}
    	}
  	}
  
  	// Timer10s fired
  	//NIENTE DA FARE
  	event void Timer10.fired() {
    	dbg("Timer10s", "Timer10s: timer fired at time %s\n", sim_time_string());  //every time this timer is fired by the child, we perform a read
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
        		phase = 3; // Pairing phase 2 completed
        			        		
        		// Assign the roles
        		if (TOS_NODE_ID % 2 == 0){  // Node 0 and 2 will be the parents
          			dbg("OperationalMode","------>Parent bracelet<------\n");
          			call Timer60.startOneShot(60000);
        		} else { // Node 1 and 3 will be the children
          			dbg("OperationalMode","------>Child bracelet<------\n"); 
          			call Timer10.startPeriodic(10000);
        	  	}      		
      		}
      		//phase == 3 in this else
      		else if (phase == 3 && call PacketAcknowledgements.wasAcked(bufPtr)){
      			dbg("Radio_ack", "INFO ack received at time %s\n", sim_time_string());
      		}
      		else if (phase == 3){
        		dbg("Radio_ack", "INFO ack not received at time %s\n", sim_time_string()); //if the ack was not received just re-send the message (only in operational phase)
        		sendMessage();
      		}
    	}
  	}
  






   //NIENTE DA FARE
   
   //if at line 150 and the else if at line 160 are never executed by the same mote, the mote that receive first the broadcast will execute only 150, and the other will execute only 160.
   
  	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    	sb_msg_t* message = (sb_msg_t*)payload;
    	if(call AMPacket.destination( bufPtr ) == AM_BROADCAST_ADDR){ //received a broadcast message for initializing the connection
    		if(strcmp(message->content, key[TOS_NODE_ID]) == 0 ){ //the message is coming from my "other half", we've the same key
    			pairDevice = call AMPacket.source( bufPtr );  //pairDevice is the address of the mote associated
    			dbg("Radio", "I'm mote %hhu and the key received is %s\n", TOS_NODE_ID, message->content); 
    			dbg("Radio", "Sending confirmation packet to the other mote that is number %hhu\n", pairDevice);
    			call PairingTimer.stop(); //we don't need broadcast messages anymore
    			phase = 2; //update the phase
    			pairingSucc(); //handle the pairing for the other mote in this function
    		}
    	}
    	else if(call AMPacket.destination( bufPtr ) == TOS_NODE_ID && strcmp(message->content, key[TOS_NODE_ID]) == 0 && phase == 1){ //unicast message that confirms the pairing
    		pairDevice = call AMPacket.source( bufPtr);  //update the pair device also for the other mote
    		phase = 2;
  			call PairingTimer.stop(); //also the other mote is ok
  			dbg("Radio", "Content is %s and my key is %s, sender was %hhu\n", message->content, key[TOS_NODE_ID], pairDevice);
  			dbg("Radio", "Mote %hhu is paired with %hhu\n", TOS_NODE_ID, pairDevice);
  			if (call AMSend.send(pairDevice, &packet, sizeof(sb_msg_t)) == SUCCESS) {
      			dbg("Radio", "Radio: pairing complete, let's start sent to node %hhu\n", pairDevice);	
      		}
    	}
    	else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && message->type == 3) { //receiving during the operational phase, only executed by the parent nodes
			pairDevice = call AMPacket.source( bufPtr);
		  	dbg("Radio_pack","INFO message received\n");
		  	dbg("Info", "Position X: %hhu, Y: %hhu\n", message->X, message->Y);
		  	dbg("Info", "Sensor status: %s\n", message->content);
		  	lastPos.X = message->X;  //update every time the field lastPos to have it always available
		  	lastPos.Y = message->Y;
		  	call Timer60.startOneShot(60000);
		 
		  	if (strcmp(message->content, "FALLING") == 0){  //special control for the falling's alert
		    	dbg("Info", "ALERT: FALLING!\n");
	 	    }
    	}
    	return bufPtr;
    }
    	
	//NIENTE DA FARE
  	event void Read.readDone(error_t result, sensorState localState) {  //executed only by children nodes
    	state = localState;
    	dbg("Sensors", "Sensor status: %s\n", state.stateName);
    	dbg("Sensors", "Position X: %hhu, Y: %hhu\n", localState.X, localState.Y);
    	dbg("Radio", "My destination is: %hhu\n", pairDevice);
      	sendMessage();		  		
  	}

  	//NIENTE DA FARE
  	void pairingSucc(){
    	if (!busy) {
      		sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));
      		message->type = 2; //Fill the message
      		message->id = msgCount;
      		strcpy(message->content, key[TOS_NODE_ID]);      		
      		if (call AMSend.send(pairDevice, &packet, sizeof(sb_msg_t)) == SUCCESS) { //send the confirmation packet to the other mote
      			dbg("Radio", "CIAOOOOOOOO\n");
        	}
      		else{
      			dbg("Radio", "Error in sending confirmation packet to mote %hhu\n", pairDevice);
      		}
    	}
  	}
  
  	// Send INFO message from child's bracelet
  	//NIENTE DA FARE
  	void sendMessage(){
    	msgCount++;
      	if (!busy) {
        	sb_msg_t* message = (sb_msg_t*)call Packet.getPayload(&packet, sizeof(sb_msg_t));
        	message->type = 3; //Fill the message
        	message->id = msgCount;
        	message->X = state.X;
        	message->Y = state.Y;
        	strcpy(message->content, state.stateName);
        	call PacketAcknowledgements.requestAck( &packet ); //ask for the ack to the parent node
        	if (call AMSend.send(pairDevice, &packet, sizeof(sb_msg_t)) == SUCCESS) {  //send the packet
          		dbg("Radio", "Radio: sending INFO packet to node %hhu\n", pairDevice);	
          		busy = TRUE;
        	}
      	} 
  	} 
}




