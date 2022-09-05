function specSetup()
{
	::upperExtraKey = 1024;
	::lowerExtraKey = 2048;
	::movieExt = ".mp4";

	if (1)
	{
		::initDLC();
	}
}

function specInit( init )
{
	if (("saveSystem" in init) && "tus" in init.saveSystem)
	{
	}
}

