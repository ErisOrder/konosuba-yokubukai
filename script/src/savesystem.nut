class this.IdMap extends this.Object
{
	constructor( path, casecheck = true )
	{
		this.data = ::loadData(path);
		this.list = this.data.root.list;
		this.map = this.data.root.map;
		this.casesensitive = casecheck;
	}

	function getId( id )
	{
		if (typeof id == "integer")
		{
			return id;
		}
		else if (typeof id == "string")
		{
			if (!this.casesensitive)
			{
				id = id.tolower();
			}

			try
			{
				return this.map[id];
				  // [019]  OP_POPTRAP        1      0    0    0
			}
			catch( e )
			{
			}
		}

		return -1;
	}

	function getInfo( id )
	{
		id = this.getId(id);
		return id >= 0 && id < this.list.len() ? this.list[id] : null;
	}

	function getCount()
	{
		return this.list.len();
	}

	data = null;
	list = null;
	map = null;
	casesensitive = true;
}

class this.NoInterruptConfirmDialog extends this.ConfirmDialog
{
	function sync()
	{
		::wait();
	}

}

function convertPSBValue( value, recursive = true )
{
	if (value instanceof this.PSBValue)
	{
		if (recursive)
		{
			if (typeof value == "table")
			{
				local ret = {};
				local f = this.PSBValue.getValue.bindenv(value);

				foreach( n, v in value )
				{
					ret[n] <- this.convertPSBValue(f(n));
				}

				return ret;
			}
			else if (typeof value == "array")
			{
				local ret = [];

				foreach( v in value )
				{
					ret.append(this.convertPSBValue(v));
				}

				return ret;
			}
		}
		else if (typeof value == "table")
		{
			local ret = {};
			local f = this.PSBValue.getValue.bindenv(value);

			foreach( n, v in value )
			{
				ret[n] <- f(n);
			}

			return ret;
		}
		else if (typeof value == "array")
		{
			local ret = [];

			foreach( v in value )
			{
				ret.append(v);
			}

			return ret;
		}
	}
	else if (value instanceof this.StructValue)
	{
		if (recursive)
		{
			if (typeof value == "table")
			{
				local ret = {};
				local f = this.StructValue.getValue.bindenv(value);

				foreach( n, v in value )
				{
					ret[n] <- this.convertPSBValue(f(n));
				}

				return ret;
			}
			else if (typeof value == "array")
			{
				local ret = [];

				foreach( v in value )
				{
					ret.append(this.convertPSBValue(v));
				}

				return ret;
			}
		}
		else if (typeof value == "table")
		{
			local ret = {};
			local f = this.StructValue.getValue.bindenv(value);

			foreach( n, v in value )
			{
				ret[n] <- f(n);
			}

			return ret;
		}
		else if (typeof value == "array")
		{
			local ret = [];

			foreach( v in value )
			{
				ret.append(v);
			}

			return ret;
		}
	}

	return value;
}

class this.SaveSystem extends this.Object
{
	DEFAULT_MOVIE_SKIPKEY = this.KEY_CANCEL | 8;
	DEFAULT_MOVIE_CANCELWAIT = 3;
	CROSSLOAD_THUMBNAIL_UPDATE = null;
	function buildFileInfo( info, index, type = 0 )
	{
		local fileInfo = {
			info = info,
			index = index,
			type = type
		};
		return fileInfo;
	}

	function getDebugInfo()
	{
		return this.format("sqheap:%f", ::System.getSqHeapLoad());
	}

	function onSystemFlag( type, name, value, old )
	{
	}

	function onConfigUpdate( name = null )
	{
		this._onConfigUpdate(name);
	}

	function onNewFile( filename )
	{
	}

	function onStartSave( type )
	{
	}

	function onEndSave( type )
	{
	}

	constructor( info, titleID = null, main = true )
	{
		::Object.constructor();
		this.THUMBNAIL_WIDTH = ::getval(info, "THUMBNAIL_WIDTH", 128);
		this.THUMBNAIL_HEIGHT = ::getval(info, "THUMBNAIL_HEIGHT", 72);
		this.spec = ::System.getSpec();
		local backupData = ::loadData("config/backup.psb");
		this.PACKMODE = ::getval(info, "SAVEDATA_PACKMODE", 0);
		this.printf("PACKMODE:%s\n", this.PACKMODE);
		this.pageCount = ::getval(info, "SAVEDATA_PAGE_COUNT", 10);
		this.crossPageCount = ::getval(info, "SAVEDATA_CROSS_PAGE_COUNT", 1);
		this.autoPageCount = ::getval(info, "SAVEDATA_AUTO_PAGE_COUNT", 1);
		this.printf("make system struct\n");
		this.systemStruct = ::Struct(backupData, "systemdata");
		this.sysflag = this.systemStruct.root.sysflag;
		this.config = this.systemStruct.root.config;
		this.medal = "medal" in this.systemStruct.root ? this.systemStruct.root.medal : null;
		local nocheckowner = ::getval(info, "BACKUP_NOCHECKOWNER", false);
		this.manager = ::AdvBackupManager();
		this.printf("manager: %s\n", this.manager);

		if ("setSingleFileMode" in this.manager)
		{
			this.printf("set single file mode\n");
			this.manager.setSingleFileMode(true);
		}

		this.manager.title = ::getval(info, "GAMETITLE");
		this.systemBackup = this.manager.addSegment(this.systemStruct, 1);
		this.printf("systemBackupSegment: %s\n", this.systemBackup);
		this.systemBackup.dialogName = ::getval(info, "BACKUP_DIALOG");

		if (nocheckowner)
		{
			this.systemBackup.setNoCheckOwner(true);
		}

		this.titleCount = ::getval(info, "TITLE_COUNT", 1);
		this.printf("title count:%d\n", this.titleCount);

		if (this.PACKMODE == 0 || this.PACKMODE == 2)
		{
			this.gameStruct = [];
			this.gameBackup = [];

			for( local i = 0; i < this.titleCount; i++ )
			{
				local struct;

				switch(this.PACKMODE)
				{
				case 0:
					struct = ::Struct(backupData, this.format("gamepackhead%d", i));
					break;

				case 1:
					struct = ::Struct(backupData, this.format(this.BACKUP_GAMEPACKPAGE_ROOT, i));
					break;

				case 2:
					struct = ::Struct(backupData, this.format("gamepack%d", i));
					break;
				}

				if (this.PACKMODE == 0 || this.PACKMODE == 2)
				{
					this.pageSize = ::getval(info, "SAVEDATA_PAGESIZE", 10);
					this.crossDataCount = ::getval(info, "SAVEDATA_CROSS_DATA_COUNT");

					if (this.crossDataCount == null)
					{
						this.crossDataCount = this.crossPageCount * this.pageSize;
					}
					else
					{
						this.crossPageCount = this.crossDataCount / this.pageSize;
					}

					this.autoDataCount = ::getval(info, "SAVEDATA_AUTO_DATA_COUNT");

					if (this.autoDataCount == null)
					{
						this.autoDataCount = this.autoPageCount * this.pageSize;
					}
					else
					{
						this.autoPageCount = this.autoDataCount / this.pageSize;
					}

					this.dataCount = struct.root.data.len() - this.crossDataCount - this.autoDataCount;
					this.pageCount = this.dataCount / this.pageSize;
				}

				this.gameStruct.append(struct);
				this.printf("data count:%d auto:%d cross:%d\n", this.dataCount, this.autoDataCount, this.crossDataCount);
				local backup = this.manager.addSegment(struct, 1);
				backup.dialogName = ::getval(info, "BACKUP_GAMEDIALOG" + i, ::getval(info, "BACKUP_GAMEDIALOG"));

				if (nocheckowner)
				{
					backup.setNoCheckOwner(true);
				}

				this.gameBackup.append(backup);
			}
		}

		if (this.PACKMODE == 0 || this.PACKMODE == 1)
		{
			this.dataStruct = [];
			this.dataBackup = [];

			for( local i = 0; i < this.titleCount; i++ )
			{
				local struct;

				if (this.PACKMODE == 0)
				{
					struct = ::Struct(backupData, this.format("gamedata%d", i));
					this.dataSegCount = this.gameStruct[i].root.data.len();
				}
				else
				{
					struct = ::Struct(backupData, this.format("gamepage%d", i));
					this.dataSegCount = this.pageCount + this.crossPageCount + this.autoPageCount;
					this.pageSize = struct.root.data.len();
					this.dataCount = this.pageCount * this.pageSize;
					this.crossDataCount = this.crossPageCount * this.pageSize;
					this.autoDataCount = this.autoPageCount * this.pageSize;
				}

				this.dataStruct.append(struct);
				local backup = this.manager.addSegment(struct, this.dataSegCount);
				backup.dialogName = ::getval(info, "BACKUP_GAMEDIALOG" + i, ::getval(info, "BACKUP_GAMEDIALOG"));

				if (nocheckowner)
				{
					backup.setNoCheckOwner(true);
				}

				this.dataBackup.append(backup);
			}
		}

		this.printf("pageSize:%d\n", this.pageSize);
		this.printf("page:%d %d %d\n", this.pageCount, this.autoPageCount, this.crossPageCount);
		this.printf("data:%d %d %d\n", this.dataCount, this.autoDataCount, this.crossDataCount);
		backupData = null;

		switch(this.spec)
		{
		case "psp":
			if (titleID != null)
			{
				this.manager.titleId = titleID;
			}
			else if ("BACKUP_TITLEID" in info)
			{
				this.manager.titleId = ::getval(info, "BACKUP_TITLEID");
			}

			if (main)
			{
				if ("INSTALL_ID" in info)
				{
					::System.setAppInstallId(info.INSTALL_ID);
				}

				this.INSTALL_CONFIG_NAME = ::getval(info, "INSTALL_CONFIG_NAME", "install");
				this.installer = this.InstallManager();
				this.installer.title = ::getval(info, "INSTALL_TITLE", ::getval(info, "GAMETITLE"));
				this.installer.comment = ::getval(info, "INSTALL_COMMENT");
				this.installer.detail = ::getval(info, "INSTALL_DETAIL");
			}

			this.systemBackup.cancelDuplicatedAutoSaveErrorDialog = false;

			if (this.gameBackup != null)
			{
				foreach( backup in this.gameBackup )
				{
					backup.cancelDuplicatedAutoSaveErrorDialog = false;
				}
			}

		case "ps3":
			if (titleID != null)
			{
				this.manager.titleId = titleID;
			}
			else if ("BACKUP_TITLEID" in info)
			{
				this.manager.titleId = ::getval(info, "BACKUP_TITLEID");
			}

			this.manager.secureFileId = "#\x0015\"\x00ff\x0081#B\x009a\x00b2#\x00ea#\x007fb\x0013\x0081";
			this.systemBackup.icon0 = ::getval(info, "BACKUP_ICON", "savedata/game_icon0.png");
			this.systemBackup.newDataIcon0 = ::getval(info, "BACKUP_ICON", "savedata/game_icon0.png");
			this.systemBackup.comment = ::getval(info, "BACKUP_COMMENT");
			this.systemBackup.detail = ::getval(info, "BACKUP_DETAIL");
			this.systemBackup.noDuplicate = true;

			if (this.gameBackup != null)
			{
				foreach( i, backup in this.gameBackup )
				{
					backup.icon0 = ::getval(info, "BACKUP_GAMEICON" + i, ::getval(info, "BACKUP_GAMEICON", "savedata/game_icon0.png"));
					backup.newDataIcon0 = ::getval(info, "BACKUP_NEWDATAICON" + i, ::getval(info, "BACKUP_NEWDATAICON", "savedata/game_icon0.png"));
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.detail = ::getval(info, "BACKUP_GAMEDETAIL" + i, ::getval(info, "BACKUP_GAMEDETAIL"));
					backup.noDuplicate = true;
				}
			}

			break;

		case "vita":
			this.systemBackup.icon0 = ::getval(info, "BACKUP_ICON", "saveicon.png");
			this.systemBackup.newDataIcon0 = ::getval(info, "BACKUP_ICON", "saveicon.png");
			this.systemBackup.comment = ::getval(info, "BACKUP_COMMENT");
			this.systemBackup.detail = ::getval(info, "BACKUP_DETAIL");

			if (this.gameBackup != null)
			{
				foreach( i, backup in this.gameBackup )
				{
					backup.icon0 = ::getval(info, "BACKUP_GAMEICON" + i, ::getval(info, "BACKUP_GAMEICON", "saveicon.png"));
					backup.newDataIcon0 = ::getval(info, "BACKUP_NEWDATAICON" + i, ::getval(info, "BACKUP_NEWDATAICON", "saveicon.png"));
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.detail = ::getval(info, "BACKUP_GAMEDETAIL" + i, ::getval(info, "BACKUP_GAMEDETAIL"));
				}
			}

			if (this.dataBackup != null)
			{
				foreach( i, backup in this.dataBackup )
				{
					backup.icon0 = ::getval(info, "BACKUP_GAMEICON" + i, ::getval(info, "BACKUP_GAMEICON", "saveicon.png"));
					backup.newDataIcon0 = ::getval(info, "BACKUP_NEWDATAICON" + i, ::getval(info, "BACKUP_NEWDATAICON", "saveicon.png"));
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.detail = ::getval(info, "BACKUP_GAMEDETAIL" + i, ::getval(info, "BACKUP_GAMEDETAIL"));
				}
			}

			break;

		case "ps4":
			this.systemBackup.icon0 = ::getval(info, "BACKUP_ICON", "saveicon.png");
			this.systemBackup.newDataIcon0 = ::getval(info, "BACKUP_ICON", "saveicon.png");
			this.systemBackup.comment = ::getval(info, "BACKUP_COMMENT");
			this.systemBackup.detail = ::getval(info, "BACKUP_DETAIL");

			if (this.gameBackup != null)
			{
				foreach( i, backup in this.gameBackup )
				{
					backup.icon0 = "saveicon.png";
					backup.newDataIcon0 = "saveicon.png";
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.detail = ::getval(info, "BACKUP_GAMEDETAIL" + i, ::getval(info, "BACKUP_GAMEDETAIL"));
				}
			}

			if (this.dataBackup != null)
			{
				foreach( i, backup in this.dataBackup )
				{
					backup.icon0 = ::getval(info, "BACKUP_GAMEICON" + i, ::getval(info, "BACKUP_GAMEICON", "saveicon.png"));
					backup.newDataIcon0 = ::getval(info, "BACKUP_NEWDATAICON" + i, ::getval(info, "BACKUP_NEWDATAICON", "saveicon.png"));
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.detail = ::getval(info, "BACKUP_GAMEDETAIL" + i, ::getval(info, "BACKUP_GAMEDETAIL"));
				}
			}

			break;

		case "x360":
			this.systemBackup.comment = this.getval(info, "BACKUP_COMMENT");
			this.systemBackup.overWrite = true;
			this.systemBackup.setNeedSpace(::getint(info, "BACKUP_SIZE"));

			if (this.gameBackup != null)
			{
				foreach( i, backup in this.gameBackup )
				{
					backup.comment = ::getval(info, "BACKUP_GAMECOMMENT" + i, ::getval(info, "BACKUP_GAMECOMMENT"));
					backup.overWrite = true;
					backup.setNeedSpace(::getint(info, "BACKUP_GAMESIZE"));
				}
			}

			break;
		}

		this.manager.init();

		while (this.manager.running)
		{
			this.wait();
		}

		if (main)
		{
			local data = ::loadData("config/config.psb");
			this.configInit = this.convertPSBValue(data.root.init);
			this.initConfig();
			this.initPlayTime();

			if (this.spec == "psp")
			{
				::sync <- this.checkSyncPSP.bindenv(this);
			}
			else if (this.spec == "x360")
			{
				::sync <- this.checkSyncX360.bindenv(this);
			}

			if ("TUS" in ::getroottable())
			{
				local tusinfo = this.getval(info, "tus");

				if (tusinfo != null)
				{
					this.tus = this.TUS(tusinfo);
				}
				else
				{
					this.printf("no TUS info\n");
				}
			}
			else
			{
				this.printf("no TUS module\n");
			}
		}

		this.fileIdMap = null;
		this.sceneIdMap = null;
		this.qsave = [];
	}

