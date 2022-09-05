class this.AppVoice extends this.SimpleSound
{
	name = null;
	constructor( owner = null )
	{
		::SimpleSound.constructor(owner);
	}

	function onPlayState( state, user = false )
	{
		::SimpleSound.onPlayState(state, user);

		if (!state)
		{
			this.name = null;
		}
	}

	function _stop()
	{
		::SimpleSound._stop();
		this.name = null;
	}

}

class this.AppVoiceBase extends this.MultiSound
{
	constructor( owner, count, group )
	{
		::MultiSound.constructor(count, group, this.AppVoice);
	}

	function findName( name )
	{
		foreach( se in this._ses )
		{
			if (se.name == name)
			{
				return se;
			}
		}
	}

	function play( name, storage, volume = 100, params = null )
	{
		local c = ::MultiSound.play(storage, volume, params);
		this._ses[c].name = name;
	}

	function stop( time = 0, name = null )
	{
		if (name == null)
		{
			::MultiSound.stop(time);
		}
		else
		{
			local se = this.findName(name);

			if (se != null)
			{
				se.stop(time);
			}
		}
	}

}

class this.Application extends this.SaveSystem
{
	OPMOVIE = "";
	TITLEBGM = null;
	MOVIECANCELKEY = null;
	MOVIEADDKEY = null;
	TITLE_MOVIE_WAIT = 30;
	ETCVOICE = "ETC";
	firstState = null;
	cmdTitleState = "title";
	endTitleState = "title";
	changeConfig = false;
	debugInfoPosition = 0;
	recordEnable = true;
	function getStartScene( cur )
	{
		this.dummyDialog("start scene not implement");
	}

	function titleMenu( cur, arg )
	{
		this.dummyDialog("title menu not implement");
	}

	function titleMovie()
	{
		this.stopBGM();
		this.cleanup();
		this.playMovie(this.OPMOVIE);
		this.setup();
	}

	function title_load( arg )
	{
		return this.openLoad();
	}

	function title_config( arg )
	{
		this.openConfig();
	}

	function openConfig()
	{
		this.dummyDialog("CONFIG panel not implement");
	}

	function openLoad()
	{
		this.dummyDialog("LOAD panel not implement");
	}

	function execLoad( scene )
	{
		if (this.player != null)
		{
			this.player.exitGame("restart", scene);
			return true;
		}

		return false;
	}

	function onStartup()
	{
	}

	function onTitleChange( title )
	{
	}

	function onStartScene( scene )
	{
	}

	function onEndScene( scene, ret )
	{
	}

	function onSuspendScene( scene, state )
	{
	}

	function onDebugSceneSelect()
	{
	}

	constructor( init )
	{
		::SaveSystem.constructor(init.saveSystem);
		this.ETCVOICE = ::getval(init, "ETCVOICE", "ETC");

		if (0)
		{
			this.showRevisionInfo();
		}

		this.cf = this.GetSet(this.getConfig.bindenv(this), this.setConfig.bindenv(this));
		this.sf = this.GetSet(this.getSystemFlag.bindenv(this), this.setSystemFlag.bindenv(this));
	}

	function destructor()
	{
		this.cleanup();
		this.hideRevisionInfo();
		this.doneDebugInfo();
		this.textbase = null;
		::Object.destructor();
	}

	cf = null;
	sf = null;
	function checkAppFunc( funcname )
	{
		return funcname in this;
	}

