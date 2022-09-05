class this.Environment extends this.Object
{
	player = null;
	camera = null;
	objects = null;
	layerList = null;
	musicList = null;
	soundList = null;
	constructor( player )
	{
		this.player = player.weakref();
		this.objects = {};
		this.layerList = [];
		this.musicList = [];
		this.soundList = [];
		this.camera = this.EnvCameraObject(player, "camera");
	}

	function destructor()
	{
		this.camera = null;
		this.objects.clear();
		this.layerList.clear();
		this.musicList.clear();
		this.soundList.clear();
		::Object.destructor();
	}

	function updateSpeed()
	{
		foreach( lay in this.layerList )
		{
			lay.updateSpeed();
		}
	}

	function onVoiceFlip( name, level, value )
	{
		if (name in this.objects)
		{
			local obj = this.objects[name];

			if (obj instanceof this.EnvLayerObject)
			{
				obj.onVoiceFlip(level, value);
			}
		}
	}

	function preloadList( list )
	{
		local ret = [];

		foreach( info in list )
		{
			ret.append([
				info[0],
				info[1],
				this.preloadImage(info[2])
			]);
		}

		return ret;
	}

	function syncObject( f )
	{
		if ("data" in f)
		{
			local data = f.data;
			local create = [];
			local leave = {};

			foreach( info in data )
			{
				local name = info[0];

				if (!(name in this.objects))
				{
					create.append(info);
				}

				leave[name] <- true;
			}

			local names = this.objects.keys();

			foreach( name in names )
			{
				if (!(name in leave))
				{
					this.removeEnvObject(name);
				}
			}

			if (create.len() > 0)
			{
				create = this.preloadList(create);

				foreach( value in create )
				{
					local name = value[0];
					local cname = value[1];
					local elm = value[2];
					local obj = this.createEnvObject(name, cname);

					if (obj != null && elm != null)
					{
						obj.update(elm);
					}
				}

				foreach( value in create )
				{
					local name = value[0];
					local elm = value[2];

					if ((name in this.objects) && elm != null)
					{
						this.objects[name].updateAfter(elm);
					}
				}

				foreach( lay in this.layerList )
				{
					lay.updateSource(null, true);
				}
			}
		}
	}

	function onRestore( f, snapMode = false )
	{
		if (!snapMode && "data" in f)
		{
			local data = this.preloadList(f.data);
			local cobjs = {};

			foreach( value in data )
			{
				local name = value[0];
				local cname = value[1];
				local elm = value[2];
				local obj = (name in this.objects) && this.objects[name].cname == cname ? this.objects[name] : this.createEnvObject(name, cname);

				if (obj != null && elm != null)
				{
					obj.update(elm);
				}

				cobjs[name] <- true;
			}

			foreach( value in data )
			{
				local name = value[0];
				local elm = value[2];

				if ((name in this.objects) && elm != null)
				{
					this.objects[name].updateAfter(elm);
				}
			}

			foreach( lay in this.layerList )
			{
				lay.updateSource(null, true);
			}

			local names = this.objects.keys();

			foreach( name in names )
			{
				if (!(name in cobjs))
				{
					this.removeEnvObject(name);
				}
			}

			this.camera.init();
		}
		else
		{
			this.envInit();
			local data = this.preloadList(f.data);

			foreach( value in data )
			{
				local name = value[0];
				local cname = value[1];
				local elm = value[2];
				local obj = this.createEnvObject(name, cname, snapMode);

				if (obj != null && elm != null)
				{
					obj.update(elm);
				}
			}

			foreach( value in data )
			{
				local name = value[0];
				local elm = value[2];

				if ((name in this.objects) && elm != null)
				{
					this.objects[name].updateAfter(elm);
				}
			}

			foreach( lay in this.layerList )
			{
				lay.updateSource(null, true);
			}
		}

		if ("env" in f)
		{
			this.camera.update(f.env);
			this.camera.updateAfter(f.env);
		}
	}

	function renameEnvObject( from, to )
	{
		this.removeEnvObject(to);

		if (from in this.objects)
		{
			local obj = this.objects[from];
			obj.name = to;
			delete this.objects[from];
			this.objects[to] <- obj;
		}
	}

	function swapEnvObject( from, to )
	{
		if (!(to in this.objects))
		{
			this.renameEnvObject(from, to);
		}
		else if (!(from in this.objects))
		{
			this.renameEnvObject(to, from);
		}
		else
		{
			local f = this.objects[from];
			local t = this.objects[to];
			f.name = to;
			t.name = from;
			this.objects[from] = t;
			this.objects[to] = f;
		}
	}

	function removeEnvObject( name )
	{
		if (name in this.objects)
		{
			local obj = this.objects[name];
			delete this.objects[name];

			if (obj instanceof this.EnvLayerObject)
			{
				this.layerList.removeValue(obj);
			}
			else if (obj instanceof this.EnvMusicObject)
			{
				this.musicList.removeValue(obj);
			}
			else
			{
				this.soundList.removeValue(obj);
			}
		}
	}

	function createEnvObject( name, cname, snapMode = false )
	{
		this.removeEnvObject(name);
		local obj;
		local classInfo = this.player.getClassInfo(cname);

		if (classInfo == null)
		{
			throw "\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e3\x0082\x00af\x00e3\x0083\x00a9\x00e3\x0082\x00b9\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e3\x0081\x008c\x00e8\x00a6\x008b\x00e3\x0081\x00a4\x00e3\x0081\x008b\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093:" + cname;
		}

		local type = classInfo.type;

		if (!snapMode || type == "layer")
		{
			switch(type)
			{
			case "music":
				obj = this.EnvMusicObject(this.player, name, cname, classInfo);
				this.musicList.append(obj);
				break;

			case "sound":
				obj = this.EnvSoundObject(this.player, name, cname, classInfo);
				this.soundList.append(obj);
				break;

			case "layer":
			default:
				obj = this.EnvLayerObject(this.player, name, cname, classInfo, this.camera);
				obj.setMsgVisible(this.msgvisible);
				this.layerList.append(obj);
				break;
			}

			this.objects[name] <- obj;
		}

		return obj;
	}

	function updateCamera()
	{
		local count = this.layerList.len();

		for( local i = 0; i < count; i++ )
		{
			local lay = this.layerList[i];

			if (lay != null)
			{
				lay.recalcPosition();
			}
		}
	}

	function updateWind()
	{
		local count = this.layerList.len();

		for( local i = 0; i < count; i++ )
		{
			this.layerList[i].recalcWind();
		}
	}

	function createObject( name, cname )
	{
		if (!(name in this.objects))
		{
			this.createEnvObject(name, cname);
		}
	}

	function removeObject( name )
	{
		if (name in this.objects)
		{
			this.removeEnvObject(name);
		}
	}

	function convImageFile( filename )
	{
		filename = this.player.evalStorage(filename);

		if (typeof filename == "string")
		{
			return this.player.convImageFile(filename);
		}

		return filename;
	}

	function evalImageFile( imageFile )
	{
		if (typeof imageFile == "array")
		{
			foreach( file in imageFile )
			{
				if (!("eval" in file) || this.player.eval(file.eval, false))
				{
					return file;
				}
			}

			return imageFile[imageFile.len() - 1];
		}
		else
		{
			return imageFile;
		}
	}

	function loadData( name )
	{
		return this.player != null ? this.player.loadData(name) : ::loadData(name);
	}

	function preloadImage( elm )
	{
		if (typeof elm == "table" && "redraw" in elm)
		{
			try
			{
				elm = this.convertPSBValue(elm);
				local imageFile = this.evalImageFile(::getval(elm.redraw, "imageFile"));

				switch(typeof imageFile)
				{
				case "string":
					imageFile = this.convImageFile(imageFile);
					imageFile = this.loadImageData(imageFile);
					break;

				case "table":
					local storage = ::getval(imageFile, "storage");

					if (storage == null)
					{
						storage = ::getval(imageFile, "file");
					}

					if (storage != null)
					{
						storage = this.convImageFile(storage);

						if (typeof storage == "string")
						{
							imageFile.storage <- storage;
							local l;
							local ext;
							l = storage.rfind(".");

							if (storage != null && l > 0)
							{
								ext = storage.substr(l + 1);
							}

							if (ext == "psb" || ext == "mtn" || ext == null && !("movie" in imageFile))
							{
								imageFile.imagedata <- this.loadImageData(storage);
							}
						}
						else
						{
							foreach( name, value in this.file )
							{
								imageFile[name] <- value;
							}
						}
					}

					break;
				}

				elm.redraw.imageFile = imageFile;
			}
			catch( e )
			{
				this.printf("%s:\x00e7\x0094\x00bb\x00e5\x0083\x008f\x00e4\x00ba\x008b\x00e5\x0089\x008d\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", this.name, e);
				::printException(e);
			}
		}

		return elm;
	}

	function objUpdate( l )
	{
		local list = [];

		foreach( elm in l )
		{
			list.append(this.preloadImage(elm));
		}

		foreach( work in list )
		{
			if (typeof work == "array")
			{
				switch(work[0])
				{
				case "init":
					this.player.envInit();
					this.envInit({
						nostopbgm = work[1]
					});
					break;

				case "del":
					this.removeObject(work[1]);
					break;

				case "new":
					this.createObject(work[1], work[2]);
					break;

				case "ren":
					this.renameEnvObject(work[1], work[2]);
					break;

				case "swp":
					this.swapEnvObject(work[1], work[2]);
					break;

				case "tag":
					if (!this.player.onTag(work[1]))
					{
						this.printf("envupdate:\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0081\x00aa\x00e5\x009f\x008b\x00e3\x0082\x0081\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e3\x0082\x00bf\x00e3\x0082\x00b0:%s\n", work[1].tagname);
					}

					break;
				}
			}
			else if (work.name == "env")
			{
				this.camera.objUpdate(work);
			}
			else if (work.name in this.objects)
			{
				local obj = this.objects[work.name];
				obj.objUpdate(work);
			}
		}

		foreach( work in list )
		{
			if (typeof work != "array")
			{
				if (work.name == "env")
				{
					this.camera.objUpdateAfter(work);
				}
				else if (work.name in this.objects)
				{
					local obj = this.objects[work.name];
					obj.objUpdateAfter(work);
				}
			}
		}
	}

	function createWait( elm, transWait )
	{
		if (elm == null)
		{
			if (transWait)
			{
				return {
					checkfunc = this.player.inTransition.bindenv(this.player),
					stopfunc = this.player.stopTransition.bindenv(this.player)
				};
			}
		}
		else if (elm.name == "env")
		{
			return this.camera.createWait(elm.mode);
		}
		else if (elm.name in this.objects)
		{
			return this.objects[elm.name].createWait(elm.mode);
		}
	}

	function envWait( wait, transWait )
	{
		local infos = [];

		foreach( e in wait.list )
		{
			local ret = this.createWait(e, transWait);

			if (ret != null)
			{
				infos.append(ret);
			}
		}

		if (infos.len() > 0)
		{
			local canSkip = ::getval(wait, "canskip", true);

			if (this.player.waitFunction(canSkip, function () : ( infos )
			{
				foreach( info in infos )
				{
					if (info.checkfunc())
					{
						return true;
					}
				}

				return false;
			}, function () : ( infos )
			{
				foreach( info in infos )
				{
					if ("stopfunc" in info)
					{
						info.stopfunc();
					}
				}
			}) == 0)
			{
				if ("wait" in wait)
				{
					this.player.waitTime(wait.wait, canSkip);
				}
			}
		}

		if ("del" in wait)
		{
			foreach( name in wait.del )
			{
				this.removeObject(name);
			}
		}
	}

	function objStop( elm )
	{
		this.dm("call objstop:" + elm.name);
	}

	function envInit( elm = null )
	{
		local names = this.objects.keys();
		local nostopbgm = ::getval(elm, "nostopbgm", false);

		foreach( name in names )
		{
			local obj = this.objects[name];

			if (!(nostopbgm && (obj instanceof this.EnvMusicObject) && obj.isPlayingLoop()))
			{
				this.removeEnvObject(name);
			}
		}

		this.camera.init();
	}

	function envUpdate( elm )
	{
		if ("msgoff" in elm)
		{
			this.player.tag_msgoff();
		}

		if ("pretrans" in elm)
		{
			this.objUpdate(elm.pretrans);
		}

		local canskip = !("wait" in elm) || !("canskip" in elm.wait) || elm.wait.canskip != 0;
		local isblack = false;

		if ("trans" in elm)
		{
			local trans = elm.trans;
			local msgchange = ::getval(elm, "msgchange");

			if (typeof trans == "table" && ("blacktrans" in trans) && "begin" in trans)
			{
				isblack = true;
				local e = ::getval(trans, "begin", {});
				e = this.duplicate(e);
				e.canskip <- canskip;
				this.player.setupTransition(msgchange);
				this.player.blackTransBegin(e);
				this.player.beginEnvTrans(false);
			}
			else
			{
				this.player.beginEnvTrans(msgchange);
			}
		}

		if ("update" in elm)
		{
			this.objUpdate(elm.update);
		}

		local transWait = false;

		if ("trans" in elm)
		{
			local trans = elm.trans;

			if (isblack)
			{
				this.player.doAfter();
				local e = ::getval(trans, "end", {});
				e = this.duplicate(e);
				e.canskip <- canskip;
				this.player.blackTransEnd(e);
			}
			else
			{
				this.player.doEnvTrans(trans);
				transWait = true;
			}
		}

		this.player.updateMsg();

		if ("wait" in elm)
		{
			this.envWait(elm.wait, transWait);
		}
	}

	function pauseMus( all = false )
	{
		foreach( mus in this.musicList )
		{
			mus.sysPause(all);
		}
	}

	function restartMus()
	{
		foreach( mus in this.musicList )
		{
			mus.sysRestart();
		}
	}

	msgvisible = false;
	function setMsgVisible( msgvisible )
	{
		this.msgvisible = msgvisible;

		foreach( lay in this.layerList )
		{
			lay.setMsgVisible(msgvisible);
		}
	}

	function checkMsgwinLayer()
	{
		foreach( lay in this.layerList )
		{
			if (lay.checkMsgwinLayer())
			{
				return true;
			}
		}

		return false;
	}

	function pauseMotion( state )
	{
		foreach( lay in this.layerList )
		{
			lay.pauseMotion(state);
		}
	}

	function dispSync()
	{
		foreach( lay in this.layerList )
		{
			lay.dispSync();
		}
	}

	function updateImage()
	{
		foreach( lay in this.layerList )
		{
			lay.updateImage({});
		}
	}

}