	function destructor()
	{
		this.gameTitleClear();
		this.systemBackup = null;
		this.gameStruct = null;
		this.gameBackup = null;
		this.dataStruct = null;
		this.dataBackup = null;
		this.manager = null;
		this.systemStruct = null;
	}

	function exit()
	{
		::System.exit();
	}

	function playMovie( name, aInput = null, cancelKey = null, addKey = null, cancelWait = null )
	{
		if (name != null && name != "")
		{
			this.printf("movie play:%s\n", name);

			if (cancelKey == null)
			{
				cancelKey = this.DEFAULT_MOVIE_SKIPKEY;
			}

			if (addKey == null)
			{
				addKey = this.ENTERKEY;
			}

			if (cancelWait == null)
			{
				cancelWait = this.DEFAULT_MOVIE_CANCELWAIT;
			}

			if (this.getFileReaded(name))
			{
				cancelKey = cancelKey | addKey;
			}

			this.playMovieUtil(name, cancelKey, aInput, cancelWait);
			this.setFileReaded(name);
		}
	}

	function setEnableScreenSaver( enable )
	{
		if (this.spec == "x360")
		{
			::System.setEnableScreenSaver(enable);
		}
	}

	function getBaseScreen()
	{
		return ::baseScreen;
	}

	function confirm( text, cur = 0, screen = null, priority = 30, shift = 0 )
	{
		if (screen == null)
		{
			screen = this.getBaseScreen();
		}

		return ::ConfirmDialog(screen, priority, shift).confirm(text, cur) != 0;
	}

	function inform( text, screen = null, priority = 30, shift = 0 )
	{
		if (screen == null)
		{
			screen = this.getBaseScreen();
		}

		::ConfirmDialog(screen, priority, shift).inform(text);
	}

	function halt( text, screen = null, priority = 30, shift = 0 )
	{
		if (screen == null)
		{
			screen = this.getBaseScreen();
		}

		::ConfirmDialog(screen, priority, shift).halt(text);
	}

	function getScreen()
	{
		return ::baseScreen;
	}

	function getDlcNum()
	{
		if ("getDlcNum" in this.manager)
		{
			return this.manager.getDlcNum();
		}
	}

	function getDlcInfoString( no, name )
	{
		if ("getDlcInfoString" in this.manager)
		{
			return this.manager.getDlcInfoString(no, name);
		}
	}

	function getHistoryMax()
	{
		return this.getDataBase().history.len();
	}

	function getIntFlags()
	{
		local ret = [];

		foreach( info in this.getFlagInfoList() )
		{
			if (info.type == "integer" || info.type == "bool")
			{
				ret.append(info.name);
			}
		}

		return ret;
	}

	function isExistConfig( name )
	{
		return name in this.config;
	}

	function getConfig( name, def = null )
	{
		if (name == "install")
		{
			name = this.INSTALL_CONFIG_NAME;
		}

		try
		{
			if (typeof this.config[name] == "bool")
			{
				  // [018]  OP_POPTRAP        1      0    0    0
				return this.config[name] ? 1 : 0;
			}

			local ret = this.config[$[stack offset 1]];

			if (ret != null)
			{
				  // [025]  OP_POPTRAP        1      0    0    0
				return ret;
			}
		}
		catch( e )
		{
			if (def == null)
			{
				this.printf("\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0082\x00b3\x00e3\x0083\x00b3\x00e3\x0083\x0095\x00e3\x0082\x00a3\x00e3\x0082\x00b0\x00e5\x0090\x008d\x00e3\x0081\x008c\x00e3\x0081\x0082\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093:%s\n", $[stack offset 1]);
			}
		}

		return def;
	}

	function setConfig( name, value )
	{
		this._setConfig(name, value);

		try
		{
			this.onConfigUpdate(name);
		}
		catch( e )
		{
			this.printf("failed to exec onConfigUpdate:%s\n", e.message);
			::printException(e);
		}
	}

	function initConfig()
	{
		local vfl = "vflag".len();
		local vvl = "voice".len();

		foreach( name, value in this.config )
		{
			local l = name.len();

			if (l >= vfl && name.substr(0, vfl) == "vflag" || l >= vvl && name.substr(0, vvl) == "voice")
			{
				this._setConfig(name, 1);
			}
		}

		foreach( name, value in this.configInit )
		{
			this._setConfig(name, value);
		}

		this._setConfig("scaleMode", ::getScaleMode());
		this._setConfig("fullScreen", ::getFullScreen());
		this.onConfigUpdate();
	}

	function askInitConfig()
	{
		if (this.confirm("YESNO_INIT", "no"))
		{
			this.initConfig();
			return true;
		}
	}

	function getIntSystemFlags()
	{
		local ret = [];

		foreach( info in this.getSystemFlagInfoList() )
		{
			if (info.type == "integer" || info.type == "bool")
			{
				ret.append(info.name);
			}
		}

		return ret;
	}

	function isExistSystemFlag( name )
	{
		if (name in this.tsysflag || name in this.sysflag)
		{
			return true;
		}
		else
		{
			local l = name.len();
			return l >= 6 && name.substr(0, 6) == "movie_" || l >= 4 && name.substr(0, 4) == "bgm_" || l >= 3 && name.substr(0, 3) == "cg_";
		}
	}

	function getSystemFlag( name, def = null )
	{
		local sf = name in this.tsysflag ? this.tsysflag : name in this.sysflag ? this.sysflag : null;

		if (sf != null)
		{
			if (typeof sf[name] == "bool")
			{
				return sf[name] ? 1 : 0;
			}
			else
			{
				return sf[name];
			}
		}
		else
		{
			local l = name.len();

			if (l >= 6 && name.substr(0, 6) == "movie_")
			{
				return this.getFileReaded(name.substr(6));
			}
			else if (l >= 4 && name.substr(0, 4) == "bgm_")
			{
				return this.getFileReaded(name.substr(4));
			}
			else if (l >= 3 && name.substr(0, 3) == "cg_")
			{
				return this.getFileReaded(name.substr(3));
			}
			else
			{
				this.printf("no such variable:%s\n", name);
			}
		}

		return def;
	}

	function setSystemFlag( name, value = true )
	{
		local type;
		local old;
		local sf = name in this.tsysflag ? this.tsysflag : name in this.sysflag ? this.sysflag : null;

		if (sf != null)
		{
			old = sf[name];

			if (typeof sf[name] == "bool")
			{
				sf[name] = value != 0;
			}
			else
			{
				sf[name] = value;
			}

			type = 3;
		}
		else
		{
			local l = name.len();

			if (l >= 6 && name.substr(0, 6) == "movie_")
			{
				this.setFileReaded(name.substr(6));
				type = 0;
			}
			else if (l >= 4 && name.substr(0, 4) == "bgm_")
			{
				this.setFileReaded(name.substr(4));
				type = 1;
			}
			else if (l >= 3 && name.substr(0, 3) == "cg_")
			{
				this.setFileReaded(name.substr(3));
				type = 0;
			}
			else if (l >= 2 && name.substr(0, 2) == "md")
			{
				if (this.medal_system)
				{
					this.medal_system.give(name);
				}

				if (this.medal != null)
				{
					local n = 2;

					while (name.charAt(n) == "0")
					{
						n++;
					}

					n = ::toint(name.substr(n));
					this.printf("medal:%s -> %s\n", name, n);

					if (n >= 0 && n < this.medal.len())
					{
						this.printf("get medal:%d\n", n);
						this.medal[n] = true;
					}
				}

				type = 2;
			}
			else
			{
				this.printf("\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x0090\x008d\x00e3\x0081\x008c\x00e3\x0081\x0082\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093:%s\n", name);
				type = 3;
			}
		}

		this.onSystemFlag(type, name, value, old);
	}

