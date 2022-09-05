this.printf("start override\n");
this.system("script/minigame.nut");
this.menuKey <- this.lowerExtraKey;
this.historyKey <- this.upperExtraKey;
::DIALOG_SHIFT <- 0;
this.inputHub.transferAnalogToDigital = true;
this.inputHub.transferRightAnalogToDigital = true;
function checkVITA()
{
	return this.TARGET_SYSTEM == "VITA";
}

function checkfile( name )
{
	return this.checkVITA() ? name + "_VITA" : name + "_PS4";
}

this.sysse <- this.SysSound("sound/sysse.psb", "syssearc", "se");
this.defaultMotionInfo <- [
	"touchEnable",
	1,
	"initvar",
	{
		vita = "TARGET_SYSTEM==\"VITA\"?1:0"
	},
	{
		function focus( self, owner, init, focus )
		{
			if (!init && focus)
			{
				this.sysse.play("cursor");
			}
		}

		function change( self, value, drag )
		{
			if (!drag)
			{
				local se;

				if ("sefunc" in self.elm)
				{
					se = this.eval(self.elm.sefunc);
				}
				else if ("seid" in self.elm)
				{
					se = self.elm.seid;
				}
				else
				{
					se = "ok";
				}

				if (se != null && se != "")
				{
					this.sysse.play(se);
				}
			}
		}

	}
];
class this.CommandModeFunction extends this.Object
{
	constructor()
	{
		::Object.constructor();
	}

	function commandInit( chara, motion, coffee )
	{
	}

	function commandStop( chara, motion, coffee )
	{
		if (motion == "show")
		{
			if (coffee)
			{
				this.entryCapture(::EnvPlayerBase.getScreenCapture(this.getBaseScreen(), 25));
			}
		}
	}

}

class this.ManualModeFunction extends this.Object
{
	constructor()
	{
		::Object.constructor();
	}

	nimage = null;
	nid = null;
	oimage = null;
	oid = null;
	function changePage( page )
	{
		local name = this.format("man%03d", page + 1);
		local data = this.loadImageData(name);

		if (this.oimage != null)
		{
			this.unregisterIcon(this.oid);
			this.oimage = null;
			this.oid = null;
		}

		if (this.nimage != null)
		{
			this.unregisterIcon(this.nid);
			this.oimage = this.nimage;
			this.oid = this.registerIcon(this.oimage, "manual", "001");
			this.nimage = null;
			this.nid = null;
		}

		if (data != null)
		{
			this.nimage = ::Image(data);

			if (this.nimage != null)
			{
				this.nid = this.registerIcon(this.nimage, "manual", "002");
			}
		}
	}

}

class this.MySaveLoadModeFunction extends ::PageSaveLoadModeFunction
{
	constructor( savemode )
	{
		::PageSaveLoadModeFunction.constructor(savemode);
		this.FILE_PANEL_NUM = 8;
	}

	function checkRoute( info )
	{
		if ("route" in info)
		{
			return info.route;
		}

		return null;
	}

	function fileInfoFormat( finfo, type = 0, nodata = null )
	{
		local info = finfo.info;

		switch(type)
		{
		case 0:
			return this.format("No.%02d", finfo.index + 1);

		case 1:
			if (info != null)
			{
				local date = this.format("%04d/%02d/%02d", info.year, info.mon, info.mday);
				local time = this.format("%02d:%02d", info.hour, info.min);
				local playtime = info.playTime;
				local hour = playtime / 3600;
				playtime -= hour * 3600;
				local min = playtime / 60;
				local sec = playtime % 60;
				playtime = this.format("%02d:%02d:%02d", hour, min, sec);
				return this.format("%s %s", date, time);
			}
			else
			{
				return "\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0083\x0096\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093";
			}

		case 2:
			if (info != null)
			{
				switch(info.route)
				{
				case 0:
					return "\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0082\x00b0\x00e3\x0080\x008c\x00e3\x0081\x0093\x00e3\x0081\x00ae\x00e5\x0091\x00aa\x00e3\x0082\x008f\x00e3\x0082\x008c\x00e3\x0081\x009f\x00e6\x008c\x0087\x00e8\x00bc\x00aa\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 1:
					return "\x00e7\x00ac\x00ac\x00ef\x00bc\x0091\x00e7\x00ab\x00a0\x00e3\x0080\x008c\x00e3\x0081\x0093\x00e3\x0081\x00ae\x00e4\x00b8\x0096\x00e7\x0095\x008c\x00e3\x0081\x00ab\x00e3\x0083\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x0089\x00e3\x0081\x00ae\x00e5\x0096\x009c\x00e3\x0081\x00b3\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 2:
					return "\x00e7\x00ac\x00ac\x00ef\x00bc\x0092\x00e7\x00ab\x00a0\x00e3\x0080\x008c\x00e9\x0081\x008b\x00e5\x008b\x0095\x00e4\x00bc\x009a\x00e3\x0081\x00a7\x00e4\x00b8\x0080\x00e6\x0094\x00ab\x00e5\x008d\x0083\x00e9\x0087\x0091\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 3:
					return "\x00e7\x00ac\x00ac\x00ef\x00bc\x0093\x00e7\x00ab\x00a0\x00e3\x0080\x008c\x00e9\x0080\x0080\x00e5\x00b1\x0088\x00e3\x0081\x00aa\x00e6\x0097\x00a5\x00e5\x00b8\x00b8\x00e3\x0081\x00ab\x00e8\x0087\x00b3\x00e4\x00b8\x008a\x00e3\x0081\x00ae\x00e5\x00a8\x00af\x00e6\x00a5\x00bd\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 4:
					return "\x00e7\x00ac\x00ac\x00ef\x00bc\x0094\x00e7\x00ab\x00a0\x00e3\x0080\x008c\x00e5\x0088\x009d\x00e5\x00bf\x0083\x00e3\x0081\x00ab\x00e6\x0088\x00bb\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0082\x00af\x00e3\x0082\x00a8\x00e3\x0082\x00b9\x00e3\x0083\x0088\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 5:
					return "\x00e7\x00ac\x00ac\x00ef\x00bc\x0095\x00e7\x00ab\x00a0\x00e3\x0080\x008c\x00e3\x0081\x0093\x00e3\x0081\x00ae\x00e3\x0081\x008f\x00e3\x0081\x00a0\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e5\x0091\x00aa\x00e3\x0081\x0084\x00e3\x0081\x00ab\x00e7\x00b5\x0082\x00e6\x00ad\x00a2\x00e7\x00ac\x00a6\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 10:
					return "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e5\x009b\x00b0\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e5\x00a5\x00b3\x00e7\x00a5\x009e\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 11:
					return "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e5\x0081\x00bd\x00e3\x0082\x008a\x00e3\x0081\x00ae\x00e8\x008a\x00b1\x00e5\x00ab\x0081\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 12:
					return "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e7\x00b4\x00a0\x00e6\x0099\x00b4\x00e3\x0082\x0089\x00e3\x0081\x0097\x00e3\x0081\x0084\x00e5\x008f\x008b\x00e6\x0083\x0085\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 13:
					return "\x00e3\x0082\x00a6\x00e3\x0082\x00a3\x00e3\x0082\x00ba\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e7\x00be\x008e\x00e3\x0081\x0097\x00e3\x0081\x008d\x00e5\x00ba\x0097\x00e4\x00b8\x00bb\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 14:
					return "\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e5\x00a3\x00ae\x00e5\x00a4\x00a7\x00e3\x0081\x00aa\x00e5\x008b\x0098\x00e9\x0081\x0095\x00e3\x0081\x0084\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";

				case 15:
					return "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0080\x008c\x00e8\x0087\x00aa\x00e5\x00a0\x0095\x00e8\x0090\x00bd\x00e3\x0081\x00aa\x00e7\x0094\x009f\x00e6\x00b4\x00bb\x00e3\x0081\x00ab\x00e7\x00a5\x009d\x00e7\x00a6\x008f\x00e3\x0082\x0092\x00ef\x00bc\x0081\x00e3\x0080\x008d";
				}
			}
			else
			{
				return "";
			}
		}

		if (info != null)
		{
			return info.text;
		}
	}

	function fileGetChara( no = null )
	{
		if (no == null)
		{
			return 0;
		}

		local index = this.fileScrollIndex + no;

		if (index < this.fileActiveList.len())
		{
			local finfo = this.fileActiveList[index];

			if (finfo.info != null)
			{
				local info = finfo.info;
				local route = this.checkRoute(info);

				switch(info.route)
				{
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
					return 0;

				case 10:
					return 1;

				case 11:
					return 2;

				case 12:
					return 3;

				case 13:
					return 5;

				case 14:
					return 4;

				case 15:
					return 6;
				}
			}
		}

		return 0;
	}

}

class this.PantsSelectFunction extends this.Object
{
	rimage = null;
	rid = null;
	pnimages = null;
	oimage = null;
	nimage = null;
	nid = null;
	oid = null;
	constructor( pants, route = null )
	{
		::Object.constructor();

		if (route != null)
		{
			this.rimage = ::Image(this.loadImageData(this.format("tx_target%01d", route)));
		}

		if (pants != null && pants.len() > 0)
		{
			this.pnimages = [];

			foreach( no in pants )
			{
				local pn = ::Image(this.loadImageData(this.format("pn%02d", no)));
				local nm = ::Image(this.loadImageData(this.format("txpn%02d", no)));
				local tx = ::Image(this.loadImageData(this.format("txpt%02d", no)));
				this.pnimages.append({
					pn = pn,
					nm = nm,
					tx = tx
				});
			}
		}
	}

	function destructor()
	{
		this.pantsClose();

		if (this.pnimages != null)
		{
			this.pnimages.clear();
			this.pnimages = null;
		}

		this.rimage = null;
	}

	function pantsOpen()
	{
		if (this.rimage != null)
		{
			this.rid = this.registerIcon(this.rimage, "text", "pntaim0");
		}

		this.pantsChange(0);
		return this.pnimages != null ? this.pnimages.len() - 1 : 0;
	}

	function pantsClose()
	{
		if (this.rid != null)
		{
			this.unregisterIcon(this.rid);
			this.rid = null;
		}

		if (this.oimage != null)
		{
			this.unregisterIcon(this.oid.pn);
			this.unregisterIcon(this.oid.nm);
			this.unregisterIcon(this.oid.tx);
			this.oimage = null;
			this.oid = null;
		}

		if (this.nimage != null)
		{
			this.unregisterIcon(this.nid.pn);
			this.unregisterIcon(this.nid.nm);
			this.unregisterIcon(this.nid.tx);
			this.nimage = null;
			this.nid = null;
		}
	}

	function pantsChange( no )
	{
		if (this.oimage != null)
		{
			this.unregisterIcon(this.oid.pn);
			this.unregisterIcon(this.oid.nm);
			this.unregisterIcon(this.oid.tx);
			this.oimage = null;
			this.oid = null;
		}

		if (this.nimage != null)
		{
			this.unregisterIcon(this.nid.pn);
			this.unregisterIcon(this.nid.nm);
			this.unregisterIcon(this.nid.tx);
			this.oimage = this.nimage;
			local pn = this.registerIcon(this.nimage.pn, "pnt", "pnt1");
			local nm = this.registerIcon(this.nimage.nm, "text", "pntnm1");
			local tx = this.registerIcon(this.nimage.tx, "text", "pnttx1");
			this.oid = {
				pn = pn,
				nm = nm,
				tx = tx
			};
			this.nimage = null;
			this.nid = null;
		}

		if (this.pnimages != null && no != null)
		{
			this.nimage = this.pnimages[no];
			local pn = this.registerIcon(this.nimage.pn, "pnt", "pnt0");
			local nm = this.registerIcon(this.nimage.nm, "text", "pntnm0");
			local tx = this.registerIcon(this.nimage.tx, "text", "pnttx0");
			this.nid = {
				pn = pn,
				nm = nm,
				tx = tx
			};
		}
	}

}

