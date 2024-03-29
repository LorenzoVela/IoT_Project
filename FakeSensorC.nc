generic configuration FakeSensorC() 
{
	provides interface Read<sensorState>;
} 

implementation 
{

	components MainC, RandomC;
	components new FakeSensorP();
	
	//Connects the provided interface
	Read = FakeSensorP;
	
	//Random interface and its initialization	
	FakeSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

}