	function getSceneId( id )
	{
		return this.sceneIdMap.getId(id);
	}

	function getSceneInfo( id )
	{
		return this.sceneIdMap.getInfo(id);
	}

	function setReaded( sceneId, value )
	{
		sceneId = this.getSceneId(sceneId);

		if (sceneId >= 0 && sceneId < this.rdsceneMax)
		{
			local v = this.rdscene[sceneId].text;

			if (value > v)
			{
				this.rdscene[sceneId].text = value;
			}
		}
	}

	function getReaded( sceneId )
	{
		sceneId = this.getSceneId(sceneId);

		if (sceneId >= 0 && sceneId < this.rdsceneMax)
		{
			return this.rdscene[sceneId].text;
		}

		return 0;
	}

	function setSelectReaded( sceneId, n )
	{
		sceneId = this.getSceneId(sceneId);

		if (sceneId >= 0 && sceneId < this.rdsceneMax)
		{
			this.rdscene[sceneId].select = this.rdscene[sceneId].select | 1 << n;
		}
	}

	function getSelectReaded( sceneId, n )
	{
		sceneId = this.getSceneId(sceneId);

		if (sceneId >= 0 && sceneId < this.rdsceneMax)
		{
			return (this.rdscene[sceneId].select & 1 << n) != 0;
		}

		return false;
	}

	function isSceneReaded( sceneId )
	{
		return this.getReaded(sceneId) > 0;
	}

	function isSceneFirstTextReaded( sceneId )
	{
		return this.getReaded(sceneId) > 1;
	}

	function isSceneAllReaded( sceneId )
	{
		local count = this.getReaded(sceneId);
		local info = this.getSceneInfo(sceneId);

		if (info != null)
		{
			return count >= info.textCount + 1;
		}

		return false;
	}

	function setSceneReaded( sceneId )
	{
		local info = this.getSceneInfo(sceneId);
		this.setReaded(sceneId, info.textCount + 1);
	}

	function getReadedTextCount()
	{
		return ::getReadedTextCount(this.rdscene, this.sceneIdMap.list);
	}

	function setDictionaryReaded( index )
	{
		local rddictionary = this.systemStruct.root.rddictionary;

		if (index >= 0 && index < rddictionary.len())
		{
			rddictionary[index] = true;
		}
	}

	function getDictionaryReaded( index )
	{
		local rddictionary = this.systemStruct.root.rddictionary;

		if (index >= 0 && index < rddictionary.len())
		{
			return rddictionary[index];
		}
		else
		{
			return false;
		}
	}

	function getFileId( id )
	{
		return this.fileIdMap != null ? this.fileIdMap.getId(id) : -1;
	}

	function setFileReaded( filename )
	{
		if (this.fileIdMap != null)
		{
			filename = filename.tolower();
			local fileId = this.fileIdMap.getId(filename);

			if (fileId >= 0 && fileId < this.rdfileMax)
			{
				if (!this.rdfile[fileId])
				{
					this.rdfile[fileId] = true;
					this.onNewFile(filename);
				}
			}
		}
	}

	function getFileReaded( filename )
	{
		if (this.fileIdMap != null && typeof filename == "string")
		{
			filename = filename.tolower();
			local fileId = this.fileIdMap.getId(filename);

			if (fileId >= 0 && fileId < this.rdfileMax)
			{
				return this.rdfile[fileId];
			}
		}

		return false;
	}

	function gameTitleClear()
	{
		this.fileIdMap = null;
		this.sceneIdMap = null;
		this.titleData = null;
		this.tsysflag = null;
		this.tusStruct = null;
	}

	function gameTitlePrepare( title = 0, loadGameData = true )
	{
		this.title = title;
		this.fileIdMap = this.IdMap("scenario/filelist.scn");
		this.sceneIdMap = this.IdMap("scenario/scenelist.scn");
		this.titleData = this.systemStruct.root[this.format("title%d", title)];
		this.tsysflag = "sysflag" in this.titleData ? this.titleData.sysflag : null;
		this.rdscene = "rdscene" in this.titleData ? this.titleData.rdscene : null;
		this.rdsceneMax = this.rdscene != null ? this.rdscene.len() : 0;
		this.rdfile = "rdfile" in this.titleData ? this.titleData.rdfile : null;
		this.rdfileMax = this.rdfile != null ? this.rdfile.len() : 0;
		local sceneCount = this.sceneIdMap.getCount();
		local fileCount = this.fileIdMap.getCount();
		this.printf("\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e6\x0095\x00b0:%d/%d \x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e6\x0095\x00b0:%d/%d\n", sceneCount, this.rdsceneMax, fileCount, this.rdfileMax);

		if (sceneCount > this.rdsceneMax || fileCount > this.rdfileMax)
		{
			this.halt(this.format("\x00e8\x00ad\x00a6\x00e5\x0091\x008a:\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e6\x0095\x00b0\x00e3\x0081\x00be\x00e3\x0081\x009f\x00e3\x0081\x00af\x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e6\x0095\x00b0\x00e3\x0081\x008c\x00e8\x00a8\x0098\x00e9\x008c\x00b2\x00e4\x00b8\x008a\x00e9\x0099\x0090\x00e3\x0082\x0092\x00e8\x00b6\x0085\x00e3\x0081\x0088\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x0099\nscn:%d/%d file:%d/%d\n", sceneCount, this.rdsceneMax, fileCount, this.rdfileMax));
		}

		this.gstruct = this.gameStruct != null ? this.gameStruct[title] : null;
		this.gbackup = this.gameBackup != null ? this.gameBackup[title] : null;
		this.dstruct = this.dataStruct != null ? this.dataStruct[title] : null;
		this.dbackup = this.dataBackup != null ? this.dataBackup[title] : null;
		this.printf("make tus struct\n");
		local backupData = ::loadData("config/backup.psb");
		local name = this.format("tuspack%d", title);

		if (backupData != null && name in backupData.root)
		{
			this.tusStruct = ::Struct(backupData, name);
		}

		if (loadGameData && this.gbackup != null)
		{
			switch(this.spec)
			{
			case "psp":
			case "x360":
				break;

			default:
				local dialog = ::ConfirmDialog(this.getBaseScreen());
				dialog.show(this.getGameDataText("DIALOG_LOADING"));

				if (!this.doLoadSegment(this.gbackup))
				{
					this.gstruct.clear();
					dialog.show(this.getGameDataText("DIALOG_LOAD_FAILED_STARTUP"));
					::wait(120);
				}

				dialog.hide();
				break;
			}
		}
	}

	function getCurrentPlayTime()
	{
		return ::System.getSystemSecond() - this.playStartTime;
	}

	function getPlayTime()
	{
		return this.playTime + this.getCurrentPlayTime();
	}

	function getLastSave()
	{
		if (this.titleData != null && "lastSave" in this.titleData)
		{
			local last = this.titleData.lastSave;
			last = last == 0 ? null : last - 1;
			this.printf("getlast:%s\n", last);
			return last;
		}
	}