class this.TestifySelectFunction extends ::HistoryModeFunction
{
	sellist = null;
	addmode = false;
	title = 0;
	constructor( sellist, title = 0, addmode = false )
	{
		::HistoryModeFunction.constructor();
		this.sellist = sellist;
		this.addmode = addmode;
		this.title = title;
	}

	function getTitle()
	{
		return this.title;
	}

	function historyStart()
	{
		::HistoryModeFunction.historyStart();
		this.oHistoryDisp = this.historyDisp = 0;
		this.oHistoryCur = this.historyCur = 0;
		this.historyDatas = [];
		this.initData();
	}

	function getHistoryLines()
	{
		return this.sellist.len();
	}

	function getHistoryData( pos )
	{
		local sel = this.sellist[pos];
		local ret = {
			text = ::getval(sel, "text"),
			name = ::getval(sel, "name", ""),
			title = "",
			indent = 0
		};
		return ret;
	}

	function historyVoice( num = null )
	{
		if (num == null)
		{
			num = this.historyCur;
		}

		this.onProcess(this.historyDisp + num);
	}

	function showAdd()
	{
		if (this.addmode)
		{
			local btname = [
				"bt1",
				"bt2",
				"bt3"
			][this.historyCur];
			local bt = this.getButton(btname);
			this.printf("\x00e8\x00a1\x00a8\x00e7\x00a4\x00ba\x00e6\x00bc\x0094\x00e5\x0087\x00ba:%s:%s\n", btname, bt);
			local nname = [
				"name1",
				"name2",
				"name3"
			][this.historyCur];
			local bn = this.getText(nname);

			if (bt != null)
			{
				local XDIFF = 1500;
				local FRAME = 30.0;

				for( local i = 0; i <= FRAME; i++ )
				{
					bt.textInfo.setOffset(XDIFF * (1.0 - i / FRAME), 0);

					if (bn != null)
					{
						bn.setOffset(XDIFF * (1.0 - i / FRAME), 0);
					}

					::wait(1);
				}

				bt.setVariable("flash", 1);
			}

			::wait(45);
			this.onProcess(0);
			this.setMotion("hide");
		}
	}

}

class this.ParameterFunction extends ::TestifySelectFunction
{
	pantsFunc = null;
	constructor( pantsFunc, sellist )
	{
		::TestifySelectFunction.constructor(sellist);

		if (pantsFunc != null)
		{
			pantsFunc.setDelegate(this);
			this.pantsFunc = pantsFunc;
		}
	}

	function pantsOpen()
	{
		if (this.pantsFunc)
		{
			return this.pantsFunc.pantsOpen();
		}

		return 0;
	}

	function pantsClose()
	{
		if (this.pantsFunc)
		{
			this.pantsFunc.pantsClose();
		}
	}

	function pantsChange( page )
	{
		if (this.pantsFunc)
		{
			this.pantsFunc.pantsChange(page);
		}
	}

}

class this.ThumbFunction extends ::Object
{
	thumlist = null;
	oimage = null;
	nimage = null;
	nid = null;
	oid = null;
	PAGENUM = 9;
	constructor()
	{
		::Object.constructor();
	}

	function destructor()
	{
		this.thumClose();
	}

	function thumOpen()
	{
		this.thumlist = [];

		foreach( n in this.cgmodelist )
		{
			local file = this.format("thum%03d", n[0]);
			local img = ::Image(this.loadImageData(file));
			this.thumlist.append(img);
		}
	}

	function thumClose()
	{
		if (this.oimage != null)
		{
			foreach( id in this.oid )
			{
				this.unregisterIcon(id);
			}

			this.oimage.clear();
			this.oimage = null;
			this.oid = null;
		}

		if (this.nimage != null)
		{
			foreach( id in this.nid )
			{
				this.unregisterIcon(id);
			}

			this.nimage.clear();
			this.nimage = null;
			this.nid = null;
		}

		if (this.thumlist != null)
		{
			this.thumlist.clear();
			this.thumlist = null;
		}
	}

	function thumPage( no = null )
	{
		if (this.oimage != null)
		{
			foreach( id in this.oid )
			{
				this.unregisterIcon(id);
			}

			this.oimage.clear();
			this.oimage = null;
			this.oid = null;
		}

		if (this.nimage != null)
		{
			foreach( id in this.nid )
			{
				this.unregisterIcon(id);
			}

			this.oimage = this.nimage;
			this.oid = [];

			for( local i = 0; i < this.PAGENUM; i++ )
			{
				local img = this.oimage[i];

				if (img != null)
				{
					local id = this.registerIcon(img, "thum", this.format("thum%02d", 9 + i));
					this.oid.append(id);
				}
			}

			this.nimage = null;
			this.nid = null;
		}

		if (no != null)
		{
			this.nid = [];
			this.nimage = [];

			for( local i = 0; i < this.PAGENUM; i++ )
			{
				local n = this.PAGENUM * no + i;

				if (this.isCgOpen(n))
				{
					local img = this.thumlist[n];
					local id = this.registerIcon(img, "thum", this.format("thum%02d", i));
					this.nid.append(id);
					this.nimage.append(img);
				}
				else
				{
					this.nimage.append(null);
				}
			}
		}
	}

}

class this.MyCgModeFunction extends ::CgModeFunction
{
	thuminfo = null;
	constructor( data )
	{
		::CgModeFunction.constructor(data);
		this.thuminfo = ::ThumbFunction();
		this.thuminfo.setDelegate(this);
	}

	function getShowThumb( n )
	{
		if (this.isCgOpen(n))
		{
			return n % 9 + 1;
		}

		return 0;
	}

	function getHideThumb( n )
	{
		if (this.isCgOpen(n))
		{
			return n % 9 + 10;
		}

		return 0;
	}

	function thumOpen()
	{
		this.thuminfo.thumOpen();
	}

	function thumPage( no )
	{
		this.thuminfo.thumPage(no);
	}

	function thumClose()
	{
		this.thuminfo.thumClose();
	}

}

class this.MyReplayModeFunction extends ::ReplayModeFunction
{
	thuminfo = null;
	constructor( data )
	{
		::ReplayModeFunction.constructor(data);
		this.thuminfo = ::ThumbFunction();
		this.thuminfo.setDelegate(this);
	}

	function getShowThumb( n )
	{
		if (this.isCgOpen(n))
		{
			return n % 9 + 1;
		}

		return 0;
	}

	function getHideThumb( n )
	{
		if (this.isCgOpen(n))
		{
			return n % 9 + 10;
		}

		return 0;
	}

	function thumOpen()
	{
		this.thuminfo.thumOpen();
	}

	function thumPage( no )
	{
		this.thuminfo.thumPage(no);
	}

	function thumClose()
	{
		this.thuminfo.thumClose();
	}

}

class this.MyPlayer extends ::ScenePlayer
{
	standLevels = [
		42.799999,
		100,
		142.8
	];
	VOICE_TARGET_SPLIT = "\x00ef\x00bc\x0086";
	SELECT_HISTORY_PREFIX = "";
	skipKey = 256;
	forceUnreadSkipKey = 256;
	FORCESKIP_DELAY = 30;
	autoFuncKey = 4;
	playCommands = [
		{
			key = this.menuKey,
			fkey = 256 | 33554432,
			func = "cmdCommand"
		},
		{
			key = this.historyKey,
			fkey = 2,
			func = "cmdHistory",
			eval = "getHistoryLines()>0"
		},
		{
			key = 64,
			func = "cmdHistory",
			eval = "getHistoryLines()>0"
		},
		{
			fkey = 1,
			func = "cmdManualEx"
		}
	];
	function canSelectHistory()
	{
		return this.selectType == null;
	}

	selectCommands = [
		{
			key = this.menuKey,
			fkey = 256,
			func = "cmdCommand",
			hideSelect = false
		},
		{
			key = this.historyKey,
			fkey = 2,
			func = "cmdHistory",
			eval = "canSelectHistory() && getHistoryLines()>0"
		}
	];
	enableDLC = 0;
	function getMsgScale()
	{
		return 1920 / this.SCWIDTH.tofloat();
	}

	autoskip = null;
	msgWaitMode = 0;
	hppanel = null;
	hpvalue = 0;
	enableRstick = true;
	constructor( app )
	{
		::ScenePlayer.constructor(app, true, false);
		this.initInfoBase([
			"motion/main.psb",
			"motion/main_hp.psb",
			"motion/particle.psb"
		]);
		local qcmd;
		qcmd = [
			{
				key = 8388608,
				fkey = 128,
				func = "cmdQuickSave",
				eval = "enableRstick&&isNormalPlay()",
				hideSelect = false
			},
			{
				key = 16777216,
				fkey = 64,
				func = "cmdQuickLoad",
				eval = "enableRstick&&isNormalPlay()&&doQuickLoad()",
				hideSelect = false
			}
		];

		if (qcmd != null)
		{
			this.playCommands.extend(qcmd);
			this.selectCommands.extend(qcmd);
		}

		this.autoskip = ::Motion(this.infobase);
		this.autoskip.chara = "AUTOSKIP";
	}

	function destructor()
	{
		this.autoskip = null;
		this.hppanel = null;

		if (this.dateinfo != null)
		{
			this.dateinfo.stop();
			this.dateinfo = null;
		}

		if (this.placeinfo != null)
		{
			this.placeinfo.stop();
			this.placeinfo = null;
		}

		::ScenePlayer.destructor();
	}

	function updateMsgWait()
	{
		this.msg.setWait(this.playMode == 0 ? this.msgWaitMode : 0, this.curReaded);
	}

	function msgWait( mode )
	{
		this.msgWaitMode = mode;
		this.updateMsgWait();
	}

	function nameFilterForHistory( text )
	{
		local t = this.nameFilter(text);
		return t == "" ? t : "\x00e3\x0080\x0090" + t + "\x00e3\x0080\x0091";
	}

	function checkDLC( no = 1 )
	{
		return no > 0 && this.enableDLC == no && (this.dlc & 1 << no - 1) != 0;
	}

	eventSpeed = 1.0;
	eventSpeedMag = 1.0;
	charaSpeed = 1.0;
	charaSpeedMag = 1.0;
	function onUpdateConfig()
	{
		this.eventSpeed = this.getConfig("eventSpeed", 1.0);
		this.charaSpeed = this.getConfig("charaSpeed", 1.0);
		this.eventSpeedMag = this.eventSpeed < 0.0099999998 ? 100 : 1.0 / this.eventSpeed;
		this.charaSpeedMag = this.charaSpeed < 0.0099999998 ? 100 : 1.0 / this.charaSpeed;
		this.enableDLC = this.getConfig("enableDLC", 0);

		if (!this.checkDLC(this.enableDLC))
		{
			this.enableDLC = 0;
		}

		this.enableRstick = this.getConfig("enableRstick", 1) != 0;
	}

	function onPlayVoice( v )
	{
	}

	function checkAction( action )
	{
		return action != null && (this.vibration || !this.getActionFlag(action, "flagShake", false));
	}

