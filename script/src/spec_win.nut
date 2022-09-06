function specSetup()
{
	::System.setResourceCacheLimitSize(500 * 1024 * 1024);
	::movieExt = ".wmv";
}

function specAfterScreenInit()
{
	if ("entryChangeScreenSizeCallback" in ::getroottable())
	{
		function changeScreenSizeCallback( width, height, scale )
		{
			::baseScreen.changeSizeScale(width, height, scale);
		}

		this.entryChangeScreenSizeCallback(this.changeScreenSizeCallback);
	}

	if (("DMMAuth" in ::getroottable()) && "DMM_APPID" in ::getroottable())
	{
		this.system("script/dmmauth.nut");
	}
}