	function gameSaveLoadPrepare( nodata = 0 )
	{
		if (this.gbackup != null && this.spec == "psp")
		{
			local dialog = ::ConfirmDialog(this.getBaseScreen());
			dialog.show(this.getGameDataText("DIALOG_READING"));
			local ret = this.doLoadSegment(this.gbackup, function ( segment ) : ( nodata )
			{
				if (this.spec == "psp")
				{
					switch(nodata)
					{
					case 1:
						if (segment.noData)
						{
							this.gstruct.clear();
							return true;
						}

						break;

					case 2:
						if (segment.noData || (segment.broken || segment.noFile) && this.confirm(this.getSegmentText("YESNO_OVERWRITE_DATA", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
						{
							this.gstruct.clear();
							return true;
						}

						break;

					default:
						break;
					}
				}
			});

			if (!ret)
			{
				this.gstruct.clear();
				dialog.show(this.getGameDataText("DIALOG_READ_FAILED"));
				::wait(60);
			}

			dialog.hide();
			return ret;
		}

		return true;
	}

	function getFileCount( saveMode = true, type = 7, filter = true )
	{
		return this.getFileList(saveMode, type, filter);
	}

	function getFileList( saveMode = true, type = 7, filter = true, list = null )
	{
		local num = 0;
		local info;
		local addfunc;

		if (list != null)
		{
			addfunc = function ( info, index, type ) : ( list )
			{
				list.append(this.buildFileInfo(info, index, type));
			};
		}

		if (type & 1)
		{
			for( local i = 0; i < this.dataCount; i++ )
			{
				info = this.doLoad(i, true);

				if (info || !filter || saveMode)
				{
					if (addfunc != null)
					{
						addfunc(info, i, 0);
					}

					num++;
				}
			}
		}

		if (!saveMode)
		{
			if (type & 4)
			{
				info = this.doQuickLoad();

				if (info || !filter)
				{
					if (addfunc != null)
					{
						addfunc(info, -1, 3);
					}

					num++;
				}
			}

			if (type & 2)
			{
				for( local i = 0; i < this.autoDataCount; i++ )
				{
					info = this.doAutoLoad(i, true);

					if (info || !filter)
					{
						if (addfunc != null)
						{
							addfunc(info, i, 1);
						}

						num++;
					}
				}
			}
		}

		if (type & 8)
		{
			for( local i = 0; i < this.crossDataCount; i++ )
			{
				info = this.doCrossLoad(i, true);

				if (info || !filter)
				{
					if (addfunc != null)
					{
						addfunc(info, i, 2);
					}

					num++;
				}
			}
		}

		return num;
	}

	function getFilePage( type, pageNo )
	{
		local list = [];
		local base = pageNo * this.pageSize;

		for( local i = 0; i < this.pageSize; i++ )
		{
			local index = base + i;
			local info;

			switch(type)
			{
			case 0:
				info = this.doLoad(index, true);
				break;

			case 1:
				info = this.doAutoLoad(index, true);
				break;

			case 2:
				info = this.doCrossLoad(index, true);
				break;

			case 3:
				if (index == 0)
				{
					info = this.doQuickLoad();
				}

				break;
			}

			list.append(this.buildFileInfo(info, index, type));
		}

		return list;
	}

	function gameSave( fileInfo, data, capture, ask = false )
	{
		local askOver = fileInfo.info != null;
		local cross = fileInfo.type == 3;

		if (!ask || this.confirm(this.getGameDataText("YESNO_SAVE")))
		{
			if (askOver && !this.confirm(this.getGameDataText("YESNO_SAVE_OVER"), "no"))
			{
				return;
			}

			local index = fileInfo.index;
			local type = fileInfo.type;
			local dialog;

			if (this.spec != "x360")
			{
				dialog = ::ConfirmDialog(this.getBaseScreen());
				dialog.show(this.getGameDataText("DIALOG_SAVING"));
			}

			local newInfo;

			switch(type)
			{
			case 0:
				newInfo = this.doSave(index, data, capture);

				if (newInfo != null)
				{
					this.setLastSave(index);
				}

				break;

			case 1:
				newInfo = this.doAutoSave(index, data, capture);
				break;

			case 2:
				newInfo = this.doCrossSave(index, data, capture);
				break;

			case 3:
				newInfo = this.doQuickSave(data, capture);
				break;
			}

			if (newInfo == null)
			{
				if (dialog)
				{
					dialog.inform(this.getGameDataText("DIALOG_SAVE_FAILED"));
				}

				newInfo = false;
			}
			else if (("syssave" in newInfo) && !newInfo.syssave)
			{
				if (dialog)
				{
					dialog.inform(this.getSystemDataText("DIALOG_SAVE_FAILED"));
				}
			}

			return newInfo;
		}
	}

	function gameLoad( fileInfo )
	{
		local index = fileInfo.index;
		local type = fileInfo.type;
		local dialog;

		if (!(this.PACKMODE != 0 || type == 3 || this.spec == "x360"))
		{
			dialog = ::ConfirmDialog(this.getBaseScreen());
			dialog.show(this.getGameDataText("DIALOG_LOADING"));
		}

		local newInfo;

		switch(type)
		{
		case 0:
			newInfo = this.doLoad(index);
			break;

		case 1:
			newInfo = this.doAutoLoad(index);
			break;

		case 2:
			newInfo = this.doCrossLoad(index);
			break;

		case 3:
			newInfo = this.doQuickLoad();
			break;
		}

		if (dialog)
		{
			if (newInfo == null)
			{
				dialog.inform(this.getGameDataText(newInfo != null ? "DIALOG_LOAD_DONE" : "DIALOG_LOAD_FAILED"));
			}
		}

		return newInfo;
	}

	function sysSave( ask = false )
	{
		if (this.checkStorage() && (!ask || this.confirm(this.getSystemDataText("YESNO_SAVE"))))
		{
			local cont = true;
			local success;

			while (cont)
			{
				local dialog = this.spec != "x360" ? ::ConfirmDialog(this.getBaseScreen()) : null;

				if (dialog != null)
				{
					dialog.show(this.getSystemDataText("DIALOG_SAVING"));
				}

				success = this.doSystemSave(false);

				if (!success && dialog)
				{
					if (1)
					{
						cont = dialog.confirm(this.getSystemDataText("DIALOG_SAVE_FAILED_RETRY"));
					}
					else
					{
						dialog.inform(this.getSystemDataText("DIALOG_SAVE_FAILED"));
						cont = false;
					}
				}
				else
				{
					cont = false;
				}
			}

			return success;
		}
	}

	function askLoad()
	{
		return this.confirm(this.getGameDataText("YESNO_LOAD"), "no");
	}

	function uploadCross( dialog = null )
	{
		if (this.tusStruct != null)
		{
			local slot = 1 + this.title;
			this.print("TUS Struct copy.\n");
			local data = "crossdata" in this.tusStruct.root ? this.tusStruct.root.crossdata : "data" in this.tusStruct.root ? this.tusStruct.root.data : null;

			if (data != null)
			{
				local count = ::min(data.len(), this.crossDataCount);
				local crossdata;

				if (this.PACKMODE == 0)
				{
					local backupData = ::loadData("config/backup.psb");
					local loadqueue = [];
					local no = this.dataCount + this.autoDataCount;

					for( local i = 0; i < count; i++ )
					{
						local dat = this.gstruct.root.data[no + i];

						if (this.isSaveDataEnable(dat))
						{
							local struct = ::Struct(backupData, this.format("gamedata%d", this.title));
							local value = {
								i = i,
								segmentId = this.dbackup.segmentId,
								fileId = no + i,
								struct = struct
							};
							loadqueue.append(value);
						}
					}

					if (this.doLoadSegment(loadqueue))
					{
						crossdata = [];
						crossdata.resize(count);

						foreach( info in loadqueue )
						{
							local ret = this.isSaveDataEnable(info.struct.root) ? info.struct.root : null;
							crossdata[info.i] = ret;
							this.printf("\x00e3\x0082\x00a2\x00e3\x0083\x0083\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e7\x0094\x00a8\x00e3\x0081\x00ae\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf:%s:%s\n", info.i, ret);
						}

						loadqueue.clear();
					}
					else
					{
						this.printf("\x00e3\x0082\x00af\x00e3\x0083\x00ad\x00e3\x0082\x00b9\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0083\x0096\x00e7\x0094\x00a8\x00e3\x0081\x00ae\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e5\x0087\x00a6\x00e7\x0090\x0086\x00e5\x00a4\x00b1\x00e6\x0095\x0097\n");
					}
				}
				else
				{
					crossdata = [];

					for( local i = 0; i < count; i++ )
					{
						local ret = this.doCrossLoad(i);
						this.printf("\x00e3\x0082\x00a2\x00e3\x0083\x0083\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e7\x0094\x00a8\x00e3\x0081\x00ae\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf:%s:%s\n", i, ret);
						crossdata.append(ret);
					}
				}

				for( local i = 0; i < count; i++ )
				{
					local src = crossdata != null ? crossdata[i] : null;
					local dest = data[i];

					if (src == null)
					{
						dest.clear();
					}
					else
					{
						this.copy2(src, dest);

						if (dest.historyCount > dest.history.len())
						{
							dest.historyCount = dest.history.len();
						}
					}
				}
			}

			if (this.rdscene && "rdscene" in this.tusStruct.root)
			{
				this.copy2(this.rdscene, this.tusStruct.root.rdscene);
			}

			if (this.rdfile && "rdfile" in this.tusStruct.root)
			{
				this.copy2(this.rdfile, this.tusStruct.root.rdfile);
			}

			if (this.tsysflag && "sysflag" in this.tusStruct.root)
			{
				this.copy2(this.tsysflag, this.tusStruct.root.sysflag);
			}

			local ret;
			local loginCheck = false;

			if (this.tus == null)
			{
				ret = true;
			}
			else
			{
				loginCheck = true;
				ret = this.tus.checkLogin();

				if (ret == true)
				{
					loginCheck = false;
					ret = this.tus.doSave(this.tusStruct, slot);
				}
			}

			if (ret != true)
			{
				if (dialog != null)
				{
					dialog.hide();
				}

				if (typeof ret == "integer")
				{
					if (ret == -1)
					{
						this.inform("DIALOG_TUS_LOGIN_FAIL");
					}
					else if (ret == -2)
					{
						this.inform("DIALOG_TUS_LOGIN_FAIL_AGE");
					}
					else if (ret == -3)
					{
						this.inform("DIALOG_TUS_UPLOAD_FAILED_SIGNOUT");
					}
					else if (this.spec == "vita")
					{
						if (ret == 2153056027)
						{
							this.print("SCE_NP_COMMUNITY_ERROR_TUS_INVALID_SAVEDATA_OWNER\n");
							this.inform("DIALOG_TUS_UPLOAD_INVALID_SAVEDATA_OWNER");
						}
						else
						{
							if (!loginCheck)
							{
								local task = this.SystemDialog();
								task.setErrorCode(ret);

								while (task.getRunning())
								{
									this.wait(0);
								}

								task = null;
							}

							if (ret == 2153055499 || ret == 2153055498)
							{
								this.inform("DIALOG_TUS_UPLOAD_FAILED_SIGNOUT");
							}
							else
							{
								this.inform("DIALOG_TUS_UPLOAD_FAILED");
							}
						}
					}
					else
					{
						this.inform({
							text = "DIALOG_TUS_UPLOAD_FAILED_ERRORCODE",
							error = ret
						});
					}
				}
				else
				{
					this.inform("DIALOG_TUS_UPLOAD_FAILED");
				}
			}

			return ret;
		}
	}

	function downloadCross( dialog = null )
	{
		if (this.tusStruct != null)
		{
			local slot = 1 + this.title;
			this.print("TUS Struct copy.\n");
			local ret;
			local loginCheck = false;

			if (this.tus == null)
			{
				ret = true;
			}
			else
			{
				loginCheck = true;
				ret = this.tus.checkLogin();

				if (ret == true)
				{
					loginCheck = false;
					ret = this.tus.doLoad(this.tusStruct, slot);
				}
			}

			if (ret == true)
			{
				local data = "crossdata" in this.tusStruct.root ? this.tusStruct.root.crossdata : "data" in this.tusStruct.root ? this.tusStruct.root.data : null;

				if (data)
				{
					local snap = this.getSnapPlayer();
					local no = this.dataCount + this.autoDataCount;
					local count = ::min(data.len(), this.crossDataCount);
					local savequeue = [];
					local savefiles = [];
					local headimage;
					local pageimage;

					if (this.PACKMODE == 0)
					{
						local backupData = ::loadData("config/backup.psb");
						headimage = this.gstruct.serialize();

						for( local i = 0; i < count; i++ )
						{
							savefiles.append(no + i);
							local store = this.storeSave(this.gstruct.root.data[no + i], data[i], snap, this.CROSSLOAD_THUMBNAIL_UPDATE);
							local struct = ::Struct(backupData, this.format("gamedata%d", this.title));
							this.storeSave(struct.root, data[i]);
							savequeue.append({
								i = i,
								segmentId = this.dbackup.segmentId,
								fileId = no + i,
								struct = struct
							});
						}

						savequeue.append({
							segmentId = this.gbackup.segmentId
						});
					}
					else if (this.PACKMODE == 1)
					{
						local currentPage = 0;

						for( local i = 0; i < count; i++ )
						{
							local n = no + i;
							local page = n / this.pageSize;

							if (i == 0)
							{
								currentPage = page;
								this.setPage(page);
								pageimage = this.dstruct.serialize();
							}
							else if (page != currentPage)
							{
								this.printf("\x00e3\x0083\x009a\x00e3\x0083\x00bc\x00e3\x0082\x00b8\x00e5\x008d\x0098\x00e4\x00bd\x008d\x00e4\x00bf\x009d\x00e5\x00ad\x0098\x00e3\x0081\x00a7\x00e3\x0081\x00af\x00e5\x00a2\x0083\x00e7\x0095\x008c\x00e3\x0082\x0092\x00e8\x00b6\x008a\x00e3\x0081\x0088\x00e3\x0082\x0089\x00e3\x0082\x008c\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093");
								break;
							}

							n = n % this.pageSize;
							this.storeSave(this.dstruct.root.data[n], data[i], snap, this.CROSSLOAD_THUMBNAIL_UPDATE);
						}

						savequeue.append({
							segmentId = this.dbackup.segmentId
						});
					}
					else if (this.PACKMODE == 2)
					{
						for( local i = 0; i < count; i++ )
						{
							this.storeSave(this.gstruct.root.data[no + i], data[i], snap, this.CROSSLOAD_THUMBNAIL_UPDATE);
						}

						savequeue.append({
							segmentId = this.gbackup.segmentId
						});
					}

					if (this.rdscene && "rdscene" in this.tusStruct.root)
					{
						local rd = this.tusStruct.root.rdscene;
						local rmax = rd.len();

						if (rmax > this.rdsceneMax)
						{
							rmax = this.rdsceneMax;
						}

						for( local i = 0; i < rmax; i++ )
						{
							local s = rd[i];
							local d = this.rdscene[i];

							if (s.text > d.text)
							{
								d.text = s.text;
							}

							if (s.select != 0)
							{
								d.select = d.select | s.select;
							}
						}
					}

					if (this.rdfile && "rdfile" in this.tusStruct.root)
					{
						local rd = this.tusStruct.root.rdfile;
						local rmax = rd.len();

						if (rmax > this.rdfileMax)
						{
							rmax = this.rdfileMax;
						}

						for( local i = 0; i < rmax; i++ )
						{
							if (rd[i] && !this.rdfile[i])
							{
								this.rdfile[i] = true;
							}
						}
					}

					if (this.tsysflag && "sysflag" in this.tusStruct.root)
					{
						foreach( name, value in this.tusStruct.root.sysflag )
						{
							if (typeof value == "bool" && value)
							{
								if ((name in this.tsysflag) && typeof this.tsysflag[name] == "bool")
								{
									this.tsysflag[name] = true;
								}
							}
						}
					}

					savequeue.append({
						segmentId = this.systemBackup.segmentId
					});

					if (!this.doSaveSegment(savequeue))
					{
						foreach( file in savefiles )
						{
							this.gstruct.root.data[file].clear();
						}

						if (!headimage)
						{
							this.gstruct.unserialize(headimage);
						}

						if (!pageimage)
						{
							this.dstruct.unserialize(pageimage);
						}

						if (dialog)
						{
							dialog.inform(this.getGameDataText("DIALOG_SAVE_FAILED"));
						}
					}

					snap = null;
				}
			}
			else
			{
				if (dialog != null)
				{
					dialog.hide();
				}

				if (typeof ret == "integer")
				{
					if (ret == -1)
					{
						this.inform("DIALOG_TUS_LOGIN_FAIL");
					}
					else if (ret == -2)
					{
						this.inform("DIALOG_TUS_LOGIN_FAIL_AGE");
					}
					else if (ret == -3)
					{
						this.inform("DIALOG_TUS_DOWNLOAD_FAILED_SIGNOUT");
					}
					else if (this.spec == "vita")
					{
						if (ret == 2153056027)
						{
							this.print("SCE_NP_COMMUNITY_ERROR_TUS_INVALID_SAVEDATA_OWNER\n");
							this.inform("DIALOG_TUS_DOWNLOAD_INVALID_SAVEDATA_OWNER");
						}
						else if (ret == 2153056330)
						{
							this.print("TUS data is not exist.\n");
							this.inform("DIALOG_TUS_DOWNLOAD_FAILED_NODATA");
						}
						else
						{
							if (!loginCheck)
							{
								local task = this.SystemDialog();
								task.setErrorCode(ret);

								while (task.getRunning())
								{
									this.wait(0);
								}

								task = null;
							}

							if (ret == 2153055499 || ret == 2153055498)
							{
								this.inform("DIALOG_TUS_DOWNLOAD_FAILED_SIGNOUT");
							}
							else
							{
								this.inform("DIALOG_TUS_DOWNLOAD_FAILED");
							}
						}
					}
					else if (ret == 2147656778)
					{
						this.print("TUS data is not exist.\n");
						this.inform("DIALOG_TUS_DOWNLOAD_FAILED_NODATA");
					}
					else
					{
						this.inform({
							text = "DIALOG_TUS_DOWNLOAD_FAILED_ERRORCODE",
							error = ret
						});
					}
				}
				else
				{
					this.inform("DIALOG_TUS_DOWNLOAD_FAILED");
				}
			}

			return ret;
		}
	}

	function setPresence( pr )
	{
		if (this.spec == "x360" && this.manager.checkSignin())
		{
			this.printf("call setPresence:%s\n", pr);

			if (this.medal_system)
			{
				this.medal_system.setPresence(pr);
			}
		}
	}

	function giveMedal( name )
	{
		this.setSystemFlag(name, true);
	}

	function setAward( name )
	{
		if (this.medal_system)
		{
			this.medal_system.setAward(name);
		}
	}

	function isWaitCache( dataCache )
	{
		foreach( cache in dataCache )
		{
			if (cache.loading)
			{
				return true;
			}
		}
	}

	function addCache( dataCache, list )
	{
		foreach( src in list )
		{
			local rsc = ::Resource();
			rsc.load(src);

			while (rsc.loading)
			{
				this.suspend();
			}

			dataCache.append(rsc);
		}
	}

	function addCacheRaw( dataCache, list )
	{
		foreach( src in list )
		{
			local rsc = ::Resource();
			rsc.loadRaw(src);

			while (rsc.loading)
			{
				this.suspend();
			}

			dataCache.append(rsc);
		}
	}

	function install()
	{
		if (this.installer == null)
		{
			return;
		}

		this.inform("DIALOG_INSTALL_DESCRIPTION");

		if (this.spec == "psp")
		{
			this.installer.installCheck();

			while (this.installer.running)
			{
				this.wait();
			}

			if (this.installer.installed)
			{
				if (!this.confirm("YESNO_INSTALL_OVERWRITE"))
				{
					  // [028]  OP_JMP            0     73    0    0
				}
			}

			if (this.installer.installedEnabled)
			{
				this.installer.installedEnabled = false;
				this.setConfig("install", 0);
				this.inform("DIALOG_INSTALLED_ONCE_DISABLED");
			}

			local success = false;
			this.installer.install();

			while (this.installer.running)
			{
				this.wait();
			}

			if (this.installer.success)
			{
				success = true;
			}
			else if (this.installer.aborted)
			{
				this.inform("DIALOG_INSTALL_RETRY");
				  // [065]  OP_JMP            0     20    0    0
			}
			else if (this.installer.nospace)
			{
				this.inform("DIALOG_INSTALL_NOSPACE");
				this.manager.listalldelete();

				while (this.manager.running)
				{
					this.wait();
				}

				  // [082]  OP_JMP            0      3    0    0
			}
			else
			{
				  // [084]  OP_JMP            0      2    0    0
			}

			  // [085]  OP_JMP            0      1    0    0
			  // [086]  OP_JMP            0    -43    0    0

			if (success)
			{
				this.inform("DIALOG_INSTALLED_ENABLED");
				this.installer.installedEnabled = true;
				this.setConfig("install", 1);
				this.sysSave();
			}
		}
		else
		{
		}
	}

	function _onConfigUpdate( name = null )
	{
		if (name == null || name == "volume")
		{
			::Sound.setMasterVolume(this.getConfig("volume", 1.0));
		}

		if (name == null || name == "bgmVolume")
		{
			::setBgmVolume(this.getConfig("bgmVolume", 1.0));
		}

		if (name == null || name == "seVolume")
		{
			::Sound.setGroupVolume("se", this.getConfig("seVolume", 1.0));
		}

		if (name == null || name == "voiceVolume")
		{
			::Sound.setGroupVolume("voice", this.getConfig("voiceVolume", 1.0));
		}

		if (name == null || name == "loopVolume")
		{
			::Sound.setGroupVolume("loop", this.getConfig("loopVolume", 1.0));
		}

		if (name == null || name == "bgmVolume")
		{
			::Sound.setGroupVolume("movie", this.getConfig("bgmVolume", 1.0));
		}

		if (name == null || name == "sysseVolume")
		{
			::Sound.setGroupVolume("sysse", this.getConfig("sysseVolume", 1.0));
		}

		if (name == null || name == "sysvoVolume")
		{
			::Sound.setGroupVolume("sysvo", this.getConfig("sysvoVolume", 1.0));
		}

		if (this.spec == "psp" && this.installer != null)
		{
			if (name == null || name == "install")
			{
				local prevEnabled = this.installer.installedEnabled;
				this.installer.installedEnabled = this.systemStruct.root.config[this.INSTALL_CONFIG_NAME] == 1;

				if (!prevEnabled && this.installer.installedEnabled)
				{
					::loadData("config/dummy.psb");
					this.sync();
				}
			}
		}

		if (name == null || name == "screenSize")
		{
			if (::baseScreen != null)
			{
				local screenSize = this.getConfig("screenSize", 1.0);

				if (screenSize < 0.60000002)
				{
					screenSize = 0.60000002;
				}

				::baseScreen.setZoom(screenSize);
			}
		}
	}

	function isGameBackup( segment )
	{
		if (this.gameBackup != null)
		{
			foreach( backup in this.gameBackup )
			{
				if (segment == backup)
				{
					return true;
				}
			}
		}

		return false;
	}

	function doLoadSegment( segment, errorfunc = null )
	{
		if (!this.checkStorage())
		{
			return false;
		}

		local param;

		if (typeof segment == "array")
		{
			param = segment;
			this.manager.dialogName = this.manager.getSegment(segment[0].segmentId).dialogName;
			segment = this.manager;
		}

		switch(this.spec)
		{
		case "x360":
			segment.autoload(param);

			while (segment.running)
			{
				this.wait();
			}

			if (!segment.success && segment.broken)
			{
				this.inform(this.getSegmentText("BROKEN_SAVE_DATA_GAME", segment));

				if (this.isGameBackup(segment))
				{
					this.gameBackupBroken = true;
				}
			}

			return segment.success;

		case "ps3":
			while (true)
			{
				segment.autoload(param);

				while (segment.running)
				{
					this.wait();
				}

				if (!segment.success && segment.broken)
				{
					if (true == this.confirm(this.getSegmentText(segment == this.systemBackup ? "YESNO_LOAD_RETRY" : "YESNO_READ_RETRY", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
					{
						continue;
					}
				}

				return segment.success;
			}

		case "vita":
		case "ps4":
			segment.autoload(param);

			while (segment.running)
			{
				this.wait();
			}

			if (!segment.success && segment.broken)
			{
				this.inform(this.getSegmentText(segment == this.systemBackup ? "DIALOG_LOAD_FAILED" : "DIALOG_READ_FAILED", segment), null, 35 + 1);
			}

			return segment.success;

		case "psp":
			segment.autoload(param);

			while (segment.running)
			{
				this.wait();
			}

			if (!segment.success)
			{
				if (errorfunc != null)
				{
					local ret = errorfunc(segment);

					if (ret != null)
					{
						return ret;
					}
				}

				if (this.confirm(this.getSegmentText(segment == this.systemBackup ? "YESNO_LOAD_RETRY" : "YESNO_READ_RETRY", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
				{
					  // [182]  OP_JMP            0      2    0    0
				}
			}

			return segment.success;
			  // [185]  OP_JMP            0    -44    0    0
		}

		segment.autoload(param);

		while (segment.running)
		{
			this.wait();
		}

		return segment.success;
	}

	function doSaveSegment( segment )
	{
		if (!this.checkStorage())
		{
			return false;
		}

		local param;

		if (typeof segment == "array")
		{
			param = segment;
			this.manager.dialogName = this.manager.getSegment(segment[0].segmentId).dialogName;
			segment = this.manager;
		}

		switch(this.spec)
		{
		case "x360":
			if (this.isGameBackup(segment) && this.gameBackupBroken)
			{
				if (!this.confirm(this.getSegmentText("YESNO_OVERWRITE_SAVEDATA_WHEN_BROKEN", segment)))
				{
					return false;
				}

				this.gameBackupBroken = false;
			}

			while (true)
			{
				segment.autosave(param);

				while (segment.running)
				{
					this.wait();
				}

				if (!segment.success && segment.nospace)
				{
					this.inform(this.getSegmentText("NOSPACE_STORAGE", segment));

					if (!this.confirm(this.getSegmentText("YESNO_RESELECT_ALTERNATIVE_STORAGE", segment)))
					{
						return segment.success;
					}

					this.gameBackupBroken = false;

					while (true)
					{
						this.manager.clearStorageReselected();
						this.manager.selectStorage();

						while (this.manager.running)
						{
							this.wait();
						}

						if (this.manager.isStorageReselected())
						{
							break;
						}

						if (!this.confirm("YESNO_NO_STORAGE_DEVICE"))
						{
							return segment.success;
						}
					}

					if (this.isGameBackup(segment))
					{
						if (!this.doSystemSave())
						{
							return segment.success;
						}
					}

					continue;
				}

				return segment.success;
			}

		case "ps3":
			while (true)
			{
				segment.autosave(param);

				while (segment.running)
				{
					this.wait();
				}

				if (!segment.success && segment.nospace)
				{
					if (!this.confirm(this.getSegmentText("YESNO_LISTDELETE_NOSPACE", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
					{
						return segment.success;
					}

					this.manager.listalldelete();

					while (this.manager.running)
					{
						this.wait();
					}

					continue;
				}

				if (!segment.success && segment.broken)
				{
					if (!this.confirm(this.getSegmentText("YESNO_SAVEBROKEN_RETRY", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
					{
						return segment.success;
					}

					segment.singledelete();

					while (segment.running)
					{
						this.wait();
					}

					continue;
				}

				return segment.success;
			}

		case "psp":
			segment.autoSaveNoSpaceErrorMessage = this.getSystemText(this.getSegmentText("DIALOG_AUTOSAVE_NOSPACE", segment));
			segment.autosave(param);

			while (segment.running)
			{
				this.wait();
			}

			if (!segment.success && segment.nospace)
			{
				if (!this.confirm(this.getSegmentText("YESNO_LISTDELETE_NOSPACE", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
				{
					return segment.success;
				}

				this.manager.listalldelete();

				while (this.manager.running)
				{
					this.wait();
				}
			}
			else
			{
				if (!segment.success)
				{
					if (this.confirm(this.getSegmentText("YESNO_SAVE_RETRY", segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
					{
						  // [267]  OP_JMP            0      2    0    0
					}
				}

				return segment.success;
			}

			  // [270]  OP_JMP            0    -60    0    0
		}

		segment.autosave(param);

		while (segment.running)
		{
			this.wait();
		}

		if (!segment.success && segment.nospace)
		{
			this.inform(this.getSegmentText("NOSPACE_STORAGE", segment));
		}

		return segment.success;
	}

	function startup( callback = null )
	{
		if (this.spec == "x360")
		{
			this.inform("%CXbox \x00e3\x0083\x0080\x00e3\x0083\x0083\x00e3\x0082\x00b7\x00e3\x0083\x00a5\x00e3\x0083\x009c\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e3\x0081\x00ab\x00e6\x0088\x00bb\x00e3\x0082\x008b\x00e3\x0081\x00a8\nQUICK SAVE\x00e3\x0081\x00ae\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf\x00e3\x0081\x00af\n\x00e6\x00b6\x0088\x00e5\x008e\x00bb\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00be\x00e3\x0081\x0099\x00e3\x0080\x0082");
		}
		else
		{
			this.initMedal();
			local dialog = ::ConfirmDialog(this.getBaseScreen());

			if (this.spec == "psp")
			{
				dialog.show("DIALOG_AUTOSAVE_WARNING1");
				::wait(60 * 1);
				dialog.show("DIALOG_AUTOSAVE_WARNING2");
				::wait(60 * 3);
			}

			dialog.show(this.getSystemDataText("DIALOG_LOADING"));

			if (!this.doSystemLoad(dialog))
			{
				this.initConfig();

				if (1)
				{
					if (!this.systemBackup.broken || dialog.confirm(this.getSystemDataText("YESNO_OVERWRITE_DATA")))
					{
						for( local cont = true; cont;  )
						{
							dialog.show(this.getSystemDataText("DIALOG_SAVING"));
							local success = this.doSystemSave(false);

							if (!success)
							{
								if (1)
								{
									cont = dialog.confirm(this.getSystemDataText("DIALOG_SAVE_FAILED_RETRY"));
								}
								else
								{
									dialog.inform(this.getSystemDataText("DIALOG_SAVE_FAILED"));
									cont = false;
								}
							}
							else
							{
								cont = false;
							}
						}
					}
				}
				else
				{
					dialog.inform(this.getSystemDataText("DIALOG_LOAD_FAILED_STARTUP"));
				}
			}

			if (callback != null)
			{
				callback(dialog);
			}

			dialog.hide();
		}
	}

	function signout()
	{
		if (this.spec == "x360")
		{
			this.softReset();

			if (this.PRESENCE_INIT != null)
			{
				this.setPresence(this.PRESENCE_INIT);
			}
		}
	}

	function signin( no = 0 )
	{
		if (this.spec == "x360")
		{
			this.printf("do signin:%d\n", no);
			this.initMedal();
			this.manager.initialSystem(no, 0, 0, 0, 1, 1);

			while (this.manager.running)
			{
				this.wait();
			}

			this.hasStorage = this.checkPhysicalStorage();

			if (this.hasStorage)
			{
				if (this.gbackup != null)
				{
					if (!this.doLoadSegment(this.gbackup))
					{
						this.gstruct.clear();
					}

					local dialog = ::ConfirmDialog(this.getBaseScreen());
					dialog.show("DIALOG_AUTOSAVE_WARNING1");
					::wait(60 * 1);
					dialog.show("DIALOG_AUTOSAVE_WARNING3");
					::wait(60 * 2);
				}

				if (1)
				{
					::initDLC();
				}
			}
			else
			{
				this.resetConfig();
			}

			this.onConfigUpdate();

			if (this.PRESENCE_INIT != null)
			{
				this.setPresence(this.PRESENCE_INIT);
			}
		}
	}

	function checkStorage()
	{
		if (this.spec == "x360")
		{
			return this.hasStorage;
		}
		else
		{
			return true;
		}
	}

	function checkPhysicalStorage()
	{
		if (this.spec == "x360")
		{
			return this.manager.checkStorage();
		}
		else
		{
			return true;
		}
	}

	function getSegmentResult( segment )
	{
		if (this.spec == "psp")
		{
			if (segment.noMs)
			{
				return this._getSystemText("ERROR_NOMEDIA");
			}
			else if (segment.ejectMs)
			{
				return this._getSystemText("ERROR_EJECT");
			}
			else if (segment.broken || segment.noFile)
			{
				return this._getSystemText("ERROR_BROKEN");
			}
			else if (segment.accessError)
			{
				return this._getSystemText("ERROR_ACCESS");
			}
			else if (segment.noData)
			{
				return this._getSystemText("ERROR_NODATA");
			}
			else if (segment.protected)
			{
				return this._getSystemText("ERROR_PROTECTED");
			}
		}
		else
		{
			if (segment.broken)
			{
				return this._getSystemText("ERROR_BROKEN");
			}

			  // [054]  OP_JMP            0      0    0    0
		}

		return "";
	}

	function getSegmentText( id, segment )
	{
		local ret = {
			text = id,
			result = this.getSegmentResult(segment),
			dialog = segment.dialogName
		};

		if ("getNeedSpace" in segment)
		{
			ret.needspace <- segment.getNeedSpace();
		}

		return ret;
	}

	function getGameDataText( id )
	{
		local backup = this.gbackup != null ? this.gbackup : this.dbackup;
		return this.getSegmentText(id, backup);
	}

	function getSystemDataText( id )
	{
		return this.getSegmentText(id, this.systemBackup);
	}

	function checkDialogText()
	{
		if (::textTable != null)
		{
			foreach( name, value in this.textTable.root )
			{
				this.printf("dialogcheck:%s\n", name);
				local func = name.substr(0, 5) == "YESNO" ? ::confirm : ::inform;
				local text = this.getSystemDataText(value);
				local text2 = this.getGameDataText(value);
				func(text);

				if (this.getSystemText(text) != this.getSystemText(text2))
				{
					func(text2);
				}
			}
		}
	}

	function getSystemFlagInfoList()
	{
		local ret = [];

		foreach( n, v in this.sysflag )
		{
			ret.append({
				name = n,
				type = typeof v
			});
		}

		if (this.tsysflag)
		{
			foreach( n, v in this.tsysflag )
			{
				ret.append({
					name = n,
					type = typeof v
				});
			}
		}

		return ret;
	}

	function _initSystemFlag( sysflag )
	{
		if (sysflag != null)
		{
			foreach( name, value in sysflag )
			{
				switch(typeof value)
				{
				case "integer":
					sysflag[name] = 0;
					break;

				case "float":
					sysflag[name] = 0.0;
					break;

				case "string":
					sysflag[name] = "";
					break;

				case "bool":
					sysflag[name] = false;
					break;
				}
			}
		}
	}

	function initSystemFlag()
	{
		this._initSystemFlag(this.tsysflag);
		this._initSystemFlag(this.sysflag);
	}

	function _setConfig( name, value )
	{
		if (name == "install")
		{
			name = this.INSTALL_CONFIG_NAME;
		}

		try
		{
			if (typeof this.config[name] == "bool" && typeof value != "bool")
			{
				this.config[name] = value.tointeger() != 0;
			}
			else
			{
				this.config[name] = value;
			}
		}
		catch( e )
		{
			this.printf("no such config name:%s\n", name);
		}
	}

	function resetConfig()
	{
		this.hasStorage = false;
		this.qsave = [];
		this.systemStruct.clear();
		this.gstruct.clear();
		this.gameBackupBroken = false;
		this.initConfig();
	}

	function doSystemSave( notify = true )
	{
		if (!this.checkStorage())
		{
			return false;
		}

		this.storePlayTime();

		if (notify)
		{
			this.onStartSave(4);
		}

		local result = this.doSaveSegment(this.systemBackup);

		if (notify)
		{
			this.onEndSave(4);
		}

		this.printf("system save done:%s\n", result);
		return result;
	}

	function doSystemLoad( dialog, check = true, update = true )
	{
		if (!this.checkStorage())
		{
			return false;
		}

		local result = this.doLoadSegment(this.systemBackup, function ( segment ) : ( check )
		{
			if (check)
			{
				if (this.spec == "psp")
				{
					local text;

					if (segment.noData)
					{
						text = "YESNO_CREATE_DATA";
					}
					else if (segment.broken || segment.noFile)
					{
						text = "YESNO_OVERWRITE_DATA";
					}

					if (text != null && this.confirm(this.getSegmentText(text, segment), 0, null, 35 + 1, this.DIALOG_SHIFT))
					{
						this.initConfig();
						this.sysSave();
						return true;
					}
				}
			}
			else
			{
				return false;
			}
		});

		if (result && update)
		{
			this.onConfigUpdate();
			this.restorePlayTime();
		}

		return result;
	}

	function doSystemDelete()
	{
		if (!this.checkStorage())
		{
			return false;
		}

		this.systemBackup.autodelete();

		while (this.systemBackup.running)
		{
			this.wait();
		}

		return this.systemBackup.success;
	}

	function storeStruct( target, value, path = "" )
	{
		foreach( n, v in value )
		{
			if (typeof v == "table" || typeof v == "array")
			{
				if (typeof target == "array")
				{
					this.storeStruct(target[n], v, path + "/" + n);
				}
				else if (n in target)
				{
					this.storeStruct(target[n], v, path + "/" + n);
				}
			}
			else
			{
				try
				{
					if (n in target)
					{
						target[n] = v;
					}
				}
				catch( e )
				{
					this.printf("storeStruct failed:%s/%s:%s\n", path, n, v);
					this.sync();
				}
			}
		}
	}

	function storeSave( store, data, capture = null, update = null )
	{
		store.clear();
		this.storeStruct(store, data);

		if ("thumbnail" in store)
		{
			if (store.thumbnail.len() < this.THUMBNAIL_WIDTH * this.THUMBNAIL_HEIGHT * 3)
			{
				this.printf("warning:invalid thumbnail size %d*%d*3/%d", this.THUMBNAIL_WIDTH, this.THUMBNAIL_HEIGHT, store.thumbnail.len());
			}
			else if (capture instanceof ::Capture)
			{
				local thumb = ::RawImage(this.THUMBNAIL_WIDTH, this.THUMBNAIL_HEIGHT);
				capture.storeThumbnail(thumb, 2);
				thumb.store(store.thumbnail);
			}
			else if (capture instanceof this.EnvPlayerBase)
			{
				if (this.isSaveDataEnable(data))
				{
					capture.snap({
						width = this.THUMBNAIL_WIDTH,
						height = this.THUMBNAIL_HEIGHT,
						data = store.thumbnail
					}, data.storage + data.target, data.point, update);
				}
			}
		}
	}

	function getDataBase()
	{
		switch(this.PACKMODE)
		{
		case 0:
			return this.dstruct.root;

		case 1:
			return this.dstruct.root.data[0];

		case 2:
			return this.gstruct.root.data[0];
		}
	}

	function getFlagInfoList()
	{
		local ret = [];
		local flags = this.getDataBase().flags;

		foreach( n, v in flags )
		{
			ret.append({
				name = n,
				type = typeof v
			});
		}

		return ret;
	}

	function setPage( page )
	{
		if (this.PACKMODE == 1 && page != this.currentPage)
		{
			this.currentPage = page;
			this.dbackup.setFileId(page);

			if (!this.doLoadSegment(this.dbackup))
			{
				this.dstruct.clear();
				this.pageError = true;
			}
			else
			{
				this.pageError = false;
			}
		}
	}

	function clearPage()
	{
		if (this.pageError)
		{
			this.currentPage = null;
		}
	}

	function testSaveAll()
	{
		local savequeue = [];

		if (this.dbackup != null)
		{
			for( local i = 0; i < this.dataSegCount; i++ )
			{
				savequeue.append({
					segmentId = this.dbackup.segmentId,
					fileId = i
				});
			}
		}

		if (this.gbackup != null)
		{
			savequeue.append({
				segmentId = this.gbackup.segmentId
			});
		}

		savequeue.append({
			segmentId = this.systemBackup.segmentId
		});
		this.doSaveSegment(savequeue);
	}

	function doSave( no, data, capture = null, notify = true )
	{
		if (notify)
		{
			this.onStartSave(0);
		}

		local ret;

		switch(this.PACKMODE)
		{
		case 0:
			this.storeSave(this.dstruct.root, data, capture);
			this.storeSave(this.gstruct.root.data[no], data, capture);
			ret = this.doSaveSegment([
				{
					segmentId = this.dbackup.segmentId,
					fileId = no
				},
				{
					segmentId = this.gbackup.segmentId
				},
				{
					segmentId = this.systemBackup.segmentId
				}
			]);

			if (ret)
			{
				ret = this.gstruct.root.data[no];
			}
			else if (this.dbackup.success)
			{
				ret = {};

				foreach( key, value in this.gstruct.root.data[no] )
				{
					ret[key] <- value;
				}

				ret.syssave <- false;
			}
			else
			{
				this.gstruct.root.data[no].clear();
				this.dstruct.root.clear();
				ret = null;
			}

			break;

		case 1:
			this.setPage(no / this.pageSize);
			local n = no % this.pageSize;
			this.storeSave(this.dstruct.root.data[n], data, capture);
			ret = this.doSaveSegment([
				{
					segmentId = this.dbackup.segmentId
				},
				{
					segmentId = this.systemBackup.segmentId
				}
			]);

			if (ret)
			{
				ret = this.dstruct.root.data[n];
			}
			else if (this.dbackup.success)
			{
				ret = {};

				foreach( key, value in this.dstruct.root.data[n] )
				{
					ret[key] <- value;
				}

				ret.syssave <- false;
			}
			else
			{
				this.dstruct.root.data[n].clear();
				ret = null;
			}

			break;

		case 2:
			this.storeSave(this.gstruct.root.data[no], data, capture);
			ret = this.doSaveSegment([
				{
					segmentId = this.gbackup.segmentId
				},
				{
					segmentId = this.systemBackup.segmentId
				}
			]);

			if (ret)
			{
				ret = this.gstruct.root.data[no];
			}
			else
			{
				this.gstruct.root.data[no].clear();
				ret = null;
			}

			break;
		}

		if (notify)
		{
			this.onEndSave(0);
		}

		return ret;
	}

	function isSaveDataEnable( info )
	{
		return info != null && (("storage" in info) && info.storage != "" || ("year" in info) && info.year != 0);
	}

	function doLoad( no, header = false )
	{
		if (this.PACKMODE == 1)
		{
			this.setPage(no / this.pageSize);
			no = no % this.pageSize;
		}

		local ret;

		if (header)
		{
			switch(this.PACKMODE)
			{
			case 0:
				ret = this.gstruct.root.data[no];
				break;

			case 1:
				ret = this.dstruct.root.data[no];
				break;

			case 2:
				ret = this.gstruct.root.data[no];
				break;
			}
		}
		else
		{
			switch(this.PACKMODE)
			{
			case 0:
				this.dbackup.setFileId(no);
				local result = this.doLoadSegment(this.dbackup);
				ret = result ? this.convertPSBValue(this.dstruct.root) : null;
				break;

			case 1:
				ret = this.dstruct.root.data[no];
				break;

			case 2:
				ret = this.gstruct.root.data[no];
				break;
			}
		}

		return this.isSaveDataEnable(ret) ? ret : null;
	}

	function setLastSave( no )
	{
		if (this.titleData != null && "lastSave" in this.titleData)
		{
			this.titleData.lastSave = no + 1;
		}
	}

	function doQuickSave( data, capture = null, auto = true, notify = true )
	{
		if ("quickdata" in this.titleData)
		{
			if (notify)
			{
				this.onStartSave(3);
			}

			local ret;

			if (auto)
			{
				local image = this.systemStruct.serialize();
				this.storeSave(this.titleData.quickdata, data, capture);
				ret = this.doSaveSegment(this.systemBackup);

				if (!ret)
				{
					this.systemStruct.unserialize(image);
				}

				ret = ret ? this.titleData.quickdata : null;
			}
			else
			{
				this.storeSave(this.titleData.quickdata, data, capture);
				ret = this.titleData.quickdata;
			}

			if (notify)
			{
				this.onEndSave(3);
			}

			return ret;
		}
	}

	function doQuickLoad()
	{
		local ret;

		if ("quickdata" in this.titleData)
		{
			ret = this.titleData.quickdata;
		}

		return this.isSaveDataEnable(ret) ? ret : null;
	}

	function canAutoSave()
	{
		return this.autoDataCount > 0;
	}

	function doAutoSave( no, data, capture = null, notify = true )
	{
		if (this.canAutoSave())
		{
			if (no == null)
			{
				no = this.titleData.autopoint;

				if (no < 0 || no >= this.autoDataCount)
				{
					no = 0;
				}

				this.titleData.autopoint = (no + 1) % this.autoDataCount;
			}
			else
			{
				local point = this.titleData.autopoint;

				if (point < 0 || point >= this.autoDataCount)
				{
					point = 0;
				}

				no = (point - no - 1 + this.autoDataCount) % this.autoDataCount;
			}

			if (notify)
			{
				this.onStartSave(1);
			}

			local ret = this.doSave(no + this.dataCount, data, capture, false);

			if (notify)
			{
				this.onEndSave(1);
			}

			return ret;
		}

		return null;
	}

	function doAutoLoad( no = 0, header = false )
	{
		if (this.canAutoSave())
		{
			local point = this.titleData.autopoint;

			if (point < 0 || point >= this.autoDataCount)
			{
				point = 0;
			}

			no = (point - no - 1 + this.autoDataCount) % this.autoDataCount;
			local ret = this.doLoad(no + this.dataCount, header);
			return this.isSaveDataEnable(ret) ? ret : null;
		}

		return null;
	}

	function canCrossSave()
	{
		return this.crossDataCount > 0;
	}

	function doCrossSave( no, data, capture = null, notify = true )
	{
		if (this.canCrossSave())
		{
			if (notify)
			{
				this.onStartSave(2);
			}

			local ret = this.doSave(no + this.dataCount + this.autoDataCount, data, capture, false);

			if (notify)
			{
				this.onEndSave(2);
			}

			return ret;
		}

		return null;
	}

	function doCrossLoad( no = 0, header = false )
	{
		if (this.canCrossSave())
		{
			local ret = this.doLoad(no + this.dataCount + this.autoDataCount, header);
			return this.isSaveDataEnable(ret) ? ret : null;
		}

		return null;
	}

	function copy( src, dst )
	{
		foreach( key, value in src )
		{
			this.type = typeof value;

			switch(this.type)
			{
			case "array":
			case "table":
				this.copy(src[key], dst[key]);
				break;

			default:
				dst[key] = value;
				break;
			}
		}
	}

	function copy2( src, dst )
	{
		foreach( key, value in dst )
		{
			local type = typeof value;

			if (key in src)
			{
				value = src[key];

				switch(type)
				{
				case "array":
				case "table":
					this.copy2(src[key], dst[key]);
					break;

				default:
					dst[key] = value;
					break;
				}
			}
		}
	}

	function getSaveDataPageCount( type )
	{
		switch(type)
		{
		case 0:
			return this.pageCount;

		case 1:
			return this.autoPageCount;

		case 2:
			return this.crossPageCount;

		case 3:
			return 1;
		}
	}

	function systemErrorInform( text )
	{
		::NoInterruptConfirmDialog(null, 35 + 3).inform(text);
		::suspend();
	}

	function softReset( state = null )
	{
		this.manager.softReset();
		this.resetConfig();

		switch(state)
		{
		case "softreset_signout":
			this.systemErrorInform("DIALOG_PLAYER_SIGNOUT");
			break;

		case "softreset_eject_storage":
			this.systemErrorInform("DIALOG_EJECT_STORAGE");
			break;
		}
	}

	function checkDiskCapacity()
	{
		if (this.spec == "ps3")
		{
			local dialog = ::ConfirmDialog(this.getBaseScreen());
			dialog.show("DIALOG_CHECK_HDD_SPACE");
			local KB = 1024;
			local MB = 1024 * 1024;
			local requiredSizeKB = 0;
			local savequeue = [];
			savequeue.append({
				segmentId = this.systemBackup.segmentId
			});

			if (this.gameBackup != null)
			{
				foreach( backup in this.gameBackup )
				{
					savequeue.append({
						segmentId = backup.segmentId
					});
				}
			}

			if (this.dataBackup != null)
			{
				foreach( backup in this.dataBackup )
				{
					savequeue.append({
						segmentId = backup.segmentId
					});
				}
			}

			this.manager.needsize(savequeue);

			while (this.manager.running)
			{
				this.wait();
			}

			local needSize = this.manager.needsizeResult;
			local freeSizeKB = needSize.freeSizeKB;
			requiredSizeKB += needSize.needSizeKB;
			this.printf("savedata require %d KB.\n", requiredSizeKB);

			if (this.medal_system)
			{
				this.medal_system.checkRequiredSize();

				while (this.medal_system.running)
				{
					this.wait();
				}

				local sizeKB = (this.medal_system.requiredSize + KB - 1) / KB;
				requiredSizeKB += sizeKB;
				this.printf("trophy require %d KB.\n", sizeKB);
			}

			this.printf("hdd requiredSize %d KB.\n", requiredSizeKB);
			this.printf("hdd freespace %d KB.\n", freeSizeKB);
			dialog.hide();

			if (requiredSizeKB > freeSizeKB)
			{
				this.halt(this.format(this.getSystemText("DIALOG_NO_HDD_SPACE"), (requiredSizeKB + KB - freeSizeKB + KB - 1) / KB));
			}
		}
		else
		{
		}
	}

	function initMedal()
	{
		if (!("MedalSystem" in ::getroottable()))
		{
			return;
		}

		if (this.medal_system_initialized)
		{
			return;
		}

		if (this.medal_system != null)
		{
			return;
		}

		local medal_data = ::loadData("config/medal.psb");

		if (medal_data)
		{
			this.medal_system = ::MedalSystem();
			this.medal_system.init(medal_data);
			this.medal_system_initialized = true;

			if (!this.medal_system.initialized)
			{
				this.printf("medal system initialization failed.\n");
				this.medal_system = null;
				return;
			}

			if (this.spec == "ps3" || this.spec == "vita" || this.spec == "ps4")
			{
				this.checkDiskCapacity();
				local dialog = ::ConfirmDialog(this.getBaseScreen());
				dialog.show(this.medal_system.requiredSize > 0 ? "DIALOG_INSTALL_TROPHY" : "DIALOG_CHECK_TROPHY");

				if (this.spec == "vita")
				{
					this.medal_system.install(false);
				}
				else
				{
					this.medal_system.install();
				}

				while (this.medal_system.running)
				{
					::wait();
				}

				dialog.hide();
			}
		}
	}

	function checkSyncPSP()
	{
		::suspend();

		if (this.installer != null && this.installer.installedError)
		{
			if (!this.installer.installedBroken)
			{
				this.installer.installedEnabled = false;
				this.systemErrorInform("DIALOG_INSTALLED_ERROR");
			}
			else
			{
				this.installer.installedEnabled = false;
				this.systemErrorInform("DIALOG_INSTALLED_ERROR_BROKEN");
			}

			this.setConfig("install", 0);
		}
	}

	function checkSyncX360()
	{
		::suspend();

		if (this.manager.checkSignout())
		{
			throw "softreset_signout";
		}

		if (this.checkStorage() && !this.checkPhysicalStorage())
		{
			throw "softreset_eject_storage";
		}
	}

	function parseSceneSFlags( id, storage, target )
	{
		local scnStorage = this.StorageData(storage);
		local scenario = scnStorage.findScene(target);

		if ("lines" in scenario)
		{
			local lines = scenario.lines;
			local cur = 0;
			local count = lines.len();

			for( local i = 0; i < count; i++ )
			{
				local obj = lines[i];

				if (typeof obj == "string")
				{
					this.setSystemFlag(obj, true);
				}
				else
				{
				}
			}
		}

		if ("texts" in scenario)
		{
			this.setReaded(id, scenario.texts.len() + 2);
		}
		else
		{
			this.setReaded(id, 1);
		}
	}

	function showUnreadScene()
	{
		foreach( id, scene in this.sceneIdMap.list )
		{
			local r = this.getReaded(id);

			if (scene.selects == null)
			{
				if (scene.textCount == 0)
				{
					this.printf("WARNING nodata scene:%s%s %d/%d\n", scene.storage, scene.target, r, scene.textCount);
				}
				else if (r < scene.textCount)
				{
					this.printf("unread scene:%s%s %d/%d\n", scene.storage, scene.target, r, scene.textCount);
				}
			}
		}
	}

	function showUnread()
	{
		this.printf("--- unread scene --\n");
		this.showUnreadScene();
	}

	function parseSFlags()
	{
		local dialog = ::ConfirmDialog(this.getBaseScreen());
		dialog.show("");

		foreach( id, scene in this.sceneIdMap.list )
		{
			local storage = scene.storage;

			if (!(storage.len() >= 4 && storage.substr(0, 4) == "test" || storage.len() >= 5 && storage.substr(0, 5) == "dummy"))
			{
				try
				{
					this.parseSceneSFlags(id, scene.storage, scene.target);
				}
				catch( e )
				{
					this.printf("failed to open %s%s:%s\n", scene.storage, scene.target, e.message);
				}

				dialog.setMessage(scene.storage + scene.target);
				dialog.work();
			}
		}

		dialog.hide();
		this.showUnread();
	}

	function breakSaveData()
	{
		if (this.spec == "psp" || this.spec == "ps3")
		{
			if (this.confirm("\x00e4\x00bf\x009d\x00e5\x00ad\x0098\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf\x00e3\x0082\x0092\x00e7\x00a0\x00b4\x00e5\x00a3\x008a\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0099"))
			{
				this.manager.secureFileId = "XXXXXXXXXXXXXXXX";
				local dialog = ::ConfirmDialog(this.getBaseScreen());
				dialog.show(this.getSystemDataText("\x00e7\x00a0\x00b4\x00e5\x00a3\x008a\x00e4\x00bf\x009d\x00e5\x00ad\x0098\x00e4\x00b8\x00ad"));
				this.doSaveSegment(this.systemBackup);
				this.doSaveSegment(this.gameBackup[this.title]);

				if (this.dataBackup != null)
				{
					this.doSaveSegment(this.dataBackup[this.title]);
				}

				dialog.inform("\x00e5\x00ae\x008c\x00e4\x00ba\x0086\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f");
				this.manager.secureFileId = "#\x0015\"\x00ff\x0081#B\x009a\x00b2#\x00ea#\x007fb\x0013\x0081";
			}
		}
	}

	function initPlayTime()
	{
		this.playStartTime = ::System.getSystemSecond();
	}

	function storePlayTime()
	{
		this.setSystemFlag("playTime", this.getPlayTime());
	}

	function restorePlayTime()
	{
		this.playTime = this.getSystemFlag("playTime", 0);
		this.initPlayTime();
	}

	function playMovieUtil( name, cancelKey = 0, aInput = null, cancelWait = 3 )
	{
		if (this.movieExt == "")
		{
			this.printf("failed to play movie:%s\n", name);
			return;
		}

		cancelWait = cancelWait * 60;
		local MOVIE_WIDTH = this.SCWIDTH;
		local MOVIE_HEIGHT = this.SCHEIGHT;
		local MOVIE_PATH = "movie/" + name + this.movieExt;

		if (this.spec == "psp")
		{
			::System.setInterval(2);
		}

		try
		{
			local movie = this.Movie();
			movie.volume = this.getMovieVolume();
			movie.smoothing = true;
			movie.priority = 27;
			local bounds = ::getScreenBounds();

			if (this.spec == "win")
			{
				bounds.width = 1920;
				bounds.height = 1080;
			}

			local scale = this.min(bounds.width / MOVIE_WIDTH, bounds.height / MOVIE_HEIGHT);
			local scale2 = ::baseScreen != null ? ::baseScreen.zoom : 1.0;
			movie.setZoom(scale * scale2);
			movie.setOffset(MOVIE_WIDTH / 2, MOVIE_HEIGHT / 2);
			movie.setCenter(MOVIE_WIDTH / 2, MOVIE_HEIGHT / 2);
			movie.play(MOVIE_PATH);
			local elapsedTime = 0;

			if (!movie.playing)
			{
			}
			else
			{
				if (this.spec == "win")
				{
					local scale = this.min(bounds.width / MOVIE_WIDTH, bounds.height / MOVIE_HEIGHT);
					local scale2 = ::baseScreen != null ? ::baseScreen.zoom : 1.0;
					movie.setZoom(scale * scale2);
					movie.setOffset(MOVIE_WIDTH / 2, MOVIE_HEIGHT / 2);
					movie.setCenter(MOVIE_WIDTH / 2, MOVIE_HEIGHT / 2);
				}

				movie.volume = this.getMovieVolume();

				if (elapsedTime >= cancelWait)
				{
					if (aInput == null && this.checkKeyPressed(cancelKey) || aInput != null && aInput.keyPressed(cancelKey))
					{
						  // [149]  OP_JMP            0     12    0    0
					}
				}

				::automaticTick();
				::sync();
				elapsedTime += ::System.getPassedFrame();
				  // [161]  OP_JMP            0    -76    0    0
			}
		}
		catch( e )
		{
			this.printf("failed to play movie:%s\n", name);
			::printException(e);
		}

		::sync();

		if (this.spec == "psp")
		{
			::System.setInterval(1);
		}
	}

	THUMBNAIL_WIDTH = 128;
	THUMBNAIL_HEIGHT = 72;
	INSTALL_CONFIG_NAME = "install";
	PACKMODE = 0;
	pageCount = 0;
	autoPageCount = 0;
	crossPageCount = 0;
	currentPage = null;
	pageSize = 0;
	pageError = false;
	dataCount = 0;
	autoDataCount = 0;
	crossDataCount = 0;
	dataSegCount = 0;
	info = null;
	PRESENCE_INIT = null;
	spec = null;
	tus = null;
	titleCount = 0;
	gameStruct = null;
	systemStruct = null;
	dataStruct = null;
	manager = null;
	systemBackup = null;
	gameBackup = null;
	dataBackup = null;
	title = 0;
	titleData = null;
	tsysflag = null;
	rdscene = null;
	rdsceneMax = 0;
	rdfile = null;
	rdfileMax = 0;
	tusStruct = null;
	gstruct = null;
	gbackup = null;
	dstruct = null;
	dbackup = null;
	sysflag = null;
	config = null;
	configInit = null;
	fileIdMap = null;
	sceneIdMap = null;
	qsave = null;
	medal_system = null;
	medal_system_initialized = false;
	medal = null;
	hasStorage = false;
	gameBackupBroken = false;
	installer = null;
	playTime = 0;
	playStartTime = 0;
}

class this.SystemYesNoDialog extends this.Object
{
	dialog = null;
	thread = null;
	running = true;
	result = null;
	msg = null;
	cur = null;
	constructor( _msg, _cur )
	{
		::Object.constructor();
		this.msg = _msg;
		this.cur = _cur;
		this.printf("system yesno dialog:%s\n", this.msg);
		this.thread = ::fork(this.run.bindenv(this));
	}

	function destroy()
	{
		this.thread.exit(0);
		this.thread = null;
	}

	function run()
	{
		this.dialog = this.NoInterruptConfirmDialog();
		this.dialog.priority = 35;
		this.result = this.dialog.confirm(this.msg, this.cur ? 0 : 1) ? 1 : 0;
		this.running = false;
	}

}

class this.SystemNoticeDialog extends this.Object
{
	dialog = null;
	thread = null;
	running = true;
	msg = null;
	constructor( _msg )
	{
		::Object.constructor();
		this.msg = _msg;
		this.printf("system notice dialog:%s\n", this.msg);
		this.thread = ::fork(this.run.bindenv(this));
	}

	function destroy()
	{
		this.thread.exit(0);
		this.thread = null;
	}

	function run()
	{
		this.dialog = this.NoInterruptConfirmDialog();
		this.dialog.priority = 35;
		this.dialog.inform(this.msg);
		this.running = false;
	}

}

class this.SystemSignalWaitDialog extends this.Object
{
	dialog = null;
	thread = null;
	closeSignal = false;
	running = true;
	msg = null;
	constructor( _msg )
	{
		::Object.constructor();
		this.msg = _msg;
		this.printf("system signal wait dialog:%s\n", this.msg);
		this.thread = ::fork(this.run.bindenv(this));
	}

	function destroy()
	{
		this.thread.exit(0);
		this.thread = null;
	}

	function close()
	{
		this.closeSignal = true;
	}

	function run()
	{
		this.dialog = this.NoInterruptConfirmDialog();
		this.dialog.priority = 35;
		this.dialog.show(this.msg);

		while (!this.closeSignal)
		{
			this.wait();
		}

		this.dialog.hide();
		this.running = false;
	}

}

