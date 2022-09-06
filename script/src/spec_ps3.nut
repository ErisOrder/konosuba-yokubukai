function specSetup()
{
	local res = ::System.getOutputResolution();
	local mode = ::System.getInterlace() ? "interlace" : "progressive";
	this.printf("mode:%s output resolution: %d x %d\n", mode, res.width, res.height);
	::System.setResourceCacheLimitSize(100 * 1024 * 1024);
	::upperExtraKey = 1024;
	::lowerExtraKey = 2048;
	::movieExt = ".pam";

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

function specStartup()
{
	this.inputHub.analogPressSensitivity = 128;

	if (::isDownloadTitle())
	{
		try
		{
			local issd = ::getScreenBounds().width == 640;
			local caution = ::MotionLayer(::baseScreen, "motion/caution.psb", issd ? "CAUTION_SD" : "CAUTION_HD", issd ? 640 : this.SCWIDTH, issd ? 480 : this.SCHEIGHT);
			caution.playWait("show", 0, false);
		}
		catch( e )
		{
			this.printf("not found caution motion\n");
		}
	}
}

