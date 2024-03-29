#include <stdio.h>
generic module FakeSensorP() 
{
	provides interface Read<sensorState>;
	uses interface Random;
}

implementation 
{

	//******************** Read Done **********************//
	task void readDone() {
	  
		sensorState state;

	  	int num = (call Random.rand16() %10);  //generates a random number between 0 and 9
	  	switch (num) //select the state
	  	{
	  		case 0 ... 2:
	  			strcpy(state.stateName, "RUNNING");
	  			break;
	  		case 3 ... 5:
	  			strcpy(state.stateName, "STANDING");
	  			break;
	  		case 6 ... 8:
	  			strcpy(state.stateName, "WALKING");
	  			break;
	  		case 9:
	  			strcpy(state.stateName, "FALLING");
	  			break;
	  		default:
	  			printf("Error in the generation of the random number");
	  			break;
	  	}
		
	  	state.X = call Random.rand16();
	  	state.Y= call Random.rand16();
	  
	 	signal Read.readDone( SUCCESS, state);
	}
	
	//***************** Read interface ********************//
	command error_t Read.read()
	{
		post readDone();
		return SUCCESS;
	}
}  