	function callAppFunc( funcname, ... )
	{
		if (funcname in this)
		{
			local func = this[funcname];
			local args = [];

			for( local i = 0; i < vargc; i++ )
			{
				args.append(vargv[i]);
			}

			try
			{
				switch(args.len())
				{
				case 0:
					  // [021]  OP_POPTRAP        1      0    0    0
					return func();

				case 1:
					  // [031]  OP_POPTRAP        1      0    0    0
					return func(args[0]);

				case 2:
					  // [043]  OP_POPTRAP        1      0    0    0
					return func(args[0], args[1]);

				case 3:
					  // [057]  OP_POPTRAP        1      0    0    0
					return func(args[0], args[1], args[2]);

				case 4:
					  // [073]  OP_POPTRAP        1      0    0    0
					return func(args[0], args[1], args[2], args[3]);
				}

				return func(args[0], args[1], args[2], args[3], args[4]);
				  // [089]  OP_POPTRAP        1      0    0    0
			}
			catch( e )
			{
				this.printf("%s:\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", $[stack offset 1], "message" in e ? e.message : e);
				::printException(e);
			}
		}
		else
		{
			this.printf("%s:no such app function\n", funcname);
		}
	}

	function createDebugText( fontSize )
	{
		if (this.textbase == null)
		{
			this.textbase = this.BasicLayer(this.getScreen());
			this.textbase.priority = 33;
		}

		return this.textbase.createText(fontSize);
	}

	function setConfig( name, value )
	{
		::SaveSystem.setConfig(name, value);
		this.changeConfig = true;
	}

	function createThumbnailInfo( info )
	{
		local image = ::RawImage(this.THUMBNAIL_WIDTH, this.THUMBNAIL_HEIGHT);
		image.restore(info.thumbnail);
		return image;
	}

	function getSceneList()
	{
		return this.sceneIdMap.list;
	}

	function askInitConfig()
	{
		if (::SaveSystem.askInitConfig())
		{
			this.changeConfig = true;
			return true;
		}

		return false;
	}

	voiceIdMap = null;
	function getVoiceConfig( name )
	{
		local info = this.voiceIdMap.getInfo(name);
		return info != null ? info.config : this.ETCVOICE;
	}

	function getVoiceLevel( name )
	{
		local info = this.voiceIdMap.getInfo(name);

		if (info != null && "level" in info)
		{
			return info.level;
		}
	}

	function getVoiceAlias( name )
	{
		local info = this.voiceIdMap.getInfo(name);

		if (info != null && info.alias != "")
		{
			return info.alias;
		}
	}

	function getVoiceOn( name )
	{
		if (this.isExistConfig("vflag" + name))
		{
			return this.getConfig("vflag" + name, 1);
		}

		local conf = this.getVoiceConfig(name);
		return this.getConfig("vflag" + conf, 1);
	}

	function getVoiceVolume( name )
	{
		if (this.isExistConfig("voice" + name))
		{
			return this.getConfig("voice" + name, 1.0);
		}

		local conf = this.getVoiceConfig(name);
		return this.getConfig("voice" + conf, 1.0);
	}

	function setVoiceVolume( name, value )
	{
		if (this.isExistConfig("voice" + name))
		{
			this.setConfig("voice" + name, value);
		}
		else
		{
			local conf = this.getVoiceConfig(name);
			this.setConfig("voice" + conf, value);
		}

		if (name == this.lastVoiceName && this.voice != null)
		{
			this.voice.setVolume(value * 100);
		}
	}

	function cleanup( stopbgm = true )
	{
		if (stopbgm)
		{
			this.bgm = null;
			this.currentBGM = null;
		}

		this.voice = null;
		this.sound = null;
		this.menupanel = null;
		this.player = null;
		::collectgarbage();
	}

	function setup()
	{
		this.menupanel = ::MotionPanelLayer(this.getScreen(), "defaultMotionInfo" in ::getroottable() ? ::defaultMotionInfo : null);
		this.menupanel.setDelegate(this);
		this.menupanel.setPriority(27);
	}

