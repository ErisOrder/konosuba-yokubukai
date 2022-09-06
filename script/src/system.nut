class this.HistoryModeFunction extends this.Object
{
	HISTORY_PANEL_NUM = 3;
	HISTORY_LINE_NUM = 3;
	HISTORY_CURSOR_COLOR = 4294959590;
	HISTORY_BUTTON = "bt%d";
	constructor()
	{
		::Object.constructor();
	}

	historyLines = 0;
	historyDispMax = 0;
	historyDisp = 0;
	historyCur = 0;
	oHistoryDisp = 0;
	oHistoryCur = 0;
	historyInitPos = 0;
	historyDatas = null;
	function historyStart()
	{
		this.historyLines = this.getHistoryLines();
		this.historyDispMax = this.historyLines - 1;
		this.historyInitPos = this.historyDispMax - this.HISTORY_PANEL_NUM + 1;

		if (this.historyInitPos < 0)
		{
			this.historyInitPos = 0;
		}

		if (this.historyInitPos > this.historyDispMax)
		{
			this.historyInitPos = this.historyDispMax;
		}

		this.oHistoryDisp = this.historyDisp = this.historyInitPos;
		this.oHistoryCur = this.historyCur = this.historyDispMax - this.historyDisp;
		this.historyDatas = [];
		this.initData();
	}

	function historyInit( init = false )
	{
		this.setMotionFocus(this.format(this.HISTORY_BUTTON, this.historyCur + 1), init);
	}

	function initData()
	{
		this.historyDatas.clear();

		for( local i = 0; i < this.HISTORY_LINE_NUM; i++ )
		{
			local n = this.historyDisp + i;

			if (n < this.historyLines)
			{
				this.historyDatas.append(this.getHistoryData(n));
			}
		}
	}

	function getData( num )
	{
		if (num == null)
		{
			num = this.historyCur;
		}

		if (num < this.historyDatas.len())
		{
			return this.historyDatas[num];
		}
	}

	function historyGetVoice( num = null )
	{
		local h = this.getData(num);
		return h != null && ("voice" in h) && h.voice != null ? 1 : 0;
	}

	function getHistoryFont( data, cur )
	{
		if (cur && this.HISTORY_CURSOR_COLOR != null)
		{
			return {
				color = this.HISTORY_CURSOR_COLOR
			};
		}
	}

	function historyTextFilter( text )
	{
		if (this.HISTORY_LINE_NUM != null && ::countCR(text) >= this.HISTORY_LINE_NUM)
		{
			return ::removeCR(text);
		}

		return text;
	}

	function historyGetTextName( num = null )
	{
		local h = this.getData(num);

		if (h != null)
		{
			local r;
			local n = ::parseLangTextName(h);
			local t = ::parseLangText(h, "text");

			if (typeof t == "array" || typeof n == "array")
			{
				r = [];
				local c = typeof t == "array" ? t.len() : n.len();

				for( local i = 0; i < n; i++ )
				{
					local text = ::getLanguageText(t, i);
					local name = ::getLanguageText(n, i);
					r.append(this.format("\x00e3\x0080\x0090%s\x00e3\x0080\x0091\n%s", text, name));
				}
			}
			else
			{
				r = this.format("\x00e3\x0080\x0090%s\x00e3\x0080\x0091\n%s", n, t);
			}

			local ret = [
				r,
				null,
				h.indent
			];
			local font = this.getHistoryFont(h, num == this.historyCur);

			if (font != null)
			{
				ret.append(font);
			}

			return ret;
		}
	}

	function historyGetText( num = null )
	{
		local h = this.getData(num);

		if (h != null)
		{
			local t = ::parseLangText(h, "text");
			local ret = [
				t,
				null,
				h.indent
			];
			local font = this.getHistoryFont(h, num == this.historyCur);

			if (font != null)
			{
				ret.append(font);
			}

			return ret;
		}
	}

	function historyGetName( num = null )
	{
		local h = this.getData(num);

		if (h != null)
		{
			local t = ::parseLangTextName(h);
			local ret = [
				t,
				null,
				h.indent
			];
			local font = this.getHistoryFont(h, num == this.historyCur);

			if (font != null)
			{
				ret.append(font);
			}

			return ret;
		}
	}

	function isEnableHistoryName( num )
	{
		local h = this.getData(num);

		if (h != null)
		{
			local disp = this.getval(h, "name");
			return disp != null && disp != "" && disp != " ";
		}

		return false;
	}

	function historyVoice( num = null )
	{
		local h = this.getData(num);

		if (h != null)
		{
			if (("voice" in h) && h.voice != null)
			{
				this.playVoice(h.voice);
			}
		}
	}

	function historyJump( num = null )
	{
		if (num == null)
		{
			num = this.historyCur;
		}

		local n = this.historyDisp + num;

		if (this.checkHistoryJump(n))
		{
			if (this.confirm("YESNO_JUMP", "no"))
			{
				this.interruptHistoryJump(n);
			}
		}
	}

	function _historyMoveBefore()
	{
		this.oHistoryDisp = this.historyDisp;
		this.oHistoryCur = this.historyCur;
	}

	function _historyMoveAfter( init = false )
	{
		if (this.oHistoryDisp != this.historyDisp)
		{
			this.initData();

			if (init)
			{
				this.redraw(init);
			}
			else
			{
				this.setMotionFocus(null, true);
				this.redraw(init);
			}
		}
		else if (this.oHistoryCur != this.historyCur)
		{
			this.historyInit(init);
			this.redraw();
		}
	}

	function historyPageUp( init = false )
	{
		this._historyMoveBefore();

		if (this.historyDisp - this.HISTORY_PANEL_NUM >= 0)
		{
			this.historyDisp -= this.HISTORY_PANEL_NUM;

			if (this.historyCur > this.historyDispMax - this.historyDisp)
			{
				this.historyCur = this.historyDispMax - this.historyDisp;
			}
		}
		else
		{
			this.historyDisp = 0;
			this.historyCur = 0;
		}

		this._historyMoveAfter(init);
	}

	function historyPageDown( init = false )
	{
		this._historyMoveBefore();

		if (this.historyDisp + this.HISTORY_PANEL_NUM <= this.historyInitPos)
		{
			this.historyDisp += this.HISTORY_PANEL_NUM;

			if (this.historyCur > this.historyDispMax - this.historyDisp)
			{
				this.historyCur = this.historyDispMax - this.historyDisp;
			}
		}
		else
		{
			this.historyDisp = this.historyInitPos;
			this.historyCur = this.historyDispMax - this.historyDisp;
		}

		this._historyMoveAfter(init);
	}

	function historyUpDisable()
	{
		return this.historyCur <= 0 && this.historyDisp <= 0;
	}

	function historyUp( init = false )
	{
		this._historyMoveBefore();

		if (this.historyCur > 0)
		{
			this.historyCur--;
		}
		else if (this.historyDisp > 0)
		{
			this.historyDisp--;
		}

		this._historyMoveAfter(init);
	}

	function historyDownDisable()
	{
		if (this.historyCur < this.HISTORY_PANEL_NUM - 1)
		{
			return !(this.historyDisp + this.historyCur < this.historyDispMax);
		}
		else
		{
			return !(this.historyDisp + this.historyCur < this.historyDispMax && this.historyDisp < this.historyDispMax);
		}
	}

	function historyDown( init = false )
	{
		this._historyMoveBefore();

		if (this.historyCur < this.HISTORY_PANEL_NUM - 1)
		{
			if (this.historyDisp + this.historyCur < this.historyDispMax)
			{
				this.historyCur++;
			}
		}
		else if (this.historyDisp + this.historyCur < this.historyDispMax && this.historyDisp < this.historyDispMax)
		{
			this.historyDisp++;
		}

		init = false;
		this._historyMoveAfter(init);
	}

	function historyFirst( init = false )
	{
		this._historyMoveBefore();
		this.historyDisp = 0;
		this.historyCur = 0;
		this._historyMoveAfter(init);
	}

	function historyLast( init = false )
	{
		this._historyMoveBefore();
		this.historyDisp = this.historyInitPos;
		this.historyCur = this.historyDispMax - this.historyDisp;
		this._historyMoveAfter(init);
	}

	function getHistoryPosition()
	{
		return this.historyLines > 1 ? (this.historyDisp + this.historyCur).tofloat() / (this.historyLines - 1) : 0;
	}

	function setHistoryPosition( value, init = false )
	{
		this._historyMoveBefore();
		local n = this.toint(this.historyLines * value);

		if (n >= this.historyLines)
		{
			n = this.historyLines - 1;
		}

		local cur = n - this.historyDisp;

		if (cur >= 0 && cur < this.HISTORY_PANEL_NUM)
		{
			this.historyCur = cur;
		}
		else if (cur < 0)
		{
			this.historyCur = 0;
			this.historyDisp = n;
		}
		else
		{
			this.historyCur = this.HISTORY_PANEL_NUM - 1;
			this.historyDisp = n - this.historyCur;
		}

		this._historyMoveAfter(init);
	}

}

