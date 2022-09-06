function specSetup()
{
	::upperExtraKey = 1024;
	::lowerExtraKey = 2048;
	::movieExt = ".mp4";
	::automaticTick = ::System.powerTick;

	if (1)
	{
		::initDLC();
	}
}

function specInit( init )
{
	if (("saveSystem" in init) && "tus" in init.saveSystem)
	{
		this.system("script/tus.nut");
	}
}