	function openMenuPanel( storage, chara, context = null, checkConfig = false )
	{
		if (context != null && (context instanceof this.Object) && "checkOpen" in context)
		{
			context.setDelegate(this);

			if (!context.checkOpen())
			{
				return;
			}
		}

		if (this.menupanel != null)
		{
			local e = typeof chara == "string" ? {
				chara = chara,
				focus = 0
			} : chara;
			local ret;

			try
			{
				if (checkConfig)
				{
					this.changeConfig = false;
					ret = this.menupanel.open(e, storage, context);

					if (this.changeConfig)
					{
						this.sysSave();

						if (this.player != null)
						{
							this.player.updateConfig();
						}
					}
				}
				else
				{
					ret = this.menupanel.open(e, storage, context);
				}
			}
			catch( e )
			{
				if (e instanceof this.GameStateException)
				{
					this.onOpenMenuException();
					throw e;
				}

				this.printf("failed to open menu:%s:%s\n", storage, chara);
				::printException(e);
			}

			return ret;
		}
	}

	function onOpenMenuException()
	{
	}

	function startup( signinCallback = null )
	{
		this.initConfig();
		::SaveSystem.startup(signinCallback);

		if (this.titleCount == 1)
		{
			this.gameTitlePrepare();
		}
	}

	function isPlayingBGM()
	{
		return this.bgm != null && this.bgm.playing;
	}

	function playBGM( storage, loop = 0 )
	{
		if (this.bgm == null)
		{
			this.bgm = this.Music("bgm");
		}

		if (storage != this.currentBGM || this.currentBGMLoop > 0 || !this.isPlayingBGM())
		{
			this.bgm.play(storage, loop);
			this.currentBGM = storage;
			this.currentBGMLoop = loop;
		}
	}

	function stopBGM( time = 500 )
	{
		if (this.bgm != null)
		{
			this.bgm.stop(time);
		}

		this.currentBGM = null;
	}

	function appStopVoice( time = 500, name = null )
	{
		this.stopVoice(time, name);
	}

	function appPlayVoice( name, storage, force = false )
	{
		this.playVoice(name, storage, force);
	}

	function playVoiceOnly( name, storage, force = false )
	{
		this.stopVoice();
		this.playVoice(name, storage, force);
	}

	function playVoice( name, storage, force = false )
	{
		if (this.voice == null)
		{
			this.voice = this.AppVoiceBase(this, 3, "voice");
		}

		if (force || this.getVoiceOn(name))
		{
			local volume = this.getVoiceVolume(name) * 100;

			if (force && volume < 1)
			{
				volume = 80;
			}

			this.voice.play(name, storage, volume);
			this.lastVoiceName = name;
		}
		else
		{
			this.lastVoiceName = null;
		}
	}

	function stopVoice( time = 500, name = null )
	{
		if (this.voice != null)
		{
			this.voice.stop(time, name);
			this.lastVoiceName = null;
			this.lastVoiceName = null;
		}
	}

	function isVoicePlaying( name = null )
	{
		if (name == null)
		{
			return this.voice && this.voice.getAllPlaying();
		}
		else
		{
			if (this.voice)
			{
				this.s = this.voice.findName(name);

				if (this.s)
				{
					return this.s.getPlaying();
				}
			}

			return false;
		}
	}

	function playSound( storage, wait = false, canSkip = true )
	{
		if (this.sound == null)
		{
			this.sound = this.MultiSound(2);
		}

		this.sound.play(storage, 100);

		if (wait)
		{
			for( local click = false; this.sound.playing;  )
			{
				if (canSkip && click)
				{
					this.sound.stop();
					break;
				}

				click = this.checkKeyPressed(this.KEY_OK | this.KEY_CANCEL);
				::sync();
			}
		}
	}

	function stopSound( time = 500 )
	{
		if (this.sound != null)
		{
			this.sound.stop(time);
		}
	}

	function dummyDialog( text )
	{
		this.inform(text);
	}

	function playMovie( movie, input = null )
	{
		::setRecordEnable(false);
		::SaveSystem.playMovie(movie, input, this.MOVIECANCELKEY, this.MOVIEADDKEY);
		::setRecordEnable(this.recordEnable);
	}

