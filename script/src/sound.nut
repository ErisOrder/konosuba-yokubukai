this.bgmVolume <- 1.0;
this.bgmMute <- false;
function setBgmVolume( volume )
{
	this.bgmVolume = volume;

	if (!this.bgmMute)
	{
		::Sound.setGroupVolume("bgm", volume);
	}
}

function getBgmVolume()
{
	return this.bgmVolume;
}

function animateBgmVolume( volume, frame, accel )
{
	this.bgmVolume = volume;

	if (!this.bgmMute)
	{
		::Sound.animateGroupVolume("bgm", this.bgmVolume, frame, accel);
	}
}

function getMovieVolume()
{
	return ::Sound.getGroupVolume("movie") * ::Sound.getMasterVolume();
}

this.soundarcs <- {};
function loadSound( name )
{
	if (name != "")
	{
		if (!(name in this.soundarcs))
		{
			::Sound.load(name);

			while (::Sound.getLoading(name))
			{
				::wait();
			}

			this.soundarcs[name] <- true;
		}
	}
}

function unloadSound( name )
{
	if (name != "")
	{
		if (name in this.soundarcs)
		{
			::Sound.unload(name);
			delete this.soundarcs[name];
		}
	}
}

this.loadSound("sound/bgm.psb");
this.loadSound("sound/se.psb");
this.loadSound("voice/voice.psb");
class this.SimpleSound extends this.Object
{
	owner = null;
	oldid = null;
	oldstorage = null;
	id = null;
	storage = null;
	playThread = null;
	playState = false;
	pan = 0;
	pitch = 100;
	volume = 1.0;
	pauseState = false;
	archives = {};
	constructor( owner = null )
	{
		::Object.constructor();

		if (owner != null)
		{
			this.owner = owner.weakref();
		}
	}

	function destructor()
	{
		this.stop();
	}

	function _stopSound( id, storage, time = 0 )
	{
		if (time > 0)
		{
			::fork(function () : ( id, storage, time, archives )
			{
				if (id != null)
				{
					::Sound.animateVoiceVolume(id, 0, time * 60 / 1000, 0);
					::suspend(time * 60 / 1000);
					::Sound.stopVoice(id);
				}

				if (storage != null)
				{
					if ((storage in archives) && --archives[storage] == 0)
					{
						::Sound.unloadArchive(storage);
						delete archives[storage];
					}
				}
			}.bindenv(this));
		}
		else
		{
			if (id != null)
			{
				::Sound.stopVoice(id);
			}

			if (storage != null)
			{
				this.unload(storage);
			}
		}
	}

	function _stop()
	{
		if (this.playThread != null)
		{
			this.playThread.exit();
			this.playThread = null;
			this.onPlayState(false, true);
		}

		this._stopSound(this.oldid, this.oldstorage);
		this.oldid = this.id;
		this.oldstorage = this.storage;
		this.id = null;
		this.storage = null;
	}

	function _stopOld( time = 0 )
	{
		this._stopSound(this.oldid, this.oldstorage, time);
		this.oldid = null;
		this.oldstorage = null;
	}

	function load( storage )
	{
		if (!(storage in this.archives))
		{
			::Sound.loadArchive(storage);
			this.archives[storage] <- 0;
		}

		this.archives[storage]++;
	}

	function unload( storage )
	{
		if ((storage in this.archives) && --this.archives[storage] == 0)
		{
			::Sound.unloadArchive(storage);
			delete this.archives[storage];
		}
	}

	function _working( storage, option )
	{
	}