	function calcTransitionSpeed( option = null )
	{
		switch(option)
		{
		case "env":
		case "stage":
		case "cut":
			return this.eventSpeed;

		case "chlayer":
			return this.charaSpeed;
		}

		return 1.0;
	}

	function calcActionSpeed( option = null )
	{
		switch(option)
		{
		case "stage":
		case "cut":
			return this.eventSpeedMag;

		case "chlayer":
			return this.charaSpeedMag;
		}

		return 1.0;
	}

	function createSaveText( disp, text )
	{
		return text;
	}

	function onPlayMode( playMode, prevPlayMode, user = false )
	{
		if (playMode == prevPlayMode)
		{
			return;
		}

		if (this.autoskip != null)
		{
			switch(playMode)
			{
			case 0:
				if (prevPlayMode == 1)
				{
					this.autoskip.play("hide", 1);
				}
				else
				{
					this.autoskip.play("hide", 1);
				}

				break;

			case 1:
				this.autoskip.setVariable("class", 0);
				this.autoskip.visible = true;
				this.autoskip.play("show", 1);
				break;

			case 2:
				this.autoskip.setVariable("class", 1);
				this.autoskip.visible = true;
				this.autoskip.play("show", 1);
				break;

			case 3:
				this.autoskip.setVariable("class", 1);
				this.autoskip.visible = true;
				this.autoskip.play("show", 1);
				break;
			}
		}

		this.updateMsgWait();
	}

	dateinfo = null;
	placeinfo = null;
	function tag_showdate( elm )
	{
		local date = ::getval(elm, "date");

		if (this.dateinfo != null)
		{
			this.dateinfo.stop();
			this.dateinfo = null;
		}

		if (date != null && date != "")
		{
			this.dateinfo = this.createInfoPanel({
				chara = "DATEWIN",
				n_text = date
			});
		}
	}

	function tag_showplace( elm )
	{
		local place = ::getval(elm, "place");

		if (this.placeinfo != null)
		{
			this.placeinfo.stop();
			this.placeinfo = null;
		}

		if (place != null && place != "")
		{
			this.placeinfo = this.createInfoPanel({
				chara = "PLACEWIN",
				n_text = place
			});
		}
	}

	function tag_showhp( elm, fast = false )
	{
		local hp = 3 - this.f.failure_num;
		this.printf("showhp:%s:%s\n", this.hppanel, hp);

		if ("visible" in elm)
		{
			if (this.getint(elm, "visible"))
			{
				if (this.hppanel == null)
				{
					this.hppanel = ::Motion(this.infobase);
					this.hppanel.chara = "HP";
					this.hppanel.visible = true;
				}

				this.hppanel.setVariable("hp3::miss", hp > 0 ? 0 : 2);
				this.hppanel.setVariable("hp2::miss", hp > 1 ? 0 : 2);
				this.hppanel.setVariable("hp1::miss", hp > 2 ? 0 : 2);
				this.hppanel.play(fast ? "normal" : "show", 1);
				this.hpvalue = hp;
			}
			else if (this.hppanel != null)
			{
				if (!fast)
				{
					this.hppanel.setVariable("hp3::miss", hp > 0 ? 0 : 2);
					this.hppanel.setVariable("hp2::miss", hp > 1 ? 0 : 2);
					this.hppanel.setVariable("hp1::miss", hp > 2 ? 0 : 2);
					this.hppanel.play("hide", 1);

					while (this.hppanel.playing)
					{
						this.sync();
					}
				}

				this.hppanel.visible = false;
				this.hppanel = null;
			}
		}
		else if (this.hppanel)
		{
			if (this.hpvalue != hp)
			{
				this.hppanel.setVariable("hp3::miss", hp > 0 ? 3 : this.hpvalue > 0 ? 1 : 2, 1);
				this.hppanel.setVariable("hp2::miss", hp > 1 ? 3 : this.hpvalue > 1 ? 1 : 2, 1);
				this.hppanel.setVariable("hp1::miss", hp > 2 ? 3 : this.hpvalue > 2 ? 1 : 2, 1);
				this.hpvalue = hp;
			}
		}
	}

	function onRestore( obj )
	{
		if ("showhp" in obj)
		{
			this.tag_showhp({
				visible = obj.showhp
			}, true);
		}
	}

	function tag_dialog( elm )
	{
		if ("text" in elm)
		{
			this.printf("dialog:%s\n", elm.text);

			if ("se" in elm)
			{
				this.sysse.play("ok");
			}

			::inform(elm.text);
			this.autoStartTick = null;
		}
	}

	function tag_pnresult( elm )
	{
		this.sysvPlay(32);
		this.openMenuPanel([
			"motion/pnresult.psb",
			"motion/particle.psb"
		], {
			chara = "PNTRESULT",
			motion = "show"
		}, this);
		this.autoStartTick = null;
	}

	function tag_sysvplay( elm )
	{
		if ("no" in elm)
		{
			this.sysvPlay(::toint(elm.no));
		}
	}

	function openSave()
	{
		this.openMenuPanel([
			"motion/saveload.psb",
			"motion/particle.psb"
		], {
			chara = "SAVE",
			state = 0
		}, ::MySaveLoadModeFunction(true));
	}

	function openHistory()
	{
		local func = ::HistoryModeFunction();
		func.HISTORY_CURSOR_COLOR = 4294291865;
		return this.openCommandPanel([
			"motion/backlog.psb",
			"motion/particle.psb"
		], "BACKLOG", func);
	}

	function cmdHistory( key )
	{
		this.sysvPlay(12);
		return ::ScenePlayer.cmdHistory(key);
	}

	function cmdCommand( key = null )
	{
		local coffee;

		switch(this.sceneMode)
		{
		case 2:
		case 1:
		case 3:
		case 4:
		case 5:
			coffee = 2;
			break;

		default:
			coffee = 0;
			break;
		}

		this.sysvPlay(14);
		this._cmdCommand(coffee);
	}

	function getScreenCapture()
	{
		local ret;
		local playerVisible = this.player.getVisible();
		this.player.setVisible(true);
		ret = ::ScenePlayer.getScreenCapture();
		this.player.setVisible(playerVisible);
		return ret;
	}

	function cmdManualEx( key = null )
	{
		this.player.setVisible(false);

		if (this.hppanel != null)
		{
			this.hppanel.visible = false;
		}

		this.cmdManual();
		this.player.setVisible(true);

		if (this.hppanel != null)
		{
			this.hppanel.visible = true;
		}
	}

	function _cmdCommand( coffee = 0 )
	{
		this.player.setVisible(false);

		if (this.hppanel != null)
		{
			this.hppanel.visible = false;
		}

		try
		{
			for( local arg; arg != "exit" && arg != "next";  )
			{
				arg = this.openCommandPanel([
					"motion/command.psb",
					"motion/particle.psb"
				], {
					chara = "COMMAND",
					coffee = coffee,
					focus = arg == null ? 0 : arg,
					fore = true
				}, ::CommandModeFunction());
				this.sync();

				switch(arg)
				{
				case "load":
					this.cmdLoad();
					break;

				case "save":
					this.cmdSave();
					break;

				case "config":
					this.cmdConfig();
					break;

				case "parameter":
					this.cmdParameter();
					break;

				case "manual":
					this.cmdManual();
					break;
				}
			}
		}
		catch( e )
		{
			this.player.setVisible(true);

			if (this.hppanel != null)
			{
				this.hppanel.visible = true;
			}

			throw e;
		}

		this.player.setVisible(true);

		if (this.hppanel != null)
		{
			this.hppanel.visible = true;
		}
	}

	function cmdConfig( ... )
	{
		local preDLC = this.enableDLC;
		this.setConfig("fullScreen", ::getFullScreen());
		this.setConfig("scaleMode", ::getScaleMode());
		this.openConfig();
		this.appStopVoice();

		if (preDLC != this.enableDLC)
		{
			this.interruptRedraw();
		}
	}

