#include <stdio.h>
generic module FakeSensorP() 
{
	provides interface Read<sensorState>;
	uses interface Random;
}

implementation 
{

	task void readDone();

	//***************** Read interface ********************//
	command error_t Read.read()
	{
		post readDone();
		return SUCCESS;
	}

	//******************** Read Done **********************//
	task void readDone() {
	  
		sensorState state;

	  	int num = (call Random.rand16() %10);
	  	int x;
	  	int y;
	  	printf("\n%d\n", num); //to delete
	  	switch (num)
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
		
	  	x = call Random.rand16();
	  	y = call Random.rand16();
	  
	  	state.X = x;
	  	state.coord[0] = x;
	 
	  	state.Y = y;
	 	state.coord[1] = y;
	 	signal Read.readDone( SUCCESS, state);
	  	/*
	  	state.X = call Random.rand16();
	  	state.Y = call Random.rand16();
	  
	  	state.coord[0] = state.X;
	  	state.coord[1] = state.Y;
	  	*/
	}
}  