	function _playwork( storage, group, loop, time, otime, option )
	{
		this.storage = storage;
		this.load(storage);

		while (::Sound.getArchiveLoading(storage))
		{
			::wait();
		}

		this._stopOld(otime);
		this.onPlayState(true);
		local priority;

		switch(group)
		{
		case "se":
			priority = 1;
			break;

		case "voice":
			priority = 2;
			break;

		case "bgm":
			priority = 3;
			break;

		default:
			priority = 0;
			break;
		}

		if (time == 0 || this.pauseState)
		{
			local param = {
				volume = this.volume,
				pitch = ::calcPitch(this.pitch),
				group = group,
				priority = priority
			};
			this.id = ::Sound.playVoice(storage, param);

			if (this.pauseState)
			{
				::Sound.pauseVoice(this.id);
			}
		}
		else
		{
			local param = {
				volume = 0,
				pitch = ::calcPitch(this.pitch),
				group = group,
				priority = priority
			};
			this.id = ::Sound.playVoice(storage, param);
			::Sound.animateVoiceVolume(this.id, this.volume, time * 60 / 1000, 0);
		}

		this._working(storage, option);

		while (this.getVoicePlaying())
		{
			::suspend();
		}

		this.onPlayState(false);
		this.playThread = null;
	}

	function play( storage, group, loop = 0, volume = 1.0, pan = 0, pitch = 100, time = 0, otime = 0, option = null )
	{
		this._stop();
		this.volume = volume;
		this.pan = pan;
		this.pitch = pitch;
		this.pauseState = false;
		this.playThread = ::fork(this._playwork.bindenv(this), storage, group, loop, time, otime, option);
	}

	function stop( time = 0 )
	{
		this._stop();
		this._stopOld(time);
	}

	function getVoicePlaying()
	{
		return this.id != null && ::Sound.getVoicePlaying(this.id);
	}

	function getPlaying()
	{
		return this.playThread != null || this.getVoicePlaying();
	}

	function setVolume( volume )
	{
		this.volume = volume;

		if (this.id != null)
		{
			::Sound.setVoiceVolume(this.id, volume);
		}
	}

	function setPan( pan )
	{
		this.pan = pan;

		if (this.id != null)
		{
		}
	}

	function setPitch( pitch )
	{
		this.pitch = pitch;

		if (this.id != null)
		{
			::Sound.setVoicePitch(this.id, ::calcPitch(pitch));
		}
	}

	function pause()
	{
		this.pauseState = true;

		if (this.id != null)
		{
			::Sound.pauseVoice(this.id);
		}
	}

	function resumeSound()
	{
		this.pauseState = false;

		if (this.id != null)
		{
			::Sound.resumeVoice(this.id);
		}
	}

	function onPlayState( state, user = false )
	{
		if (state != this.playState)
		{
			if (state)
			{
				if (this.owner != null)
				{
					this.owner.onStartSound(this);
				}
			}
			else if (this.owner != null)
			{
				this.owner.onStopSound(this, user);
			}

			this.playState = state;
		}
	}

}

class this.Music extends this.Object
{
	group = null;
	constructor( group = "bgm", soundClass = this.SimpleSound, owner = null )
	{
		::Object.constructor();
		this.group = group;
		this._sound = soundClass(owner);
	}

	function destructor()
	{
		this.stop();
	}

	_fadeThread = null;
	_fadeVisible = null;
	function _fadefunc( visible, frame )
	{
		if (visible)
		{
			for( local i = 0; i < frame; i++ )
			{
				this.setVisvalue(i.tofloat() / frame);
				::suspend();
			}
		}
		else
		{
			for( local i = 0; i < frame; i++ )
			{
				this.setVisvalue(1 - i.tofloat() / frame);
				::suspend();
			}
		}

		this.setVisvalue(visible ? 1.0 : 0);
		this.checkStopPause();
	}

	function fadeVisible( visible, time )
	{
		this._fadeVisible = visible;
		this._fadeThread = ::fork(this._fadefunc.bindenv(this), visible, time * 60 / 1000);
	}

	function fadeStop()
	{
		if (this._fadeThread)
		{
			this._fadeThread.exit();
			this._fadeThread = null;
			this.visvalue = this._fadeVisible ? 1.0 : 0;
			this.checkStopPause();
		}
	}