	trialTexts = [
		[
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e3\x0081\x00ad\x00e3\x0081\x0088\x00e3\x0081\x00ad\x00e3\x0081\x0088\x00e3\x0080\x0081\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093\x00e3\x0080\x0082\n\x00e7\x00a7\x0081\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e5\x00a4\x0089\x00e3\x0081\x00aa\x00e5\x008c\x0082\x00e3\x0081\x0084\x00e3\x0081\x008c\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x00ab\x00e3\x0080\x0081\x00e4\x00bc\x00bc\x00e5\x0090\x0088\x00e3\x0081\x0086\x00e3\x0081\x00a8\x00e6\x0080\x009d\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0081\x00a8\x00e3\x0081\x0084\x00e3\x0081\x0086\x00e3\x0081\x0093\x00e3\x0081\x00a8\x00e3\x0081\x00af\x00e3\x0080\x0081\n\x00e7\x00a7\x0081\x00e3\x0081\x008c\x00e3\x0081\x009d\x00e3\x0081\x00ae\x00e4\x00b8\x008b\x00e7\x009d\x0080\x00e3\x0082\x0092\x00e7\x009d\x0080\x00e3\x0081\x0091\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e5\x00a7\x00bf\x00e3\x0082\x0092\n\x00e6\x0083\x00b3\x00e5\x0083\x008f\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0081\x00a8\x00e8\x00a8\x0080\x00e3\x0081\x0086\x00e3\x0081\x0093\x00e3\x0081\x00a8\x00e3\x0081\x00a0\x00e3\x0082\x0088\x00e3\x0081\x00aa\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0081\x00ab\x00e3\x0082\x0088\x00e3\x0081\x0084\x00e7\x0094\x009f\x00e5\x009c\x00b0\x00e3\x0081\x00aa\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0080\x0081\n\x00e5\x0082\x00b7\x00e3\x0082\x0093\x00e3\x0081\x00a0\x00e3\x0082\x008a\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0082\x0082\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0081\x0084\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x00a7\x00e3\x0081\x0097\x00e3\x0082\x0087\x00e3\x0081\x0086\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00a6\x00e3\x0082\x00a3\x00e3\x0082\x00ba",
				text = "\x00e5\x0090\x008c\x00e3\x0081\x0098\x00e7\x00b4\x00a0\x00e6\x009d\x0090\x00e3\x0082\x0092\x00e4\x00bd\x00bf\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0083\x008f\x00e3\x0083\x00b3\x00e3\x0082\x00ab\x00e3\x0083\x0081\x00e3\x0081\x00af\x00e3\x0080\x0081\n\x00e3\x0081\x008a\x00e3\x0081\x009d\x00e3\x0082\x0089\x00e3\x0081\x008f\x00e6\x0095\x00b0\x00e5\x008d\x0083\x00e3\x0082\x00a8\x00e3\x0083\x00aa\x00e3\x0082\x00b9\x00e3\x0081\x0099\x00e3\x0082\x008b\x00e3\x0081\x00a8\x00e6\x0080\x009d\x00e3\x0081\x0086\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0080\x0082"
			}
		],
		[
			{
				name = "\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0082\x00e3\x0081\x00ae\x00e3\x0081\x0095\x00e3\x0080\x0081\x00e5\x0089\x008d\x00e3\x0082\x0082\x00e8\x00a8\x0080\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0081\x00a8\x00e6\x0080\x009d\x00e3\x0081\x0086\x00e3\x0081\x0091\x00e3\x0081\x00a9\x00e3\x0080\x0081\n\x00e3\x0081\x009d\x00e3\x0082\x0093\x00e3\x0081\x00aa\x00e3\x0081\x00b5\x00e3\x0081\x0086\x00e3\x0081\x00ab\x00e7\x009b\x0097\x00e3\x0082\x0089\x00e3\x0082\x008c\x00e3\x0081\x009f\x00e4\x00b8\x008b\x00e7\x009d\x0080\x00e3\x0082\x0092\x00e8\x00bf\x0094\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0082\x0082\x00e3\x0080\x0081\n\x00e3\x0081\x009f\x00e3\x0081\x00b6\x00e3\x0082\x0093\x00e3\x0081\x00bf\x00e3\x0082\x0093\x00e3\x0081\x00aa\x00e5\x009b\x00b0\x00e3\x0082\x008b\x00e3\x0081\x00a8\x00e6\x0080\x009d\x00e3\x0081\x0086\x00e3\x0082\x0093\x00e3\x0081\x00a0\x00e3\x0082\x0088\x00e3\x0081\x00ad\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0080\x0081\x00e6\x00b1\x00ba\x00e3\x0082\x0081\x00e3\x0081\x009f\x00e5\x00a0\x00b4\x00e6\x0089\x0080\x00e3\x0081\x00ab\x00e3\x0083\x0091\x00e3\x0083\x00b3\x00e3\x0083\x0084\x00e3\x0082\x0092\x00e7\x00bd\x00ae\x00e3\x0081\x0084\x00e3\x0081\x00a6\x00e3\x0080\x0081\n\x00e6\x008c\x0081\x00e3\x0081\x00a1\x00e4\x00b8\x00bb\x00e3\x0081\x008c\x00e3\x0081\x0093\x00e3\x0081\x00a3\x00e3\x0081\x009d\x00e3\x0082\x008a\x00e5\x009b\x009e\x00e5\x008f\x008e\x00e3\x0081\x0099\x00e3\x0082\x008b\x00e3\x0081\x00a8\x00e3\x0081\x0084\x00e3\x0081\x0086\x00e3\x0081\x00ae\x00e3\x0081\x008c\n\x00e3\x0082\x0082\x00e3\x0081\x00a3\x00e3\x0081\x00a8\x00e3\x0082\x0082\x00e5\x0090\x0088\x00e7\x0090\x0086\x00e7\x009a\x0084\x00e3\x0081\x00aa\x00e6\x0089\x008b\x00e6\x00ae\x00b5\x00e3\x0081\x00a0\x00e3\x0081\x00a8\x00e6\x0080\x009d\x00e3\x0081\x0086\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x009d\x00e3\x0081\x0086\x00e3\x0081\x00a0\x00e3\x0081\x00aa\x00e3\x0080\x0082\n\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x008c\x00e7\x00a7\x0081\x00e3\x0081\x00ab\x00e8\x00a6\x008b\x00e3\x0081\x009b\x00e3\x0082\x008b\x00e5\x0084\x00aa\x00e3\x0081\x0097\x00e3\x0081\x0095\x00e3\x0081\x00af\x00e3\x0081\x00b2\x00e3\x0081\x00a8\x00e5\x0091\x00b3\x00e3\x0082\x0082\x00e3\x0081\x00b5\x00e3\x0081\x009f\x00e5\x0091\x00b3\x00e3\x0082\x0082\x00e9\x0081\x0095\x00e3\x0081\x0086\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e4\x00bd\x0095\x00e3\x0082\x0092\x00e8\x00a8\x0080\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00ef\x00bc\x0081\n\x00e5\x00b9\x00b4\x00e7\x0094\x00b2\x00e6\x0096\x0090\x00e3\x0082\x0082\x00e7\x0084\x00a1\x00e3\x0081\x0084\x00e3\x0081\x0093\x00e3\x0082\x0093\x00e3\x0081\x00aa\x00e6\x00a0\x00bc\x00e5\x00a5\x00bd\x00e3\x0082\x0092\x00e7\x0094\x00b7\x00e5\x0085\x00b1\x00e3\x0081\x00ab\x00e6\x0099\x0092\x00e3\x0081\x0099\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a6\x00e3\x0080\x0081\n\x00e5\x00b1\x0088\x00e8\x00be\x00b1\x00e3\x0081\x00a7\x00e3\x0081\x0097\x00e3\x0081\x008b\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x00a0\x00e3\x0082\x008d\x00e3\x0081\x0086\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x00a7\x00e3\x0082\x0082\x00e3\x0080\x0081\x00e3\x0082\x0082\x00e3\x0081\x0097\x00e8\x00a6\x008b\x00e3\x0081\x0088\x00e3\x0081\x00a1\x00e3\x0082\x0083\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0080\x0081\n\x00e8\x00b2\x00ac\x00e4\x00bb\x00bb\x00e3\x0081\x00af\x00e5\x008f\x0096\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0082\x0082\x00e3\x0082\x0089\x00e3\x0081\x0086\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00ad\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0082\x00a6\x00e3\x0082\x00a3\x00e3\x0082\x00ba",
				text = "\x00e3\x0081\x0088\x00e3\x0080\x0081\x00e3\x0081\x0088\x00e3\x0081\x0088\x00e3\x0081\x00a8\x00e3\x0080\x0081\x00e3\x0081\x0082\x00e3\x0081\x00ae\x00e3\x0080\x0081\x00e3\x0081\x0094\x00e4\x00b8\x00bb\x00e4\x00ba\x00ba\x00e6\x00a7\x0098\x00ef\x00bc\x009f\n\x00e3\x0081\x008a\x00e6\x0096\x0099\x00e7\x0090\x0086\x00e3\x0082\x0092\x00e5\x0086\x00b7\x00e3\x0081\x00be\x00e3\x0081\x0099\x00e6\x0089\x008b\x00e4\x00bc\x009d\x00e3\x0081\x0084\x00e3\x0082\x0092\x00e3\x0081\x0095\x00e3\x0081\x009b\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x009f\x00e3\x0081\x00a0\x00e3\x0081\x0084\x00e3\x0081\x00a6\x00e3\x0082\x0082\n\x00e3\x0082\x0088\x00e3\x0082\x008d\x00e3\x0081\x0097\x00e3\x0081\x0084\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0081\x00ab\x00e3\x0080\x0081\x00e3\x0081\x0093\x00e3\x0081\x0093\x00e3\x0081\x00af\x00e9\x00a7\x0086\x00e3\x0081\x0091\x00e5\x0087\x00ba\x00e3\x0081\x0097\x00e3\x0081\x00ae\x00e5\x0086\x0092\x00e9\x0099\x00ba\x00e8\x0080\x0085\x00e3\x0081\x009f\x00e3\x0081\x00a1\x00e3\x0081\x008c\x00e9\x009b\x0086\x00e3\x0081\x00be\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0082\x008b\n\x00e8\x00a1\x0097\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0082\x0088\x00ef\x00bc\x009f"
			}
		],
		[
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x0093\x00e3\x0081\x00aa\x00e8\x00ad\x00a6\x00e6\x0088\x0092\x00e3\x0081\x0097\x00e3\x0081\x00aa\x00e3\x0081\x008f\x00e3\x0081\x00a6\x00e3\x0082\x0082\x00e3\x0081\x0084\x00e3\x0081\x0084\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0082\x0088\x00e3\x0080\x0082\n\x00e3\x0082\x0082\x00e3\x0081\x0086\x00e6\x0080\x0092\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e8\x0085\x0090\x00e3\x0082\x008c\x00e3\x0082\x00a2\x00e3\x0083\x00b3\x00e3\x0083\x0087\x00e3\x0083\x0083\x00e3\x0083\x0089\x00e3\x0081\x008c\x00e3\x0081\x00a9\x00e3\x0081\x0086\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0081\x0093\x00e3\x0081\x0093\x00e3\x0081\x00ab\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0082\x0088\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00a6\x00e3\x0082\x00a3\x00e3\x0082\x00ba",
				text = "\x00e3\x0081\x0082\x00e3\x0080\x0081\x00e7\x00b5\x0090\x00e7\x0095\x008c\x00e3\x0081\x00a7\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0080\x0081\n\x00e5\x0085\x00a5\x00e3\x0082\x008b\x00e6\x0099\x0082\x00e3\x0081\x00ab\x00e3\x0081\x00a1\x00e3\x0082\x0087\x00e3\x0081\x00a3\x00e3\x0081\x00a8\x00e3\x0083\x0094\x00e3\x0083\x00aa\x00e3\x0083\x0083\x00e3\x0081\x00a8\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0081\x0091\x00e3\x0081\x00a9\x00e2\x0080\x0095\x00e2\x0080\x0095"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e6\x00af\x008e\x00e6\x009c\x0088\x00e5\x00af\x009d\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e3\x0082\x0092\x00e8\x00a5\x00b2\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0082\x008b\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x00ab\x00e8\x00a8\x0080\x00e3\x0082\x008f\x00e3\x0082\x008c\x00e3\x0081\x009f\x00e3\x0081\x008f\n\x00e3\x0081\x0082\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x00be\x00e3\x0081\x009f\x00e3\x0081\x008a\x00e3\x0081\x008b\x00e3\x0081\x0097\x00e3\x0081\x00aa\x00e3\x0081\x0093\x00e3\x0081\x00a8\x00e3\x0081\x00ab\n\x00e6\x0089\x008b\x00e3\x0082\x0092\x00e5\x0087\x00ba\x00e3\x0081\x0099\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x00af\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x00a0\x00e3\x0082\x008d\x00e3\x0081\x0086\x00e3\x0081\x00aa\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2\x00e3\x0080\x0081\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093\x00e3\x0080\x0081\n\x00e3\x0081\x009d\x00e3\x0081\x0086\x00e8\x00a8\x0080\x00e3\x0082\x008f\x00e3\x0081\x009a\x00e3\x0081\x00ab\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x00ab\x00e5\x008d\x0094\x00e5\x008a\x009b\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0082\x0084\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0081\x00a9\x00e3\x0081\x0086\x00e3\x0081\x00a0\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0082\x00e3\x0081\x0082\x00e3\x0080\x0082\x00e3\x0081\x0084\x00e3\x0081\x00a4\x00e3\x0081\x00be\x00e3\x0081\x00a7\x00e3\x0082\x0082\x00e3\x0080\x0081\x00e3\x0081\x009d\x00e3\x0081\x00ae\x00e3\x0081\x008f\x00e3\x0081\x00a0\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e6\x008c\x0087\x00e8\x00bc\x00aa\x00e3\x0081\x00ab\n\x00e6\x008c\x00af\x00e3\x0082\x008a\x00e5\x009b\x009e\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0081\x00af\x00e5\x00be\x00a1\x00e5\x0085\x008d\x00e3\x0081\x00a0\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0081\x00ab\x00e3\x0080\x0081\x00e4\x00bb\x008a\x00e3\x0081\x00ae\x00e7\x008a\x00b6\x00e6\x0085\x008b\x00e3\x0081\x00a7\x00e8\x00a1\x0086\x00e4\x00ba\x00ba\x00e3\x0081\x00ae\x00e5\x0089\x008d\x00e3\x0081\x00ab\x00e3\x0081\x0093\x00e3\x0081\x00ae\x00e8\x00ba\x00ab\x00e3\x0082\x0092\x00e6\x0099\x0092\x00e3\x0081\x0099\n\x00e3\x0081\x00a8\x00e3\x0081\x0084\x00e3\x0081\x0086\x00e3\x0081\x00ae\x00e3\x0082\x0082\x00e3\x0081\x00aa\x00e3\x0081\x008b\x00e3\x0081\x00aa\x00e3\x0081\x008b\x00e2\x0080\x00a6\x00e2\x0080\x00a6\x00e3\x0080\x0082"
			}
		],
		[
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x009d\x00e3\x0081\x0086\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0082\x0088\x00e3\x0080\x0082\n\x00e3\x0081\x0093\x00e3\x0081\x00a3\x00e3\x0081\x00a1\x00e3\x0081\x00af\x00e8\x0090\x00bd\x00e3\x0081\x00a8\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0082\x0082\x00e8\x0090\x00bd\x00e3\x0081\x00a8\x00e3\x0081\x009b\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e6\x0086\x0091\x00e3\x0081\x008d\x00e7\x0089\x00a9\x00e3\x0082\x0092\n\x00e6\x008a\x00b1\x00e3\x0081\x0088\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00ad\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e7\x00a7\x0081\x00e3\x0080\x0081\x00e6\x009c\x009d\x00e8\x00b5\x00b7\x00e3\x0081\x008d\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0083\x0091\x00e3\x0083\x00b3\x00e3\x0083\x0084\x00e3\x0082\x0092\x00e3\x0081\x00af\x00e3\x0081\x0084\x00e3\x0081\x00a6\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a6\x00e3\x0080\x0081\n\x00e6\x0081\x00a5\x00e3\x0081\x009a\x00e3\x0081\x008b\x00e3\x0081\x0097\x00e3\x0081\x008f\x00e3\x0081\x00a6\x00e8\x0080\x0090\x00e3\x0081\x0088\x00e3\x0082\x0089\x00e3\x0082\x008c\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e3\x0082\x0082\x00e3\x0081\x0086\x00e2\x0080\x00a6\x00e2\x0080\x00a6\x00e6\x008c\x0087\x00e8\x00bc\x00aa\x00e3\x0082\x0082\x00e3\x0082\x008d\x00e3\x0081\x00a8\x00e3\x0082\x0082\n\x00e7\x0081\x00ab\x00e5\x008f\x00a3\x00e3\x0081\x00ab\x00e6\x0094\x00be\x00e3\x0082\x008a\x00e8\x00be\x00bc\x00e3\x0082\x0093\x00e3\x0081\x0098\x00e3\x0082\x0083\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\x00e3\x0081\x008b\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0084\x00e3\x0080\x0081\x00e3\x0081\x0084\x00e3\x0082\x0084\x00e3\x0080\x0081\x00e4\x00bb\x008a\x00e6\x0097\x00a5\x00e3\x0081\x00af\x00e5\x0086\x00b7\x00e3\x0081\x0088\x00e3\x0082\x008b\x00e3\x0081\x00aa\x00e3\x0081\x00a8\x00e3\x0080\x0082\n\x00e7\x0089\x00b9\x00e3\x0081\x00ab\x00e8\x0085\x00b0\x00e3\x0081\x00ae\x00e3\x0081\x0082\x00e3\x0081\x009f\x00e3\x0082\x008a\x00e3\x0081\x008c\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x00a8\x00e3\x0081\x00ab\x00e3\x0081\x008b\x00e3\x0081\x008f\x00e4\x00bb\x008a\x00e3\x0081\x00af\x00e9\x0083\x00bd\x00e5\x0090\x0088\x00e3\x0081\x008c\x00e6\x0082\x00aa\x00e3\x0081\x0084\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00ef\x00bc\x0081\n\x00e3\x0082\x0084\x00e3\x0082\x008b\x00e3\x0081\x00aa\x00e3\x0082\x0089\x00e3\x0080\x0081\x00e3\x0081\x009d\x00e3\x0081\x0086\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x00ad\x00e3\x0080\x0081\n\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00ab\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0081\x008f\x00e3\x0081\x00a0\x00e3\x0081\x0095\x00e3\x0081\x0084\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x00a0\x00e3\x0080\x0081\x00e3\x0081\x00a0\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0080\x0081\x00e6\x008e\x00a1\x00e5\x00af\x00b8\x00e3\x0082\x0092\x00e3\x0081\x0099\x00e3\x0082\x008b\x00e3\x0081\x00a8\x00e8\x00a8\x0080\x00e3\x0081\x0086\x00e3\x0081\x0093\x00e3\x0081\x00a8\x00e3\x0081\x00af\n\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x0095\x00e3\x0082\x0093\x00e3\x0081\x008c\x00e8\x00bf\x0091\x00e3\x0081\x00a5\x00e3\x0081\x008f\x00e3\x0081\x00a8\x00e8\x00a8\x0080\x00e3\x0081\x0086\x00e3\x0081\x0093\x00e3\x0081\x00a8\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0082\x0088\x00e3\x0081\x00ad\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e3\x0081\x00b8\x00e3\x0081\x008d\x00e3\x0081\x0097\x00e3\x0081\x00a3\x00ef\x00bc\x0081\x00ef\x00bc\x0081\x00e3\x0080\x0080\x00e3\x0081\x0086\x00e3\x0083\x00bc\x00e3\x0081\x00a3\x00e3\x0080\x0081\n\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a0\x00e3\x0081\x008c\x00e8\x00ba\x00ab\x00e4\x00bd\x0093\x00e3\x0081\x008c\x00e5\x0086\x00b7\x00e3\x0081\x0088\x00e3\x0081\x00a6\x00e3\x0081\x008d\x00e3\x0081\x00a1\x00e3\x0082\x0083\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0081\x00bf\x00e3\x0081\x009f\x00e3\x0081\x0084\x00e3\x0080\x0082\n\x00e7\x00a7\x0081\x00e3\x0082\x0082\x00e6\x0088\x00bb\x00e3\x0082\x008d\x00e3\x0081\x00a3\x00e3\x0081\x00a8\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0084\x00e3\x0082\x0084\x00e3\x0080\x0081\x00e7\x00a7\x0081\x00e3\x0081\x00af\x00e3\x0081\x0093\x00e3\x0081\x0093\x00e3\x0081\x00ab\x00e6\x00ae\x008b\x00e3\x0082\x008b\x00e3\x0080\x0082\n\x00e3\x0081\x009d\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0081\x009c\x00e3\x0081\x00b2\x00e3\x0080\x0081\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x00ab\x00e3\x0082\x0082\x00e6\x00ae\x008b\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e6\x00ac\x00b2\x00e3\x0081\x0097\x00e3\x0081\x0084\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x00bb\x00e3\x0080\x0081\x00e6\x0094\x00be\x00e7\x00bd\x00ae\x00e3\x0083\x0097\x00e3\x0083\x00ac\x00e3\x0082\x00a4\x00e3\x0081\x008b\x00e3\x0080\x0082\n\x00e3\x0081\x009d\x00e3\x0081\x0086\x00e3\x0081\x0084\x00e3\x0081\x0086\x00e6\x0089\x00b1\x00e3\x0081\x0084\x00e3\x0082\x0082\x00e5\x00ab\x008c\x00e3\x0081\x0084\x00e3\x0081\x00a7\x00e3\x0081\x00af\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x009e\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e",
				text = "\x00e3\x0081\x009d\x00e3\x0081\x00ae\x00e3\x0082\x008f\x00e3\x0082\x008a\x00e3\x0081\x00ab\x00e3\x0080\x0081\x00e3\x0081\x0095\x00e3\x0081\x00a3\x00e3\x0081\x008d\x00e3\x0081\x00a8\x00e5\x0085\x00a8\x00e7\x0084\x00b6\x00e5\x00a4\x0089\x00e3\x0082\x008f\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x0098\x00e3\x0082\x0083\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x008b\x00e3\x0080\x0082\n\x00e3\x0083\x00a2\x00e3\x0082\x00b8\x00e3\x0083\x00a2\x00e3\x0082\x00b8\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0080\x0081\x00e5\x008b\x0095\x00e3\x0081\x008d\x00e3\x0081\x008c\x00e3\x0081\x008e\x00e3\x0081\x0093\x00e3\x0081\x00a1\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x009e\x00e3\x0080\x0082"
			}
		],
		[
			{
				name = "\x00e3\x0083\x0090\x00e3\x0083\x008b\x00e3\x0083\x00ab",
				text = "\x00e3\x0081\x0093\x00e3\x0081\x00ae\x00e5\x00ba\x0097\x00e3\x0082\x0082\x00e3\x0080\x0081\x00e6\x00b3\x00a5\x00e6\x00a3\x0092\x00e3\x0081\x00ab\x00e6\x00b0\x0097\x00e3\x0082\x0092\x00e3\x0081\x00a4\x00e3\x0081\x0091\x00e3\x0081\x009f\x00e3\x0081\x00bb\x00e3\x0081\x0086\x00e3\x0081\x008c\n\x00e3\x0081\x0084\x00e3\x0081\x0084\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x00af\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x008b\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x00ab\x00e3\x0083\x008a",
				text = "\x00e3\x0081\x00aa\x00e3\x0080\x0081\x00e3\x0081\x00aa\x00e3\x0082\x008b\x00e3\x0081\x00bb\x00e3\x0081\x00a9\x00e3\x0080\x0082\n\x00e3\x0081\x00a0\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e2\x0080\x00a6\x00e2\x0080\x00a6\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x00ad\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0081\x00a7\x00e5\x008f\x0096\x00e3\x0082\x008a\x00e5\x0088\x0086\x00e3\x0082\x0092\x00e8\x00a6\x0081\x00e6\x00b1\x0082\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0080\x0081\n\x00e7\x00a7\x0081\x00e3\x0081\x00ae\x00e5\x0088\x0086\x00e3\x0081\x008c\x00e6\x00b8\x009b\x00e3\x0081\x00a3\x00e3\x0081\x00a1\x00e3\x0082\x0083\x00e3\x0081\x0086\x00e3\x0082\x008f\x00ef\x00bc\x0081\n\x00e7\x00b5\x00b6\x00e5\x00af\x00be\x00e3\x0081\x00ab\x00e5\x00ab\x008c\x00e3\x0082\x0088\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e3\x0081\x00ad\x00e3\x0081\x0088\x00e3\x0080\x0081\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00ef\x00bc\x009f\n\x00e3\x0081\x0082\x00e3\x0082\x0093\x00e3\x0081\x009f\x00e3\x0080\x0081\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9\x00e3\x0081\x00ab\x00e4\x00bd\x0095\x00e3\x0081\x008b\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0081\x00ae\x00ef\x00bc\x009f\n\x00e5\x00a6\x0099\x00e3\x0081\x00ab\x00e4\x00b8\x008d\x00e6\x00a9\x009f\x00e5\x00ab\x008c\x00e3\x0081\x0098\x00e3\x0082\x0083\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x00b5\x00e3\x0080\x0081\x00ef\x00bc\x0092\x00e4\x00ba\x00ba\x00e3\x0081\x008d\x00e3\x0082\x008a\x00e3\x0081\x00a7\x00ef\x00bc\x0081\x00ef\x00bc\x009f\n\x00e7\x0084\x00a1\x00e7\x0090\x0086\x00ef\x00bc\x0081\x00e3\x0080\x0080\x00e7\x00b5\x00b6\x00e5\x00af\x00be\x00e3\x0081\x00ab\x00e7\x0084\x00a1\x00e7\x0090\x0086\x00ef\x00bc\x0081\x00e3\x0080\x0080\x00e5\x00bc\x0095\x00e3\x0081\x008d\x00e5\x008f\x0097\x00e3\x0081\x0091\x00e3\x0081\x00aa\x00e3\x0081\x0084\x00e3\x0081\x008b\x00e3\x0082\x0089\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x00a9\x00e3\x0081\x0086\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00e3\x0080\x0081\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0080\x0082\n\x00e3\x0081\x00aa\x00e3\x0081\x009c\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0082\x0092\x00e8\x00a6\x008b\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0082\x0088\x00e3\x0082\x008a\x00e3\x0082\x0082\x00e6\x0098\x008e\x00e6\x0097\x00a5\x00e3\x0081\x00ae\x00e6\x00ba\x0096\x00e5\x0082\x0099\x00e3\x0082\x0092\x00e9\x0080\x00b2\x00e3\x0082\x0081\x00e3\x0082\x0088\x00e3\x0081\x0086\x00e3\x0080\x0082\n\x00e6\x00b4\x009e\x00e7\x00aa\x009f\x00e3\x0081\x00be\x00e3\x0081\x00a7\x00e8\x00a1\x008c\x00e3\x0081\x008f\x00e3\x0082\x0093\x00e3\x0081\x00a0\x00e3\x0080\x0081\x00e6\x0090\x00ba\x00e5\x00b8\x00af\x00e9\x00a3\x009f\x00e3\x0081\x00aa\x00e3\x0081\x00a9\x00e3\x0082\x0082\x00e5\x00bf\x0085\x00e8\x00a6\x0081\x00e3\x0081\x00a0\x00e3\x0082\x008d\x00e3\x0081\x0086\x00ef\x00bc\x009f"
			}
		],
		[
			{
				name = "\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2",
				text = "\x00e7\x00a2\x00ba\x00e3\x0081\x008b\x00e3\x0081\x00ab\x00e3\x0082\x00ab\x00e3\x0082\x00ba\x00e3\x0083\x009e\x00e3\x0081\x00af\x00e3\x0080\x0081\n\x00e5\x00a4\x0089\x00e6\x0085\x008b\x00e3\x0081\x00a7\x00e3\x0083\x0098\x00e3\x0082\x00bf\x00e3\x0083\x00ac\x00e3\x0081\x00a7\x00e3\x0082\x00af\x00e3\x0082\x00ba\x00e3\x0081\x00a7\x00e3\x0083\x0092\x00e3\x0082\x00ad\x00e3\x0083\x008b\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0081\x00aa\n\x00e9\x00a7\x0084\x00e7\x009b\x00ae\x00e4\x00ba\x00ba\x00e9\x0096\x0093\x00e3\x0081\x00a0\x00e3\x0081\x0091\x00e3\x0081\x00a9\x00e2\x0080\x0095\x00e2\x0080\x0095"
			},
			{
				name = "\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x00a0\x00e3\x0080\x0081\x00e3\x0081\x00a0\x00e3\x0080\x0081\x00e3\x0081\x00a0\x00e3\x0081\x00a3\x00e3\x0081\x009f\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x0081\x00ef\x00bc\x009f\n\x00e3\x0081\x00be\x00e3\x0081\x0095\x00e3\x0081\x008b\x00e9\x00bb\x0092\x00e3\x0081\x008c\x00e5\x00a5\x00bd\x00e3\x0081\x008d\x00e3\x0081\x00a0\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0080\x0081\x00e3\x0081\x0084\x00e3\x0081\x00a4\x00e3\x0082\x0082\x00e9\x00bb\x0092\x00e3\x0081\x0084\x00e3\x0081\x00ae\x00e3\x0082\x0092\n\x00e8\x00ba\x00ab\x00e3\x0081\x00ab\x00e3\x0081\x00a4\x00e3\x0081\x0091\x00e3\x0081\x00a6\x00e3\x0082\x008b\x00e3\x0081\x00a8\x00e3\x0081\x00a7\x00e3\x0082\x0082\x00e6\x0080\x009d\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0082\x008b\x00e3\x0082\x0093\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e9\x009d\x0092\x00e3\x0081\x0084\x00e3\x0083\x00aa\x00e3\x0083\x009c\x00e3\x0083\x00b3\x00ef\x00bc\x0081\x00ef\x00bc\x009f\n\x00e3\x0081\x00a9\x00e3\x0080\x0081\x00e3\x0081\x00a9\x00e3\x0081\x0086\x00e3\x0081\x0097\x00e3\x0081\x00a6\x00e3\x0081\x009d\x00e3\x0082\x008c\x00e3\x0082\x0092\x00e3\x0081\x00a3\x00ef\x00bc\x0081\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0093\x00e3\x0080\x0081\x00e3\x0081\x0093\x00e3\x0082\x008c\x00e3\x0081\x00af\x00e3\x0082\x0082\x00e3\x0081\x0097\x00e3\x0082\x0084\x00e7\x00a7\x0081\x00e3\x0082\x0092\x00e8\x00be\x00b1\x00e3\x0082\x0081\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0081\x008b\x00ef\x00bc\x009f\n\x00e3\x0081\x00b2\x00e3\x0082\x0089\x00e3\x0081\x00b2\x00e3\x0082\x0089\x00e3\x0081\x00a7\x00e3\x0083\x0094\x00e3\x0083\x00b3\x00e3\x0082\x00af\x00e3\x0081\x00a8\x00e3\x0081\x008b\x00e2\x0080\x00a6\x00e2\x0080\x00a6\x00e8\x00a8\x0080\x00e3\x0081\x0086\x00e6\x00b0\x0097\x00e3\x0081\x008b\x00ef\x00bc\x0081\x00ef\x00bc\x009f"
			},
			{
				name = "\x00e3\x0083\x0090\x00e3\x0083\x008b\x00e3\x0083\x00ab",
				text = "\x00e9\x00bb\x0092\x00e9\x00ad\x0094\x00e8\x00a1\x0093\x00e3\x0081\x00ab\x00e8\x0088\x0088\x00e5\x0091\x00b3\x00e3\x0081\x008c\x00e3\x0081\x0082\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0081\x008b\x00ef\x00bc\x009f\n\x00e5\x00ad\x00a4\x00e7\x008b\x00ac\x00e3\x0081\x00ab\x00e6\x0084\x009b\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0082\x008b\x00e5\x00a8\x0098\x00e3\x0082\x0088\x00e3\x0080\x0082"
			},
			{
				name = "\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093",
				text = "\x00e3\x0081\x0097\x00e3\x0080\x0081\x00e4\x00b8\x008b\x00e7\x009d\x0080\x00e6\x00b3\x00a5\x00e6\x00a3\x0092\x00e3\x0081\x00af\x00e7\x008a\x00af\x00e7\x00bd\x00aa\x00e3\x0081\x00a7\x00e3\x0081\x0099\x00e3\x0082\x0088\x00e3\x0081\x00a3\x00ef\x00bc\x0081\n\x00e3\x0081\x0095\x00e3\x0081\x0095\x00e3\x0082\x0084\x00e3\x0081\x008b\x00e3\x0081\x00aa\x00e8\x00b6\x00a3\x00e5\x0091\x00b3\x00e3\x0081\x00aa\x00e3\x0082\x0093\x00e3\x0081\x008b\x00e3\x0081\x0098\x00e3\x0082\x0083\x00e3\x0081\x0082\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\x00e3\x0081\x00a3\x00ef\x00bc\x0081"
			},
			{
				name = "\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9",
				text = "\x00e3\x0081\x0093\x00e3\x0081\x0093\x00e3\x0081\x00af\x00e7\x00a7\x0081\x00e3\x0081\x00ab\x00e4\x00bb\x00bb\x00e3\x0081\x009b\x00e3\x0081\x00a6\x00e3\x0081\x008a\x00e3\x0081\x0091\x00ef\x00bc\x0081\n\x00e4\x00bb\x00b2\x00e9\x0096\x0093\x00e3\x0082\x0092\x00e5\x00ae\x0088\x00e3\x0082\x008b\x00e3\x0081\x00ae\x00e3\x0081\x008c\x00e3\x0082\x00af\x00e3\x0083\x00ab\x00e3\x0082\x00bb\x00e3\x0082\x00a4\x00e3\x0083\x0080\x00e3\x0083\x00bc\x00e3\x0081\x00ae\x00e5\x00bd\x00b9\x00e5\x0089\x00b2\x00e3\x0081\x00a0\x00ef\x00bc\x0081"
			}
		]
	];
	trialPants = [
		[
			0
		],
		[
			1
		],
		[
			2,
			3
		],
		[
			4,
			5,
			6
		],
		[
			7,
			8,
			9,
			10
		],
		[
			11,
			12,
			13,
			14,
			15
		]
	];
	function getTrustChara()
	{
		if (this.f.route >= 10)
		{
			return this.f.route - 9;
		}

		return 0;
	}

	function getTrustValue()
	{
		if (this.f.route >= 10)
		{
			local charaNameTable = [
				"dummy",
				"AQUA",
				"MEGUMIN",
				"DARKNESS",
				"WIZ",
				"CHRIS",
				"YUNYUN"
			];
			local charaName = this.format("trust_%s", charaNameTable[this.f.route - 9]);
			return this.f[charaName];
		}
	}

	function checkTestimony( no )
	{
		if (this.f.reserve01 > 0)
		{
			return this.f.reserve02 & no;
		}
		else
		{
			return this.f.testimony_num >= 7 || no == 2 && this.f.testimony_num >= 6;
		}
	}

	function cmdParameter( ... )
	{
		local trial = this.f.trial;
		local pants = this.trialPants[trial];
		local texts = this.trialTexts[trial];
		local bpages = [];
		local pantslist = [];
		local sellist = [];
		local context;
		local s = [
			"motion/parameter.psb",
			"motion/particle.psb"
		];
		local route;

		if (this.f.pants_possession > 0)
		{
			bpages.append(0);
			s.append("motion/parameter1.psb");

			for( local i = 0; i < this.f.pants_num; i++ )
			{
				pantslist.append(pants[i]);
			}

			route = this.f.trial;
		}

		context = ::PantsSelectFunction(pantslist, route);

		if (this.f.testimony_num > 0)
		{
			bpages.append(1);
			s.append("motion/parameter2.psb");

			if (trial == 1)
			{
				local num = 0;
				local ok2 = false;
				local ok5 = false;

				if (this.f.reserve01 > 0)
				{
					num = this.f.reserve01;
					ok2 = this.f.reserve02 & 1;
					ok5 = this.f.reserve02 & 2;
				}
				else
				{
					if (this.f.pc >= 339)
					{
						num = 7;
					}
					else if (this.f.pc >= 337)
					{
						num = 6;
					}
					else if (this.f.pc >= 334)
					{
						num = 5;
					}
					else if (this.f.pc >= 329)
					{
						num = 3;
					}
					else if (this.f.pc >= 321)
					{
						num = 2;
					}

					if (this.f.testimony_num > num)
					{
						num = this.f.testimony_num;
					}

					ok2 = this.f.testimony_num >= num;
					ok5 = this.f.testimony_num >= num || !ok2 && this.f.testimony_num >= num - 1;
					this.f.reserve01 = num;

					if (ok2)
					{
						this.f.reserve02 = this.f.reserve02 | 1;
					}

					if (ok5)
					{
						this.f.reserve02 = this.f.reserve02 | 2;
					}
				}

				for( local i = 0; i < num; i++ )
				{
					if (!(i == 2 && !ok2 || i == 5 && !ok5))
					{
						sellist.append(texts[i]);
					}
				}
			}
			else
			{
				for( local i = 0; i < this.f.testimony_num; i++ )
				{
					sellist.append(texts[i]);
				}
			}

			context = ::ParameterFunction(context, sellist);
		}

		if (this.f.route >= 10)
		{
			bpages.append(3);
			s.append("motion/parameter4.psb");
		}
		else
		{
			bpages.append(2);
			s.append("motion/parameter3.psb");
		}

		local charaname = this.format("PARAMATER%s", bpages[0] + 1);
		this.openCommandPanel(s, {
			chara = charaname,
			bpages = bpages
		}, context);
	}

	function cmdQuickSave( ... )
	{
		this.sysvPlay(18);

		if (!this.CONFIRM_QSAVE || this.confirm("YESNO_QSAVE", "no"))
		{
			this.doQuickSave(this.getSaveData(), this.getSaveScreenCapture(), false);
			::inform("%C\x00e3\x0082\x00af\x00e3\x0082\x00a4\x00e3\x0083\x0083\x00e3\x0082\x00af\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0083\x0096\x00e3\x0081\x008c\x00e5\x00ae\x008c\x00e4\x00ba\x0086\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0080\x0082");
			this.autoStartTick = null;
		}
	}

	function cmdQuickLoad( ... )
	{
		this.sysvPlay(19);
		return ::ScenePlayer.cmdQuickLoad();
	}

	function cmdManual( ... )
	{
		this.openManual();
	}

	function getSaveInfo( info )
	{
		if (info == null)
		{
			return "\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0083\x0096\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093";
		}

		local title = info.title;
		local date = this.format("%02d/%02d/%02d", info.year % 100, info.mon, info.mday);
		local time = this.format("%02d:%02d", info.hour, info.min);
		local playtime = info.playTime;
		local hour = playtime / 3600;
		playtime -= hour * 3600;
		local min = playtime / 60;
		local sec = playtime % 60;
		playtime = this.format("%02d:%02d:%02d", hour, min, sec);
		return this.format("%s\n%s %s\n\x00e3\x0083\x0097\x00e3\x0083\x00ac\x00e3\x0082\x00a4\x00e6\x0099\x0082\x00e9\x0096\x0093 %s", title, date, time, playtime);
	}

	function getQuickSaveInfo()
	{
		return this.getSaveInfo(this.doQuickLoad());
	}

	function getAutoSaveInfo()
	{
		return this.getSaveInfo(this.doAutoLoad(null, true));
	}

	function choiceSelect( list, info )
	{
		if ("type" in info)
		{
			local pntch = {
				pntchara = 0,
				gohoubi = 1,
				oshioki = 2,
				chara = 3
			};

			if (info.type in pntch)
			{
				this.sysvPlay(25);
				return {
					type = info.type,
					storage = [
						"motion/pntchselect.psb",
						"motion/particle.psb"
					],
					chara = {
						chara = this.format("CHARA%d", list.len()),
						title = pntch[info.type]
					},
					canHide = false
				};
			}
			else if (info.type == "pants")
			{
				this.sysvPlay(23);
				local storage = [
					"motion/pntreturn.psb",
					"motion/particle.psb"
				];
				return {
					type = info.type,
					storage = storage,
					chara = {
						chara = "PNTRETURN",
						route = ::getint(info, "route", 0)
					},
					canHide = false
				};
			}
			else if (info.type == "testify")
			{
				local sels = [];

				foreach( sel in list )
				{
					local eval = this.getval(sel, "eval");

					if (eval == null || this.eval(eval))
					{
						sels.append(sel);
					}
				}

				local title = ::getint(info, "title", 0);
				this.printf("\x00e8\x00a8\x00bc\x00e8\x00a8\x0080\x00e9\x0081\x00b8\x00e6\x008a\x009e:%s\n", title);

				switch(title)
				{
				case 0:
					this.sysvPlay(26);
					break;

				case 1:
					break;

				case 2:
					this.sysvPlay(24);
					break;
				}

				return {
					type = info.type,
					storage = [
						"motion/testify.psb",
						"motion/particle.psb"
					],
					chara = "TESTIFY",
					canHide = false,
					context = ::TestifySelectFunction(sels, title)
				};
			}
			else if (info.type == "testifyadd")
			{
				return {
					type = info.type,
					storage = [
						"motion/testify.psb",
						"motion/particle.psb"
					],
					chara = "TESTIFY",
					canHide = false,
					context = ::TestifySelectFunction(list, this.title, true)
				};
			}
			else if (info.type == "minigame")
			{
				return {
					type = info.type,
					storage = [
						"motion/minigame.psb"
					],
					chara = "MINIGAME",
					canHide = false,
					canCommand = false,
					context = ::MiniGameFunction1(info, this.input)
				};
			}
			else if (info.type == "minigame2")
			{
				return {
					type = info.type,
					storage = [
						"motion/minigame.psb"
					],
					chara = "MINIGAME",
					canHide = false,
					canCommand = false,
					context = ::MiniGameFunction2(info, this.input)
				};
			}
			else if (info.type == "coffee")
			{
				this.stopAllVoice();
				this.playBGM(this.TITLEBGM);
				this.sysvPlay(15);
				this._cmdCommand(1);
				this.stopBGM(500);
				this.clearCapture();
				return null;
			}
		}

		local ret = ::ScenePlayer.choiceSelect(list, info);
		ret.storage = [
			"motion/envselect.psb",
			"motion/particle.psb"
		];
		return ret;
	}

	function onSelectStart( selinfo, seltype )
	{
		if (!("type" in selinfo))
		{
			this.sysse.play("ok");
		}
	}

	function onSelectStop( info, type, motion )
	{
	}

	function getSaveData()
	{
		local ret = ::ScenePlayer.getSaveData();
		ret.route <- this.getval(ret.flags, "route", 0);
		ret.day <- this.getval(ret.flags, "day", 0);
		return ret;
	}

	function checkAllReaded( list )
	{
		foreach( scene in list )
		{
			if (scene != null && !this.isSceneAllReaded(scene + "*start"))
			{
				this.printf("\x00e3\x0081\x00bf\x00e3\x0081\x00a6\x00e3\x0081\x00aa\x00e3\x0081\x0084:%s\n", scene);
				return false;
			}
		}

		return true;
	}

	function getDebugInfo()
	{
		local text = "";
		text += this.format("route:%s day:%s state:%s\n", this.f.route, this.f.day, this.f.timestate);
		return text + ::ScenePlayer.getDebugInfo();
	}

	function addTes( n = 1, a = 0, b = 0 )
	{
		this.f.testimony_num += n;
		this.f.reserve01 += a;
		this.f.reserve02 += b;
	}

	function FuncLikePoint( name, point )
	{
		local charaNameTable = [
			"dummy",
			"AQUA",
			"MEGUMIN",
			"DARKNESS",
			"CHRIS",
			"WIZ",
			"YUNYUN"
		];
		local charaName = this.format("like_%s", charaNameTable[name]);
		local likeMax = 10;
		local likeMin = 0;

		if (name == 0)
		{
			return;
		}

		this.f[charaName] += point;
		this.f[charaName] = this.f[charaName] >= likeMax ? likeMax : this.f[charaName];
		this.f[charaName] = this.f[charaName] <= likeMin ? likeMin : this.f[charaName];
	}

	function FuncTrustPoint( name, point )
	{
		local charaNameTable = [
			"dummy",
			"AQUA",
			"MEGUMIN",
			"DARKNESS",
			"CHRIS",
			"WIZ",
			"YUNYUN"
		];
		local charaName = this.format("trust_%s", charaNameTable[name]);
		local trustMax = 10;
		local trustMin = 0;

		if (name == 0)
		{
			return;
		}

		this.f[charaName] += point;
		this.f[charaName] = this.f[charaName] >= trustMax ? trustMax : this.f[charaName];
		this.f[charaName] = this.f[charaName] <= trustMin ? trustMin : this.f[charaName];
	}

	function FuncFailureChk( num )
	{
		this.f.failure = 0;

		if (this.f.failure_num >= num)
		{
			this.f.failure = 1;
		}
	}

	function FuncHintChk()
	{
		this.f.hint0 = this.f.hint1 * this.f.hint2 * this.f.hint3 * this.f.hint4 * this.f.hint5;
	}

	function FuncChkTR04_03()
	{
		return this.f.sel_tr04_03_1 * this.f.sel_tr04_03_2 * this.f.sel_tr04_03_4 * this.f.sel_tr04_03_6;
	}

	function FuncRouteChk()
	{
		local like = [
			[
				this.f.like_AQUA,
				10
			],
			[
				this.f.like_MEGUMIN,
				11
			],
			[
				this.f.like_DARKNESS,
				12
			],
			[
				this.f.like_WIZ,
				13
			],
			[
				this.f.like_CHRIS,
				14
			],
			[
				this.f.like_YUNYUN,
				15
			]
		];
		local max = like[0][0];
		this.f.route = like[0][1];

		for( local i = 1; i < 6; i++ )
		{
			if (like[i][0] > max)
			{
				max = like[i][0];
				this.f.route = like[i][1];
			}
		}
	}

	function FuncChkEv022()
	{
		local ret;
		ret = this.sf.ev022 == 0 ? this.sf.clear_aqua_good * this.sf.clear_aqua_normal * this.sf.clear_megumin_good * this.sf.clear_megumin_normal * this.sf.clear_darkness_good * this.sf.clear_darkness_normal * this.sf.clear_wiz_good * this.sf.clear_wiz_normal * this.sf.clear_chris_good * this.sf.clear_chris_normal * this.sf.clear_yunyun_good * this.sf.clear_yunyun_normal : 0;
		return ret;
	}

}

