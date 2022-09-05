function specSetup()
{
	::System.setPixelFormat(3);
	::upperExtraKey = 1024;
	::lowerExtraKey = 2048;
	::movieExt = ".pmf";
	::System.setClockFrequency(333);
	::automaticTick = ::System.powerTick;
}

function specInit( init )
{
	::System.setDLSize(::DLSIZE, ::DLSIZE, 1);
}