	function getFading()
	{
		return this._fadeThread != null && this._fadeThread.status != 0;
	}

	function play( storage, loop = 0, volume = 100, start = null, params = null, time = 0, option = null )
	{
		storage = storage.tolower();
		this.fadeStop();
		this._volume = volume / 100.0;

		if (storage != this._sound.storage || !this._sound.playing)
		{
			this._fade = "fade" in params ? params.fade : 100;
			this._pan = "pan" in params ? params.pan : 0;
			this._pitch = "pitch" in params ? params.pitch : 100;

			if (start != null)
			{
			}

			if (time > 0)
			{
				this._sound.play(storage, this.group, loop, 0, this._pan, this._pitch, 0, 0, option);
				this.fadeVisible(true, time);
			}
			else
			{
				this._sound.play(storage, this.group, loop, this._fade / 100.0 * this._volume, this._pan, this._pitch, 0, 0, option);
				this._visvalue = 1.0;
			}

			this._currentStorage = storage;
			this._currentLoop = loop;
			this._paused = false;
		}
	}

	function _stop()
	{
		this._sound.stop();
	}

	function stop( time = 0 )
	{
		this._currentStorage = null;
		this.fadeStop();

		if (this._sound.id != null && time > 0)
		{
			this._stopFlag = true;
			this.fadeVisible(false, time);
		}
		else
		{
			this._stop();
			this.visvalue = 0;
		}
	}

	function _pause()
	{
		if (true)
		{
			this._sound.pause();
			this._paused = true;
		}
	}

	function pause( time = 0 )
	{
		if (!this._paused)
		{
			this.fadeStop();

			if (time > 0)
			{
				this._pauseFlag = true;
				this.fadeVisible(false, time);
			}
			else
			{
				this._pause();
				this.visvalue = 0;
			}
		}
	}

	function restart( time = 0 )
	{
		if (this._paused)
		{
			this.printf("music restart:%d\n", time);
			this.fadeStop();

			if (time > 0)
			{
				this._paused = false;
				this.visvalue = 0;
				this._sound.resumeSound();
				this.fadeVisible(true, time);
			}
			else
			{
				this.visvalue = 1.0;
				this._sound.resumeSound();
				this._paused = false;
			}
		}
	}

	function setVolume( volume )
	{
		this._volume = volume / 100.0;
		this._sound.setVolume(this._fade / 100.0 * this._volume * this._visvalue);
	}

	function getPlaying()
	{
		return this._sound.getPlaying() && !this._stopFlag;
	}

	function getPaused()
	{
		return this._paused || this._pauseFlag;
	}

	function checkStopPause()
	{
		if (this._stopFlag)
		{
			this._stop();
			this._stopFlag = false;
		}

		if (this._pauseFlag)
		{
			this._pause();
			this._pauseFlag = false;
		}
	}

	function setVisvalue( v )
	{
		if (v != this._visvalue)
		{
			this._visvalue = v;
			this._sound.setVolume(this._fade / 100.0 * this._volume * this._visvalue);
		}
	}

	function setFade( fade )
	{
		if (this._fade != fade)
		{
			this._fade = fade;
			this._sound.setVolume(this._fade / 100.0 * this._volume * this._visvalue);
		}
	}

	function getFade()
	{
		return this._fade;
	}

	function setPan( pan )
	{
		if (this._pan != pan)
		{
			this._pan = pan;
			this._sound.setPan(this._pan);
		}
	}

	function getPan()
	{
		return this._pan;
	}

	function setPitch( pitch )
	{
		if (this._pitch != pitch)
		{
			this._pitch = pitch;
			this._sound.setPitch(this._pitch);
		}
	}

	function getPitch()
	{
		return this._pitch;
	}