function FuncChekSection1()
{
	if (this.f.trial_failure == 0 && this.f.failure_num == 0)
	{
		this.giveMedal("md13");
	}
}

function FuncChekSection2()
{
	if (this.f.trial_failure == 0 && this.f.failure_num == 0)
	{
		this.giveMedal("md14");
	}
}

function FuncChekSection3()
{
	if (this.f.trial_failure == 0 && this.f.failure_num == 0)
	{
		this.giveMedal("md15");
	}
}

function FuncChekSection4()
{
	if (this.f.trial_failure == 0 && this.f.failure_num == 0)
	{
		this.giveMedal("md16");
	}
}

function FuncChekSection5()
{
	if (this.f.trial_failure == 0 && this.f.failure_num == 0)
	{
		this.giveMedal("md17");
	}
}

function FuncChekTutorial()
{
	if (this.sf.adv_tutorial == 1 && this.sf.trial_tutorial == 1)
	{
		this.giveMedal("md21");
	}
}

this.voiceNames <- [
	"KZ",
	"AQ",
	"MG",
	"DS",
	"WZ",
	"CS",
	"YN",
	"VA"
];
this.voiceConfigs <- [
	"KAZUMA",
	"AQUA",
	"MEGUMIN",
	"DARKNESS",
	"WIZ",
	"CHRIS",
	"YUNYUN",
	"VANIR"
];
class this.MyApplication extends this.Application
{
	CROSSLOAD_THUMBNAIL_UPDATE = [
		[
			"new",
			"__over",
			"event"
		],
		{
			name = "__over",
			showmode = 1,
			redraw = {
				imageFile = "crosssave"
			},
			action = [
				[
					"zpos",
					-3000
				]
			]
		}
	];
	OPMOVIE = "OP";
	TITLEBGM = "BGM01";
	MOVIECANCELKEY = this.KEY_OK | 8;
	EXTRABGM = "BGM08";
	endTitleState = null;
	function sysvPlay( no, ch = -1 )
	{
		this.stopVoice();

		if (ch < 0)
		{
			ch = this.cf.systemVoice;
		}

		local name = this.voiceNames[ch];
		local conf = this.voiceConfigs[ch];
		local file = this.format("%sSY%04d", name, no);
		this.playVoice(conf, file);
	}

