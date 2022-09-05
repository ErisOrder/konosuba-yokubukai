function specSetup()
{
	::System.setResourceCacheLimitSize(100 * 1024 * 1024);
	::movieExt = ".wmv";
}

function bgmMuteControl()
{
	for( local mute = false; true;  )
	{
		::wait();
		mute = !::System.getXmpActive();

		if (mute != this.bgmMute)
		{
			this.bgmMute = mute;

			if (this.bgmMute)
			{
				::Sound.animateGroupVolume("bgm", 0, 0, 0);
			}
			else
			{
				::Sound.setGroupVolume("bgm", this.bgmVolume);
			}
		}
	}
}

function specAfterInit()
{
	::fork(this.bgmMuteControl);

	if (::textTable != null)
	{
		::System.setStringTable(::textTable);
	}
}