	_volume = 1.0;
	_visvalue = 1.0;
	_fade = 100.0;
	_pan = 0;
	_pitch = 100.0;
	_pauseFlag = false;
	_stopFlag = false;
	_paused = false;
	_currentStorage = null;
	_currentLoop = null;
	_currentId = null;
	_sound = null;
}

class this.MultiSound extends this.Object
{
	group = null;
	constructor( count, group = "se", soundClass = this.SimpleSound )
	{
		::Object.constructor();
		this._count = count;
		this._ses = [];

		for( local i = 0; i < this._count; i++ )
		{
			this._ses.append(soundClass(this));
		}

		this._current = this._count - 1;
		this.group = group;
	}

	function destructor()
	{
		this.stop();
	}

	function play( storage, volume = 100, params = null, time = 0, option = null )
	{
		if (typeof storage == "integer")
		{
			storage = storage.tostring();
		}

		storage = storage.tolower();

		if (this.getPlaying())
		{
			this._current = (this._current + 1) % this._count;
		}

		this._volume = volume / 100.0;
		this._fade = "fade" in params ? params.fade : 100;
		this._pan = "pan" in params ? params.pan : 0;
		this._pitch = "pitch" in params ? params.pitch : 100;
		this._ses[this._current].play(storage, this.group, 0, this._fade / 100.0 * this._volume, this._pan, this._pitch, time, 0, option);
		return this._current;
	}

	function stop( time = 0 )
	{
		foreach( se in this._ses )
		{
			se.stop(time);
		}
	}

	function setVolume( volume )
	{
		volume = volume / 100.0;

		if (this._volume != volume)
		{
			this._volume = volume;
			this._ses[this._current].setVolume(this._fade / 100.0 * this._volume);
		}
	}

	function getPlaying()
	{
		return this._ses[this._current].getPlaying();
	}

	function getAllPlaying()
	{
		foreach( se in this._ses )
		{
			if (se.getPlaying())
			{
				return true;
			}
		}

		return false;
	}

	playingCount = 0;
	function onStartSound( sound )
	{
		if (this.playingCount == 0)
		{
			this.onStart();
		}

		this.playingCount++;
	}

	function onStopSound( sound, user )
	{
		this.playingCount--;

		if (this.playingCount == 0)
		{
			this.onStop();
		}
	}

	function onStart()
	{
	}

	function onStop()
	{
	}

	function setFade( fade )
	{
		if (this._fade != fade)
		{
			this._fade = fade;
			this._ses[this._current].setVolume(this._fade / 100.0 * this._volume);
		}
	}

	function getFade()
	{
		return this._fade;
	}

	function setPan( pan )
	{
		if (this._pan != pan)
		{
			this._pan = pan;
			this._ses[this._current].setPan(this._pan);
		}
	}

	function getPan()
	{
		return this._pan;
	}

	function setPitch( pitch )
	{
		if (this._pitch != pitch)
		{
			this._pitch = pitch;
			this._ses[this._current].setPitch(this._pitch);
		}
	}

	function getPitch()
	{
		return this._pitch;
	}

	_volume = 1.0;
	_fade = 100;
	_pan = 0;
	_pitch = 100;
	_ses = null;
	_count = 0;
	_current = 0;
}

class this.SysSound extends this.Object
{
	group = null;
	constructor( config, archive, group = "se" )
	{
		::Object.constructor();
		this.config = config;
		this.archive = archive;
		::Sound.load(config);

		while (::Sound.getLoading(config))
		{
			::wait();
		}

		::Sound.loadArchive(archive);

		while (::Sound.getArchiveLoading(archive))
		{
			::wait();
		}

		this.group = group;
	}

	function destructor()
	{
		this.stop();
		::Sound.unloadArchive(this.archive);
		::Sound.unload(this.config);
	}

	function play( name, volume = 100 )
	{
		::Sound.playVoice(name, {
			group = this.group
		});
	}

	function stop()
	{
		::Sound.stopArchive(this.archive);
	}

	config = null;
	archive = null;
}