	function sysvCheck()
	{
		return this.voice == null || !this.voice.getPlaying();
	}

	constructor( init )
	{
		::Application.constructor(init);
		this.addGlobalVariable("dlc");
		::dlc <- 2;
		local n = this.getDlcNum();
		this.printf("dlc count:%s\n", n);

		for( local i = 0; i < n; i++ )
		{
			local name = this.getDlcInfoString(i, "name");
			this.printf("dlc info:%s\n", name);

			if (name == "dlc002")
			{
				this.dlc = this.dlc | 2;
			}
			else
			{
			}
		}

		this.initClearFlags();
	}

	dlcvalues = null;
	svoicevalues = null;
	function dlcInit()
	{
		this.dlcvalues = [
			0
		];

		for( local i = 0; i < 2; i++ )
		{
			if (this.dlc & 1 << i)
			{
				this.dlcvalues.append(i + 1);
			}
		}

		foreach( v in this.dlcvalues )
		{
			this.printf("dlcvalue:%s\n", v);
		}

		this.svoicevalues = [
			0
		];

		for( local i = 0; i < 6; i++ )
		{
			if (this.getClear(i))
			{
				this.svoicevalues.append(i + 1);
			}
		}

		this.svoicevalues.append(7);
	}

	function checkDLCDisable( no )
	{
		return no >= this.dlcvalues.len();
	}