	function convTitleResult( ret, cur )
	{
		if (typeof ret == "array")
		{
			this.arg = ret[0];
			local info = ret[1];
			local storage = info[1];
			local label = info.len() > 2 ? info[2] : null;

			if (label != null && label.len() > 0 && label.charAt(0) != "*")
			{
				label = "*" + label;
			}

			return {
				storage = storage,
				target = label,
				mode = 3,
				cur = cur,
				arg = this.arg
			};
		}

		return ret;
	}

	function titleCommand( cur, arg )
	{
		local funcname = "title_" + cur;

		if (funcname in this)
		{
			return this.convTitleResult(this[funcname](arg), cur);
		}
		else
		{
			throw this.Exception(cur + ":\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x0088\x00e3\x0083\x00ab\x00e7\x0094\x00a8\x00e3\x0082\x00b3\x00e3\x0083\x009e\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0081\x008c\x00e5\x00ae\x009f\x00e8\x00a3\x0085\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093");
		}
	}

	function playTitleBgm()
	{
		if (this.TITLEBGM)
		{
			this.playBGM(this.TITLEBGM);
			this.setFileReaded(this.TITLEBGM);
		}
	}

	function titleLoop( cur, arg )
	{
		local scene;

		do
		{
			::sync();

			switch(cur)
			{
			case null:
			case "":
			case "title":
			case "title0":
			case "title1":
				this.playTitleBgm();
				cur = this.titleMenu(cur, arg);

				if (typeof cur == "table")
				{
					scene = cur;
					break;
				}
				else if (typeof cur == "array")
				{
					cur = cur[0];
					arg = cur[1];
				}
				else
				{
					arg = null;
				}

				break;

			case "exit":
				this.exit();
				break;

			case "start":
			case "start2":
				scene = this.getStartScene(cur);

				if (scene != null)
				{
					scene.fromStart <- true;
				}

				break;

			case "movie0":
				scene = this.titleMovie();
				arg = null;
				cur = null;
				break;

			case "movie":
				scene = this.titleMovie();
				arg = null;
				cur = this.cmdTitleState;
				break;

			case "install":
				this.install();
				arg = cur;
				cur = this.cmdTitleState;
				break;

			default:
				if (typeof arg != "table" || ::getval(arg, "titlebgm", true) == true)
				{
					this.playTitleBgm();
				}

				scene = this.titleCommand(cur, arg);

				if (scene == null)
				{
					arg = cur;
					cur = this.cmdTitleState;
				}

				break;
			}
		}
		while (scene == null);

		return scene;
	}

	player = null;
	function getPlayer()
	{
		return this.player;
	}

	function getSnapPlayer()
	{
		return this.player != null ? this.player : this.createGamePlayer(this, null);
	}

	function getSaveData()
	{
		return this.player != null ? this.player.getSaveData() : null;
	}

	function getSaveScreenCapture()
	{
		return this.player != null ? this.player.getScreenCapture() : null;
	}

	function sceneMain( scene )
	{
		local player = this.createGamePlayer(this, scene);
		player.setDelegate(this);
		this.player = player.weakref();
		local ret = player.main(scene);
		this.player = null;
		::setRecordEnable(this.recordEnable);
		return ret;
	}