class this.SaveLoadModeFunction extends this.Object
{
	FILE_PANEL_NUM = 6;
	FILE_NODATA = null;
	FILE_BUTTON = "bt%d";
	saveMode = false;
	constructor( saveMode = true )
	{
		::Object.constructor();
		this.saveMode = saveMode;
	}

	function checkOpen()
	{
		return this.gameSaveLoadPrepare(this.saveMode ? 2 : 1);
	}

	type = 0;
	filter = true;
	fileInfoList = null;
	fileActiveList = null;
	fileCurIndex = null;
	fileMaxScrollCount = null;
	fileScrollIndex = null;
	function _fileStart( saveMode, type, filter )
	{
		this.fileActiveList = [];
		local num = this.getFileList(saveMode, type, filter, this.fileActiveList);
		this.fileMaxScrollCount = this.max(num - this.FILE_PANEL_NUM, 0);
		this.fileCurIndex = 0;
		this.fileScrollIndex = 0;
		return num;
	}

	function fileStart( saveMode = null, type = 7, filter = true, checkLast = false )
	{
		if (saveMode != null)
		{
			this.saveMode = saveMode;
		}

		this.type = type;
		this.filter = filter;
		local num = this._fileStart(saveMode, type, filter);

		if (checkLast)
		{
			local last = this.getLastSave();

			if (last != null)
			{
				this.fileScrollIndex = last / this.FILE_PANEL_NUM * this.FILE_PANEL_NUM;
			}
		}

		return num;
	}