	function checkDLCNo( no )
	{
		return this.checkDLCDisable(no) ? 0 : this.dlcvalues[no];
	}

	function getDLCValues()
	{
		return this.dlcvalues;
	}

	function getSysVoiceValues()
	{
		return this.svoicevalues;
	}

	function onConfigUpdate( name = null )
	{
		::Application.onConfigUpdate(name);

		if (name == null || name == "scaleMode")
		{
			this.setScaleMode(this.getConfig("scaleMode"));
		}

		if (name == null || name == "fullScreen")
		{
			this.setFullScreen(this.getConfig("fullScreen"));
		}
	}

	firstState = "movie0";
	firstLogo = true;
	function titleMovie()
	{
		this.printf("TARGET:%s\n", this.TARGET_SYSTEM);
		this.stopBGM(500);
		::wait(30);
		this.cleanup();
		this.setup();

		try
		{
			if (false && this.firstLogo)
			{
				this.openMenuPanel("motion/logo.psb", {
					chara = "FICTION",
					motion = "show"
				});
				this.firstLogo = false;
			}

			this.openMenuPanel("motion/logo.psb", {
				chara = "LOGO",
				motion = "mages"
			});
		}
		catch( e )
		{
			this.printf("failed to work logo motion\n");
			::printException(e);
		}

		::sync();
		::Application.titleMovie();
	}