	function main( args )
	{
		this.startup();
		this.onStartup();
		local scene;

		if (0 || ::System.getDebugBuild())
		{
			if ("startScene" in args)
			{
				scene = {
					storage = args.startScene
				};

				if ("startLine" in args)
				{
					scene.target <- args.startLine;
				}
			}
		}

		local cur = this.firstState;
		local arg;
		local nextScene;

		for( local stopbgm = true; true;  )
		{
			this.cleanup(stopbgm);
			this.setup();

			try
			{
				::setRecordEnable(this.recordEnable);
				::sync();

				if (scene == null)
				{
					scene = this.titleLoop(cur, arg);
				}

				arg = null;
				stopbgm = true;

				if (typeof scene == "table")
				{
					stopbgm = ::getbool(scene, "stopbgm", true);

					if (stopbgm)
					{
						this.stopBGM();
					}

					this.onStartScene(scene);
					local ret = this.sceneMain(scene);
					this.onEndScene(scene, ret);

					if (this.getint(scene, "mode", 0) == 0)
					{
						this.sysSave();
					}

					if (("cur" in scene) && scene.cur != null && scene.cur != "")
					{
						cur = scene.cur;
					}
					else
					{
						cur = this.getval(scene, "mode", 0) == 0 ? this.endTitleState : this.cmdTitleState;
					}

					arg = this.getval(scene, "arg", arg);
					this.printf("scene end cur:%s:%s\n", cur, arg);
				}
				else if (typeof scene == "array")
				{
					cur = scene[0];
					arg = scene[1];
				}
				else
				{
					cur = scene;
				}

				scene = nextScene;
				nextScene = null;
			}
			catch( e )
			{
				if (e instanceof this.GameStateException)
				{
					this.printf("Game State Exception:%s\n", e.state);

					if (typeof scene == "table")
					{
						this.onSuspendScene(scene, e.state);
					}

					switch(e.state)
					{
					case "restart":
						switch(typeof e.scene)
						{
						case "array":
							scene = e.scene[0];
							nextScene = e.scene[1];
							break;

						case "table":
							scene = e.scene;
							nextScene = null;
							break;

						default:
							break;
						}

						break;

					case "totitle":
						if (this.getint(scene, "mode", 0) == 0)
						{
							this.sysSave();
						}

						if (("cur" in scene) && scene.cur != null && scene.cur != "")
						{
							cur = scene.cur;
						}
						else
						{
							cur = this.getval(scene, "mode", 0) == 0 ? this.endTitleState : this.cmdTitleState;
						}

						arg = this.getval(scene, "arg", arg);
						nextScene = null;
						scene = nextScene;
						break;

					case "totitle2":
						if (this.getint(scene, "mode", 0) == 0)
						{
							this.sysSave();
						}

						cur = this.getval(scene, "cur", this.endTitleState);
						arg = this.getval(scene, "arg", arg);
						nextScene = null;
						scene = nextScene;
						break;

					case "exit":
						if (this.getint(scene, "mode", 0) == 0)
						{
							this.sysSave();
						}

					case "quit":
						if (("cur" in scene) && scene.cur != null && scene.cur != "")
						{
							cur = scene.cur;
						}
						else
						{
							cur = this.getval(scene, "mode", 0) == 0 ? this.endTitleState : this.cmdTitleState;
						}

						arg = this.getval(scene, "arg", arg);
						scene = nextScene;
						nextScene = null;
						break;

					case "tostart":
						nextScene = null;
						scene = nextScene;
						cur = null;
						arg = null;
						break;

					default:
						nextScene = null;
						scene = nextScene;
						break;
					}
				}
				else
				{
					local message = (e instanceof this.Exception) ? e.message : e;

					switch(message)
					{
					case "softreset_signout":
					case "softreset_eject_storage":
						this.softReset(message);
						scene = null;
						nextScene = null;
						cur = null;
						arg = null;
						break;

					default:
						::printException(e);
						scene = null;
						nextScene = null;
						cur = null;
						arg = null;
					}
				}
			}
		}
	}

	flags = {};
	function setFlag( name, value )
	{
		if (this.player != null)
		{
			this.player.setFlag(name, value);
		}
		else
		{
			this.flags[name] <- value;
		}
	}

	function getFlag( name )
	{
		if (this.player != null)
		{
			return this.player.getFlag(name);
		}
		else
		{
			local value = this.getval(this.flags, name);

			if (value == null)
			{
				value = 0;
			}

			return value;
		}
	}

	debugInfoThread = null;
	function _showDebugInfo()
	{
		local text = this.createDebugText(::DEBUG_FONTSIZE);
		local t = "";

		if (this.player != null)
		{
			local n = this.player.getDebugInfo();

			if (n != null && n != "")
			{
				t += n;
				t += "\n";
			}
		}

		t += this.getDebugInfo();
		text.print(t, this.debugInfoPosition);
		::wait();
		  // [031]  OP_JMP            0    -28    0    0
	}