	snapplayer = null;
	function fileEnd()
	{
		this.fileActiveList = null;
		this.snapplayer = null;
		this.clearPage();
	}

	function fileRestart()
	{
		this._fileStart(this.saveMode, this.type, this.filter);
		this.redraw();
	}

	function fileInit()
	{
		local focus = this.fileCurIndex - this.fileScrollIndex + 1;
		this.setMotionFocus(this.format(this.FILE_BUTTON, focus), true);
	}

	function fileUpload()
	{
		if (this.confirm("YESNO_UPLOAD_TUS", "no"))
		{
			local dialog = ::ConfirmDialog();
			dialog.show("DIALOG_TUS_UPLOAD");
			local ret = this.uploadCross(dialog);

			if (ret == true)
			{
				dialog.hide();
				this.inform("DIALOG_TUS_UPLOAD_SUCCESS");
				this.fileRestart();
			}
		}
	}

	function fileDownload()
	{
		if (this.confirm("YESNO_DOWNLOAD_TUS", "no"))
		{
			local dialog = ::ConfirmDialog();
			dialog.show("DIALOG_TUS_DOWNLOAD");
			local ret = this.downloadCross(dialog);

			if (ret == true)
			{
				dialog.inform("DIALOG_TUS_DOWNLOAD_SUCCESS");
				this.fileRestart();
			}
		}
	}

	function fileUp()
	{
		if (this.fileCurIndex > 0)
		{
			if (this.fileCurIndex == this.fileScrollIndex)
			{
				this.fileCurIndex--;
				this.fileScrollIndex--;
			}
			else
			{
				this.fileCurIndex--;
			}

			this.redraw();
		}
	}

	function fileDown()
	{
		if (this.fileCurIndex < this.fileActiveList.len() - 1)
		{
			if (this.fileCurIndex == this.fileScrollIndex + this.FILE_PANEL_NUM - 1)
			{
				this.fileScrollIndex++;
				this.fileCurIndex++;
			}
			else
			{
				this.fileCurIndex++;
			}

			this.redraw();
		}
	}

	function getFilePosition()
	{
		if (this.fileMaxScrollCount > 0)
		{
			return this.fileScrollIndex / this.fileMaxScrollCount;
		}

		return 0;
	}

	function setFilePosition( value )
	{
		local n = this.toint(this.fileMaxScrollCount * value);
		local cur = n - this.fileScrollIndex;

		if (cur >= 0 && cur < this.FILE_PANEL_NUM)
		{
			this.fileCurIndex = cur;
		}
		else if (cur < 0)
		{
			this.fileCurIndex = 0;
			this.fileScrollIndex = n;
		}
		else
		{
			this.fileCurIndex = this.FILE_PANEL_NUM - 1;
			this.fileScrollIndex = n - this.fileCurIndex;
		}

		this.redraw();
	}