	function titleLoop( cur, arg )
	{
		return ::Application.titleLoop(cur, arg);
	}

	function getStartScene( cur )
	{
		return {
			storage = "MAINLOOP.txt",
			target = ""
		};
	}

	function titleMenu( cur, arg )
	{
		this.cgmodecache = null;

		if (cur == null || cur == "title0")
		{
			return this.openMenuPanel([
				"motion/title.psb",
				"motion/particle.psb"
			], {
				chara = "TITLE",
				focus = 0
			});
		}
		else
		{
			return this.openMenuPanel([
				"motion/gamemode.psb",
				"motion/particle.psb"
			], {
				chara = "GAMEMODE",
				focus = arg == null ? 0 : arg
			});
		}
	}

	function title_load( arg )
	{
		return this.openLoad();
	}

	function title_config( arg )
	{
		this.openConfig();
	}

	function title_manual( arg )
	{
		this.openManual();
	}

	function title_musicmode( arg )
	{
		local func = ::MusicModeFunction(::loadData("config/musicmode.psb").root, 1);
		func.setDelegate(this);

		if (func.checkComplete())
		{
			this.giveMedal("md20");
		}

		this.bgm.stop(500);
		this.openMenuPanel([
			"motion/musicmode.psb",
			"motion/particle.psb"
		], "MUSICMODE", func);
	}

	function title_pantsmode( arg )
	{
		this.openMenuPanel([
			"motion/pntview.psb",
			"motion/particle.psb"
		], "PNTGALLERY");
	}

	function checkExit()
	{
		if (::confirm("%C\x00e3\x0082\x00b2\x00e3\x0083\x00bc\x00e3\x0083\x00a0\x00e3\x0082\x0092\x00e7\x00b5\x0082\x00e4\x00ba\x0086\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x009f"))
		{
			this.System.exit();
		}
	}

	cgmodecache = null;
	function _cgmode( func, medal, title, cur, arg )
	{
		func.setDelegate(this);

		if (arg == null && medal != "")
		{
			if (func.checkComplete())
			{
				this.giveMedal(medal);
			}
		}

		this.playBGM(this.EXTRABGM);

		if (cur == "cgmode" && this.cgmodecache == null)
		{
			this.cgmodecache = [
				::loadData("motion/charaselect.psb"),
				::loadData("motion/cgselect.psb"),
				::loadData("motion/particle.psb")
			];
		}

		local ret = this.openMenuPanel([
			"motion/charaselect.psb",
			"motion/cgselect.psb",
			"motion/particle.psb"
		], arg == null ? {
			title = title,
			chara = "CHARA"
		} : {
			title = title,
			chara = "CG",
			arg = arg
		}, func);

		if (typeof ret == "table")
		{
			ret.arg <- {
				ch = func.ch,
				cur = ret.cur,
				titlebgm = false
			};
			ret.cur <- cur;
			return ret;
		}

		this.cgmodecache = null;
	}

	function title_cgmode( arg )
	{
		return this._cgmode(::MyCgModeFunction(::loadData("config/cgmode.psb").root), "md18", 0, "cgmode", arg);
	}

	function title_replaymode( arg )
	{
		return this._cgmode(::MyReplayModeFunction(::loadData("config/replaymode.psb").root), "md19", 1, "replaymode", arg);
	}

	function title_clearmode( arg )
	{
		this.openClear();
	}

	function isClear()
	{
		return ::allSeen || this.getSystemFlag("clear_game");
	}

	function isExtraOpen()
	{
		return this.isClear();
	}

	function openConfig()
	{
		this.setConfigMode(true);

		try
		{
			this.openMenuPanel([
				"motion/option.psb",
				"motion/particle.psb"
			], {
				chara = "OPTION1",
				focus = 0
			}, ::ConfigModeFunction(), true);
		}
		catch( e )
		{
			this.setConfigMode(false);
			throw e;
		}

		this.setConfigMode(false);
	}

	function openLoad()
	{
		local ret = this.openMenuPanel([
			"motion/saveload.psb",
			"motion/particle.psb"
		], {
			chara = "SAVE",
			state = 1
		}, ::MySaveLoadModeFunction(false));

		if (ret == "exit")
		{
			ret = null;
		}

		return ret;
	}

	function openManual()
	{
		this.openMenuPanel([
			"motion/manual.psb",
			"motion/particle.psb"
		], {
			chara = "MANUAL",
			focus = 0
		}, ::ManualModeFunction());
	}

	clearList = [
		[
			"aqua",
			"\x00e3\x0082\x00a2\x00e3\x0082\x00af\x00e3\x0082\x00a2"
		],
		[
			"megumin",
			"\x00e3\x0082\x0081\x00e3\x0081\x0090\x00e3\x0081\x00bf\x00e3\x0082\x0093"
		],
		[
			"darkness",
			"\x00e3\x0083\x0080\x00e3\x0082\x00af\x00e3\x0083\x008d\x00e3\x0082\x00b9"
		],
		[
			"wiz",
			"\x00e3\x0082\x00a6\x00e3\x0082\x00a3\x00e3\x0082\x00ba"
		],
		[
			"chris",
			"\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00b9"
		],
		[
			"yunyun",
			"\x00e3\x0082\x0086\x00e3\x0082\x0093\x00e3\x0082\x0086\x00e3\x0082\x0093"
		]
	];
	function getClear( n )
	{
		if (n < this.clearList.len())
		{
			local ret = 0;
			local name = this.clearList[n][0];

			if (this.getSystemFlag("clear_" + name + "_good"))
			{
				ret = ret | 1;
			}

			if (this.getSystemFlag("clear_" + name + "_normal"))
			{
				ret = ret | 2;
			}

			return ret;
		}

		return 0;
	}

	clearFlags = null;
	function initClearFlags()
	{
		this.clearFlags = {};

		foreach( i, v in this.clearList )
		{
			local name = v[0];
			local cname = v[1];
			local m = i * 2 + 1;
			this.clearFlags["clear_" + name + "_good"] <- {
				type = 1,
				name = cname,
				id = i,
				medal = m
			};
			this.clearFlags["clear_" + name + "_normal"] <- {
				type = 0,
				name = cname,
				id = i,
				medal = m + 1
			};
		}
	}

	clearName = null;
	function onSystemFlag( type, name, value, old )
	{
		if (type == 3 && name in this.clearFlags)
		{
			local info = this.clearFlags[name];

			if (info.type == 0 || info.type == 1)
			{
				this.giveMedal(this.format("md%02d", info.medal));

				if (!old && value)
				{
					this.clearName = name;
				}
			}
		}
	}

	function onStartScene( scene )
	{
		this.clearName = null;
	}

	function onEndScene( scene, ret )
	{
		if (ret == 0 && this.clearName != null)
		{
			local info = this.clearFlags[this.clearName];
			local msg;

			switch(info.type)
			{
			case 0:
				msg = "%C" + info.name + "\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0081\x00ae\n\x00e3\x0083\x008e\x00e3\x0083\x00bc\x00e3\x0083\x009e\x00e3\x0083\x00ab\x00e3\x0082\x00a8\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0082\x0092\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00a2\x00e3\x0083\x00bc\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0080\x0082";
				break;

			case 1:
				msg = "%C" + info.name + "\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0081\x00ae\n\x00e3\x0082\x00b0\x00e3\x0083\x0083\x00e3\x0083\x0089\x00e3\x0082\x00a8\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0082\x0092\x00e3\x0082\x00af\x00e3\x0083\x00aa\x00e3\x0082\x00a2\x00e3\x0083\x00bc\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0080\x0082";
				break;
			}

			::inform(msg);
			this.sysvPlay(20);

			if (::confirm(info.name + "\x00e3\x0082\x0092\x00e3\x0082\x00b7\x00e3\x0082\x00b9\x00e3\x0083\x0086\x00e3\x0083\x00a0\x00e3\x0083\x009c\x00e3\x0082\x00a4\x00e3\x0082\x00b9\x00e3\x0081\x00ab\x00e8\x00a8\x00ad\x00e5\x00ae\x009a\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x009f"))
			{
				this.cf.systemVoice = info.id + 1;
			}
		}
	}

	function showUnread()
	{
		::Application.showUnread();
		this.printf("-----start unread image files-----\n");
		local cgmodelist = ::loadData("config/cgmode.psb").root;

		foreach( data in cgmodelist )
		{
			foreach( value in data )
			{
				local c = value.len();

				for( local i = 1; i < c; i++ )
				{
					local name = value[i];

					if (!this.getFileReaded(name))
					{
						this.printf("%s\n", name);
					}
				}
			}
		}

		this.printf("-----done unread image files-----\n");
	}

}

function createGamePlayer( owner, scene )
{
	if (::getval(scene, "storage") == "cgview")
	{
		return this.CGViewPlayer(owner);
	}
	else
	{
		return this.MyPlayer(owner);
	}
}

function gameMain( args, init )
{
	this.MyApplication(init).main(args);
}

this.printf("done override\n");