	function doneDebugInfo()
	{
		if (this.debugInfoThread != null)
		{
			this.debugInfoThread.exit(0);
			this.debugInfoThread = null;
		}
	}

	function toggleDebugInfo()
	{
		if (this.debugInfoThread == null)
		{
			this.debugInfoThread = ::fork(this._showDebugInfo.bindenv(this));
		}
		else
		{
			this.doneDebugInfo();
		}
	}

	revind = null;
	function showRevisionInfo()
	{
		local revinfo = this.loadData("config/revision.psb");

		if (revinfo != null)
		{
			local revision = revinfo.root.revision;
			revision = revision.replace("$Revision: ", "");
			revision = revision.replace(" $", "");
			this.printf("revision:%s\n", revision);
			this.revind = this.createDebugText(::DEBUG_FONTSIZE);
			this.revind.print("DBG VER rev:" + revision, 1);
		}
	}

	function hideRevisionInfo()
	{
		this.revind = null;
	}

	function toggleRevisionInfo()
	{
		if (this.revind == null)
		{
			this.showRevisionInfo();
		}
		else
		{
			this.hideRevisionInfo();
		}
	}

	function isStorageEnable()
	{
		return this.checkStorage();
	}

	function gameTitleClear()
	{
		this.voiceIdMap = null;
		::SaveSystem.gameTitleClear();
		this.onTitleChange(null);
	}

	function gameTitlePrepare( title = 0, loadGame = true )
	{
		this.voiceIdMap = this.IdMap("scenario/charvoice.scn");
		::SaveSystem.gameTitlePrepare(title, loadGame);
		this.onTitleChange(title);
	}

	function openDebugMenu()
	{
		local sel;
		sel = ::select([
			"\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e6\x0093\x008d\x00e4\x00bd\x009c",
			"\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e9\x0081\x00b8\x00e6\x008a\x009e",
			"\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e8\x00a1\x00a8\x00e7\x00a4\x00ba",
			"\x00e3\x0083\x0081\x00e3\x0082\x00a7\x00e3\x0083\x0083\x00e3\x0082\x00af",
			"\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x0088\x00e3\x0083\x00ab\x00e3\x0081\x00ab\x00e6\x0088\x00bb\x00e3\x0082\x008b"
		], null, 32);

		while (sel != null)
		{
			if (sel == 3)
			{
				this.debugCheck();
			}
			else
			{
				this.debugMenu(this, sel);
				  // [025]  OP_JMP            0      0    0    0
			}
		}
	}

	function debugCheck()
	{
		local sel;
		sel = ::select([
			"\x00e3\x0083\x00a1\x00e3\x0083\x0083\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0082\x00b8\x00e3\x0081\x00af\x00e3\x0081\x00bf\x00e5\x0087\x00ba\x00e3\x0081\x0097\x00e3\x0083\x0081\x00e3\x0082\x00a7\x00e3\x0083\x0083\x00e3\x0082\x00af",
			"\x00e3\x0083\x0080\x00e3\x0082\x00a4\x00e3\x0082\x00a2\x00e3\x0083\x00ad\x00e3\x0082\x00b0\x00e3\x0081\x00af\x00e3\x0081\x00bf\x00e5\x0087\x00ba\x00e3\x0081\x0097\x00e3\x0083\x0081\x00e3\x0082\x00a7\x00e3\x0083\x0083\x00e3\x0082\x00af"
		], null, 32);

		while (sel != null)
		{
			switch(sel)
			{
			case 0:
				local player = this.createGamePlayer(this, null);
				player.setDelegate(this);
				player.checkMsgOverAll();
				break;

			case 1:
				this.checkDialogText();
				break;
			}
		}
	}

	bgm = null;
	currentBGM = null;
	currentBGMLoop = false;
	voice = null;
	sound = null;
	menupanel = null;
	textbase = null;
	lastVoiceName = null;
}