	function fileGetNo( no )
	{
		local index = this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];
			return [
				finfo.type,
				finfo.index
			];
		}
	}

	function fileGetNew( no = null )
	{
		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			return this.getLastSave() == index;
		}
	}

	function fileGetText( no = null )
	{
		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];

			if (finfo.info != null)
			{
				local info = finfo.info;
				return this.format("%02d/%02d/%02d %02d:%02d", info.year % 100, info.mon, info.mday, info.hour, info.min);
			}
		}

		return "NO DATA";
	}

	function fileCheck( no )
	{
		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];
			return this.saveMode || finfo.info != null;
		}

		return false;
	}

	function fileExec( no = null )
	{
		if (this.fileCheck(no))
		{
			local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

			if (this.saveMode)
			{
				local fileInfo = this.fileActiveList[index];
				local newInfo = this.gameSave(fileInfo, this.getSaveData(), this.getSaveScreenCapture(), false);

				if (newInfo != null)
				{
					if (newInfo == false)
					{
						this.fileActiveList[index].info = null;
					}
					else
					{
						this.fileActiveList[index].info = newInfo;
					}
				}

				this.redraw();
			}
			else
			{
				local fileInfo = this.fileActiveList[index];

				if (fileInfo.info != null && this.askLoad())
				{
					local info = this.gameLoad(fileInfo);

					if (info != null)
					{
						if (!this.execLoad(info))
						{
							this.onProcess(info);
							this.setMotion("hide");
						}
					}
				}
			}
		}
	}

	function createThumbnail( finfo, size )
	{
		local info = finfo.info;

		if (info != null && "thumbnail" in info)
		{
			return this.createThumbnailInfo(info);
		}
		else if (size != null)
		{
			if (this.snapplayer == null)
			{
				this.snapplayer = this.getSnapPlayer();
			}

			local image = this.RawImage(size.width, size.height);
			local sceneName = info.storage;

			if ("target" in info)
			{
				sceneName += info.target;
			}

			if (this.snapplayer.snap(image, sceneName, info.point))
			{
				return image;
			}
		}
	}

	function fileGetThumb( no = null, size = null )
	{
		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];

			if (finfo.info != null)
			{
				return this.createThumbnail(finfo, size);
			}
			else
			{
				return this.FILE_NODATA;
			}
		}

		this.printf("%s:no thumbnail data\n", no);
		return null;
	}

	function convertTitle( title )
	{
		return title;
	}

	function fileInfoFormat( finfo, type = 0, nodata = null )
	{
		if (finfo != null && finfo.info != null)
		{
			local info = finfo.info;
			local title = this.convertTitle(info.title);
			local date = this.format("%02d/%02d/%02d", info.year % 100, info.mon, info.mday);
			local time = this.format("%02d:%02d", info.hour, info.min);
			local playtime = info.playTime;
			local hour = playtime / 3600;
			playtime -= hour * 3600;
			local min = playtime / 60;
			local sec = playtime % 60;
			playtime = this.format("%02d:%02d:%02d", hour, min, sec);
			return this.format("%s\n%s %s\nPLAYTIME %s", title, date, time, playtime);
		}
		else
		{
			return nodata;
		}
	}

	function fileGetInfo( no = null, type = 0, nodata = null )
	{
		if (nodata == null)
		{
			nodata = this.getSystemText("MESSAGE_NODATA");
		}

		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];
			local ret = this.fileInfoFormat(finfo, type, nodata);

			if (ret != null)
			{
				return ret;
			}
		}

		return nodata;
	}

	function fileGetFlag( name, no = null )
	{
		local index = no == null ? this.fileCurIndex : this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];

			if (finfo.info != null)
			{
				return ::getval(finfo.info.flags, name);
			}
		}
	}

}

class this.PageSaveLoadModeFunction extends this.SaveLoadModeFunction
{
	lastPageNo = 0;
	pageNo = 0;
	pageMax = 0;
	constructor( savemode = true )
	{
		::SaveLoadModeFunction.constructor(savemode);
	}

	function fileStart( saveMode = null, type = 0, page = null )
	{
		if (saveMode != null)
		{
			this.saveMode = saveMode;
		}

		this.type = type;
		this.fileMaxScrollCount = 0;
		this.fileCurIndex = 0;
		this.fileScrollIndex = 0;
		this.pageMax = this.getSaveDataPageCount(type) - 1;

		if (page == null)
		{
			this.pageNo = 0;

			if (type == 0)
			{
				local last = this.getLastSave();

				if (last != null)
				{
					this.pageNo = last / this.FILE_PANEL_NUM;
				}
			}
		}
		else
		{
			this.pageNo = page;
		}

		if (this.pageNo > this.pageMax)
		{
			this.pageNo = this.pageMax;
		}

		this.lastPageNo = this.pageNo;
		this.fileActiveList = this.getFilePage(type, this.pageNo);
		this.printf("fileActiveList:%d\n", this.fileActiveList.len());
	}

	function getFileCurrentPage()
	{
		return this.pageNo;
	}

	function getFileLastPage()
	{
		return this.lastPageNo;
	}

	function getFilePageNum()
	{
		return this.pageMax + 1;
	}

	function fileRestart()
	{
		this.fileActiveList = this.getFilePage(this.type, this.pageNo);
		this.redraw();
	}

	function filePageUp( loop = false )
	{
		this.lastPageNo = this.pageNo;

		if (this.pageNo < this.pageMax)
		{
			this.pageNo++;
			this.fileRestart();
		}
		else if (loop)
		{
			this.pageNo = 0;
			this.fileRestart();
		}
	}

	function filePageDown( loop = false )
	{
		this.lastPageNo = this.pageNo;

		if (this.pageNo > 0)
		{
			this.pageNo--;
			this.fileRestart();
		}
		else if (loop)
		{
			this.pageNo = this.pageMax;
			this.fileRestart();
		}
	}

}

class this.ConfigModeFunction extends this.Object
{
	constructor()
	{
		::Object.constructor();
	}

	textStartTick = null;
	textShowState = 0;
	function calcTextCount( maxnum, startTick )
	{
		local time = this.getCurrentTick() - startTick;
		local chStep = (1.0 - this.getConfig("textSpeed", 1.0)) * 50.0;
		local autoWait = (1.0 - this.getConfig("autoSpeed", 1.0)) * 2000.0;
		local textTime = chStep * maxnum;
		local allTime = textTime + 100 + autoWait;
		local totalTime = allTime + 100;

		if (this.textShowState > 1)
		{
			if (time > totalTime)
			{
				this.textShowState = 0;
				return null;
			}
			else
			{
				return 0;
			}
		}
		else if (this.textShowState > 0)
		{
			if (time > allTime)
			{
				this.textShowState = 2;
				return 0;
			}
			else
			{
				return maxnum;
			}
		}
		else if (time >= textTime)
		{
			this.textShowState = 1;
			return maxnum;
		}
		else
		{
			return ::toint(maxnum * time / textTime);
		}
	}

	function updateTextCount()
	{
		local text = this.getText("text");

		if (text != null && text.info.initSize)
		{
			if (this.textStartTick == null)
			{
				this.textStartTick = this.getCurrentTick();
			}

			local m = this.calcTextCount(text.info.render.getRenderCount(), this.textStartTick);

			if (m == null)
			{
				text.info.render.setShowCount(0);
				this.textStartTick = this.getCurrentTick();
			}
			else
			{
				text.info.render.setShowCount(m);
			}
		}
	}

}

class this.CgModeFunction extends this.Object
{
	data = null;
	cgmodelist = null;
	cgmodecaption = null;
	ch = 0;
	constructor( data )
	{
		::Object.constructor();
		this.data = data;
		this.select();
	}

	function getCgStorage( info )
	{
		switch(typeof info)
		{
		case "table":
			return ::getval(info, "storage");

		case "array":
			return info[0];
		}

		return info;
	}

	function getCompleteCount( ch = null, all = false )
	{
		local n = 0;
		local a = 0;

		if (ch == null)
		{
			foreach( i, value in this.data )
			{
				local count = this.getCompleteCount(i, all);
				n += count[0];
				a += count[1];
			}
		}
		else
		{
			local chdata = this.getChData(ch);
			local clist = typeof chdata == "table" ? ::getval(chdata, "list") : chdata;

			if (all)
			{
				local list = [];

				foreach( value in clist )
				{
					if (value != null)
					{
						local c = value.len();

						for( local i = 1; i < c; i++ )
						{
							local name = value[i];
							local id = this.getFileId(name.tolower());

							if (id >= 0)
							{
								list.append(id);
							}
						}

						n += this.rdfile.countFlags(list);
						a += list.len();
					}
				}
			}
			else
			{
				foreach( value in clist )
				{
					if (value != null)
					{
						if (::allSeen || this.isCgView(value))
						{
							n++;
						}

						a++;
					}
				}
			}
		}

		return [
			n,
			a
		];
	}

	function checkComplete( ch = null, all = false )
	{
		local count = this.getCompleteCount(ch, all);
		return count[0] == count[1];
	}

	function getCompletePercent( ch = null, all = false )
	{
		local count = this.getCompleteCount(ch, all);
		return ::toint(count[0] * 100.0 / count[1]);
	}

	function getChData( ch )
	{
		local chdata;

		switch(typeof this.data)
		{
		case "table":
			chdata = this.getval(this.data, "" + ch);
			break;

		case "array":
			chdata = this.data[this.toint(ch)];
			break;
		}

		if (chdata == null)
		{
			chdata = this.data;
		}

		return chdata;
	}

	function select( ch = 0 )
	{
		this.ch = ch;
		local chdata = this.getChData(ch);

		if (typeof chdata == "table")
		{
			this.cgmodelist = ::getval(chdata, "list");
			this.cgmodecaption = ::getval(chdata, "caption");
		}
		else
		{
			this.cgmodelist = chdata;
		}
	}

	function getCgCount()
	{
		return this.cgmodelist != null ? this.cgmodelist.len() : 0;
	}

	function getCgCaption( n )
	{
		return this.cgmodecaption != null ? this.cgmodecaption[n] : "";
	}

	function isCgView( list )
	{
		local c = list.len();

		for( local i = 1; i < c; i++ )
		{
			if (this.getFileReaded(this.getCgStorage(list[i])))
			{
				return true;
			}
		}

		return false;
	}

	function execCg( n, list )
	{
		local vlist = [];
		local c = list.len();

		for( local i = 1; i < c; i++ )
		{
			local info = list[i];

			if (info != null)
			{
				local storage = this.getCgStorage(info);

				if (::allSeen || this.getFileReaded(storage))
				{
					local s;

					switch(typeof info)
					{
					case "table":
						s = info;
						break;

					case "array":
						s = {
							storage = storage
						};

						if (info.len() > 1)
						{
							s.x <- info[1];
						}

						if (info.len() > 2)
						{
							s.y <- info[2];
						}

						break;

					default:
						s = {
							storage = storage
						};
						break;
					}

					vlist.append(s);
				}
			}
		}

		if (vlist.len() > 0)
		{
			local func = "execCgView";

			if (this.checkAppFunc(func))
			{
				this.callAppFunc(func, vlist);
			}
			else
			{
				this.onProcess({
					storage = "cgview",
					mode = 3,
					list = vlist,
					cur = n,
					stopbgm = false
				});
				this.setMotion("hide");
			}
		}
	}

	function playCg( n )
	{
		if (this.isCgOpen(n))
		{
			this.execCg(n, this.cgmodelist[n]);
		}
	}

	function isCgDisable( n )
	{
		return !(this.cgmodelist != null && n < this.cgmodelist.len() && this.cgmodelist[n] != null);
	}

	function getCgThumb( n )
	{
		if (this.isCgOpen(n))
		{
			return this.cgmodelist[n][0];
		}

		return 0;
	}

	function isCgOpen( n )
	{
		if (this.cgmodelist != null && n < this.cgmodelist.len())
		{
			return this.cgmodelist[n] != null && (::allSeen || this.isCgView(this.cgmodelist[n]));
		}

		return false;
	}

}

class this.ReplayModeFunction extends this.CgModeFunction
{
	constructor( data )
	{
		::CgModeFunction.constructor(data);
	}

	function isCgView( info )
	{
		if (info.len() > 4)
		{
			local flag = info[4];

			if (typeof flag == "string")
			{
				local ret;

				if (flag.find("*") != null)
				{
					ret = this.isSceneReaded(flag);
				}
				else
				{
					ret = this.getSystemFlag(flag);
				}

				return ret;
			}
		}

		local scene = info[1].tolower();
		local label = info.len() > 2 ? info[2] : null;

		if (label != null && label.len() > 0 && label.charAt(0) != "*")
		{
			label = "*" + label;
		}

		return this.isSceneReaded(scene + label);
	}

	function execCg( n, info )
	{
		local storage = info[1];
		local label = info.len() > 2 ? info[2] : null;

		if (label != null && label.len() > 0 && label.charAt(0) != "*")
		{
			label = "*" + label;
		}

		local mode = info.len() > 3 && info[3] == 1 ? 3 : 1;
		this.onProcess({
			storage = storage,
			target = label,
			mode = mode,
			cur = n
		});
		this.setMotion("hide");
	}

}

class this.MusicModeFunction extends this.Object
{
	musicObj = null;
	bgmlist = null;
	currentMusic = null;
	selMusic = 0;
	musicRepeat = 0;
	constructor( list, repeat = 0 )
	{
		::Object.constructor();
		this.bgmlist = list;
		this.musicObj = ::Music("bgm", ::SimpleSound, this);
		this.musicRepeat = repeat;
	}

	function destructor()
	{
		this.musicObj = null;
		this.bgmlist = null;
		::Object.destructor();
	}

	function getCompleteCount()
	{
		local a = 0;
		local n = 0;

		foreach( value in this.bgmlist )
		{
			if (value != null)
			{
				if (::musicAllSeen || ::allSeen)
				{
					n++;
				}
				else
				{
					switch(typeof value)
					{
					case "string":
						if (this.getFileReaded(value))
						{
							n++;
						}

						break;

					case "array":
						local v = value[1];

						if (v != null && this.getFileReaded(v))
						{
							n++;
						}

						break;

					case "table":
						local v = ::getval(value, "storage");

						if (v != null && this.getFileReaded(v))
						{
							n++;
						}

						break;
					}
				}

				a++;
			}
		}

		return [
			n,
			a
		];
	}

	function checkComplete()
	{
		local count = this.getCompleteCount();
		return count[0] == count[1];
	}

	function getCompletePercent()
	{
		local count = this.getCompleteCount();
		return ::toint(count[0] * 100.0 / count[1]);
	}

	function getMusicRepeat()
	{
		return this.musicRepeat;
	}

	function _updateMusicRepeat( old )
	{
		if (this.currentMusic != null && (old == 1 || this.musicRepeat == 1))
		{
			local n = this.currentMusic;
			this.stopMusic();
			this._startMusic(n);
		}
	}

	function setMusicRepeat( mode )
	{
		local old = this.musicRepeat;
		this.musicRepeat = mode;
		this._updateMusicRepeat(old);
	}

	function changeMusicRepeat()
	{
		local old = this.musicRepeat;
		this.musicRepeat = (this.musicRepeat + 1) % 3;
		this._updateMusicRepeat(old);
	}

	function onStopSound( sound, user )
	{
		if (!user && sound.storage != null && this.musicObj != null)
		{
			switch(this.musicRepeat)
			{
			case 0:
				break;

			case 1:
				break;

			case 2:
				this.nextMusic();
				break;
			}
		}
	}

	function onStartSound( sound )
	{
	}

	function getMusicCount()
	{
		return this.bgmlist != null ? this.bgmlist.len() : 0;
	}

	function isMusicOpen( n )
	{
		if (n < this.bgmlist.len())
		{
			if (::musicAllSeen || ::allSeen)
			{
				return true;
			}

			local info = this.bgmlist[n];

			switch(typeof info)
			{
			case "string":
				return this.getFileReaded(info);

			case "array":
				if (info.len() > 2)
				{
					return this.getSystemFlag(info[2]);
				}
				else
				{
					return this.getFileReaded(info[1]);
				}

			case "table":
				if ("flag" in info)
				{
					return this.getSystemFlag(info.flag);
				}
				else if ("storage" in info)
				{
					return this.getFileReaded(info.storage);
				}
			}
		}

		return false;
	}

	function getMusicNo( n )
	{
		if (this.isMusicOpen(n))
		{
			local info = this.bgmlist[n];

			switch(typeof info)
			{
			case "array":
				return info[0];

			case "table":
				if ("no" in info)
				{
					return info.no;
				}
			}

			return n + 1;
		}

		return 0;
	}

	function isMusicPlaying( n = null )
	{
		if (n == null)
		{
			return this.currentMusic != null;
		}
		else
		{
			return n < this.bgmlist.len() && this.currentMusic == n;
		}
	}

	function selectMusic( n )
	{
		this.selMusic = n;
	}

	function _startMusic( music )
	{
		this.currentMusic = music;
		local info = this.bgmlist[this.currentMusic];
		local name;

		switch(typeof info)
		{
		case "string":
			name = info;
			break;

		case "array":
			name = info[1];
			break;

		case "table":
			name = ::getval(info, "storage");
			break;
		}

		this.musicObj.play(name, this.musicRepeat == 1 ? -1 : 1);
		this.redraw();
	}

	function playMusic()
	{
		if (this.selMusic != null)
		{
			if (this.currentMusic == this.selMusic && this.musicObj.playing)
			{
				this.stopMusic();
			}
			else
			{
				this.startMusic();
			}
		}
	}

	function startMusic()
	{
		if (this.selMusic != null && this.isMusicOpen(this.selMusic))
		{
			this._startMusic(this.selMusic);
		}
	}

	function stopMusic()
	{
		this.musicObj.stop(500);
		this.currentMusic = null;
		this.redraw();
	}

	function nextMusic()
	{
		local c = this.currentMusic != null ? this.currentMusic : this.selMusic;
		local n = (c + 1) % this.bgmlist.len();

		while (n != c && !this.isMusicOpen(n))
		{
			n = (n + 1) % this.bgmlist.len();
		}

		if (n != c)
		{
			this._startMusic(n);
		}
	}

	function prevMusic()
	{
		local c = this.currentMusic != null ? this.currentMusic : this.selMusic;
		local n = (c - 1 + this.bgmlist.len()) % this.bgmlist.len();

		while (n != c && !this.isMusicOpen(n))
		{
			n = (n - 1 + this.bgmlist.len()) % this.bgmlist.len();
		}

		if (n != c)
		{
			this._startMusic(n);
		}
	}

}

class this.CGViewPlayer extends ::EnvPlayer
{
	constructor( app )
	{
		::EnvPlayer.constructor(app, false);
	}

	function checkClick()
	{
		return this.exitFlag || this.nextFlag;
	}

	function checkCommand()
	{
		if (this.panel != null && this.panel._work())
		{
			this.sync();
			return true;
		}
	}

	function next()
	{
		this.nextFlag = true;
	}

	function done()
	{
		this.exitFlag = true;
	}

	function main( scene )
	{
		local list = ::getval(scene, "list");

		if (list == null || list.len() <= 0)
		{
			return -1;
		}

		this.panel = this.createMotionPanelLayer(23);
		this.panel.show({
			chara = "cgview",
			motion = "show"
		}, "motion/cgview.psb");
		this.ev = this.env.createEnvObject("ev", "event");
		this.exitFlag = false;
		local info = list[0];
		this.xpos = this.getval(info, "x", 0);
		this.ypos = this.getval(info, "y", 0);
		this.currentStorage = null;

		foreach( info in list )
		{
			if (this.exitFlag)
			{
				break;
			}

			local storage = this.getval(info, "storage");

			if (storage != null)
			{
				this.currentStorage = storage;
				this.nextFlag = false;
				this.beginEnvTrans(false);
				this.ev.objUpdateAll({
					showmode = 1,
					redraw = {
						imageFile = storage
					}
				});
				this.movecheck();
				this.updateImage();
				this.doEnvTrans({
					method = "crossfade",
					time = 500
				});
				this.waitTransition();
				this.waitClick();
			}
		}

		this.currentStorage = null;
		this.beginEnvTrans(false);
		this.ev = null;
		this.env.envInit();
		this.doEnvTrans({
			method = "crossfade",
			time = 500
		});
		this.waitTransition();
		local p = this.panel;
		this.panel = null;
		p.playWait("hide");
	}

	panel = null;
	ev = null;
	nextFlag = false;
	prevNextFlag = false;
	exitFlag = false;
	currentStorage = null;
	function getPicture()
	{
		return null;
	}

	function updateImage()
	{
		this.env.camera.shiftx = this.xpos;
		this.env.camera.shifty = this.ypos;
		this.env.camera.camerazoom = this.zoom * 100;
	}

	function initPos()
	{
		if (this.xpos != 0 || this.ypos != 0 || this.zoom != this.initZoom)
		{
			this.xpos = 0;
			this.ypos = 0;
			this.zoom = this.initZoom;
			this.updateImage();
		}
	}

	function movecheck()
	{
		local w = 0;
		local h = 0;

		if (this.ev != null && this.ev.targetLayer != null)
		{
			local picture = this.ev.targetLayer;
			w = picture.width;
			h = picture.height;
		}

		if (w < 1920)
		{
			w = 1920;
		}

		if (h < 1080)
		{
			h = 1080;
		}

		local xmax = this.toint((w * this.zoom - 1920) / 2);
		local ymax = this.toint((h * this.zoom - 1080) / 2);

		if (this.xpos < -xmax)
		{
			this.xpos = -xmax;
		}
		else if (this.xpos > xmax)
		{
			this.xpos = xmax;
		}

		if (this.ypos < -ymax)
		{
			this.ypos = -ymax;
		}
		else if (this.ypos > ymax)
		{
			this.ypos = ymax;
		}
	}

	function move( x, y )
	{
		local ox = this.xpos;
		local oy = this.ypos;
		this.xpos += x;
		this.ypos += y;
		this.movecheck();

		if (this.xpos != ox || this.ypos != oy)
		{
			this.updateImage();
		}
	}

	xpos = 0;
	ypos = 0;
	zoom = 1.0;
	initZoom = 1.0;
}

function createGamePlayer( owner, scene )
{
	if (::getval(scene, "storage") == "cgview")
	{
		return this.CGViewPlayer(owner);
	}
	else
	{
		return this.ScenePlayer(owner);
	}
}

