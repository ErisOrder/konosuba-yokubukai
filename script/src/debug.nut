class this.DialogWindow extends ::BasicLayer
{
	DEFAULT_AFX = "center";
	DEFAULT_AFY = "center";
	maxline = 10;
	_bounds = null;
	_scale = null;
	constructor( screen = null )
	{
		::BasicLayer.constructor(screen);
		this._bounds = ::getScreenBounds(screen);
		this._scale = this.min(this._bounds.width / this.SCWIDTH, this._bounds.height / this.SCHEIGHT);
		this.maxline = this.SCHEIGHT / this.DEBUG_FONTSIZE - 2;
		this.smoothing = true;
	}

}

class this.LineInputWindow extends this.DialogWindow
{
	constructor( screen = null )
	{
		::DialogWindow.constructor(screen);
		this.setPriority(32 + 1);
	}

	function drawPage( name, num )
	{
		this.clearText();
		this.drawText(-this.SCWIDTH / 4 + this.DEBUG_FONTSIZE / 2, -this.SCHEIGHT / 4 + this.DEBUG_FONTSIZE / 2, this.format("\x00e4\x00b8\x008a\x00e4\x00b8\x008b\x00e5\x00b7\x00a6\x00e5\x008f\x00b3:\x00e5\x00a2\x0097\x00e6\x00b8\x009b \x00e2\x0097\x008b\x00ef\x00bc\x009a\x00e6\x00b1\x00ba\x00e5\x00ae\x009a \x00c3\x0097:\x00e6\x0088\x00bb\x00e3\x0082\x008b\n%s:%04d\n", name, num), this.DEBUG_FONTSIZE, 4294967295, this._scale);
	}

	function open( num = 0, name = "" )
	{
		local input = this.getCurrentInput();
		this.fill(this.SCWIDTH / 2 * this._scale, this.SCHEIGHT / 2 * this._scale, 4282664004);
		local num = 0;
		this.drawPage(name, num);

		while (true)
		{
			::sync();
			local onum = num;
			local key = this.getPadKey(input);
			local shift = input.key(512);

			switch(key)
			{
			case this.KEY_OK:
				return num;

			case this.KEY_CANCEL:
				return null;

			case 128:
				num -= shift ? 10 : 1;

				if (num < 0)
				{
					num = 0;
				}

				break;

			case 64:
				num += shift ? 10 : 1;
				break;

			case 16:
				num += shift ? 100 : 10;

				if (num < 0)
				{
					num = 0;
				}

				break;

			case 32:
				num -= shift ? 100 : 10;
				break;
			}

			if (num != onum)
			{
				this.drawPage(name, num);
			}
		}

		this.clear();
		::sync();
	}

}

class this.SceneSelectWindow extends this.DialogWindow
{
	list = null;
	constructor( list, screen = null )
	{
		::DialogWindow.constructor(screen);
		this.setPriority(32);
		this.list = list;
	}

	function getName( scene )
	{
		local ret = "";

		if ("storage" in scene)
		{
			ret = scene.storage;
		}

		if ("target" in scene)
		{
			ret += scene.target;
		}

		return ret;
	}

	function drawPage( disp, cur )
	{
		this.clearText();
		local text = "\x00e2\x0097\x008b\x00ef\x00bc\x009a\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e5\x00ae\x009f\x00e8\x00a1\x008c \x00c3\x0097\x00ef\x00bc\x009a\x00e3\x0082\x00ad\x00e3\x0083\x00a3\x00e3\x0083\x00b3\x00e3\x0082\x00bb\x00e3\x0083\x00ab \x00e2\x0096\x00a1:\x00e8\x00a1\x008c\x00e5\x0085\x00a5\x00e5\x008a\x009b\n";

		for( local i = 0; i < this.maxline; i++ )
		{
			local n = disp + i;

			if (n < this.list.len())
			{
				local scene = this.getName(this.list[n]).toupper();

				if (i == cur)
				{
					text += this.format("[%s]\n", scene);
				}
				else
				{
					text += this.format(" %s \n", scene);
				}
			}
		}

		this.drawText(-this.SCWIDTH / 2 + this.DEBUG_FONTSIZE / 2, -this.SCHEIGHT / 2 + this.DEBUG_FONTSIZE / 2, text, this.DEBUG_FONTSIZE, 4294967295, this._scale);
	}

	function open( current = null )
	{
		local input = this.getCurrentInput();
		this.fill(this.SCWIDTH * this._scale, this.SCHEIGHT * this._scale, 4282664004);
		local disp = current == null ? 0 : current;

		if (disp < 0 || disp >= this.list.len())
		{
			disp = 0;
		}

		local cur = 0;
		this.drawPage(disp, cur);

		while (true)
		{
			::sync();
			local ocur = cur;
			local odisp = disp;
			local key = this.getPadKey(input);

			switch(key)
			{
			case this.KEY_OK:
				return this.list[disp + cur];

			case this.KEY_CANCEL:
				return null;

			case 1024:
			case 2048:
				local line = ::LineInputWindow(this.getOwner());
				local num = line.open(0, "\x00e8\x00a1\x008c\x00e7\x0095\x00aa\x00e5\x008f\x00b7");

				if (num != null)
				{
					return {
						storage = this.list[disp + cur].storage,
						target = num
					};
				}

				break;

			case 64:
				if (cur > 0)
				{
					cur--;
				}
				else if (disp > 0)
				{
					disp--;
				}
				else
				{
					disp = this.list.len() - this.maxline;

					if (disp < 0)
					{
						disp = 0;
					}

					cur = this.list.len() - disp - 1;
				}

				break;

			case 128:
				if (cur + 1 < this.maxline)
				{
					if (disp + cur < this.list.len() - 1)
					{
						cur++;
					}
					else
					{
						cur = 0;
					}
				}
				else if (disp + 1 + cur < this.list.len())
				{
					disp++;
				}
				else
				{
					disp = 0;
					cur = 0;
				}

				break;

			case 16:
				if (disp < this.list.len() - this.maxline)
				{
					disp += this.maxline;
				}

				if (disp + cur >= this.list.len())
				{
					cur = this.list.len() - disp - 1;
				}

				break;

			case 32:
				if (disp > this.maxline)
				{
					disp -= this.maxline;
				}

				break;
			}

			if (odisp != disp || ocur != cur)
			{
				this.drawPage(disp, cur);
			}
		}

		this.clear();
		::sync();
	}

}

class this.VariableEditWindow extends this.DialogWindow
{
	player = null;
	list = null;
	constructor( player, screen = null )
	{
		::DialogWindow.constructor(screen);
		this.setPriority(32);
		this.player = player.weakref();
		this.list = player.getIntFlags();
	}

	function updateValue( disp, cur )
	{
		local n = disp + cur;

		if (n >= 0 && n < this.list.len())
		{
			local name = this.list[n];
			local value = this.toint(this.player.getFlag(name), 0);
			local nvalue = ::LineInputWindow(this.getOwner()).open(value, "\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x0080\x00a4");

			if (value != nvalue)
			{
				this.player.setFlag(name, nvalue);
				return true;
			}
		}

		return false;
	}

	function drawPage( disp, cur )
	{
		this.clearText();
		local text = "\x00e2\x0097\x008b\x00ef\x00bc\x009a\x00e7\x00b7\x00a8\x00e9\x009b\x0086 \x00c3\x0097\x00ef\x00bc\x009a\x00e7\x00b5\x0082\x00e4\x00ba\x0086\n";

		for( local i = 0; i < this.maxline; i++ )
		{
			local n = disp + i;

			if (n < this.list.len())
			{
				local name = this.list[n];
				local value = this.toint(this.player.getFlag(name), 0);
				text += this.format(i == cur ? "%03d:[%s] %s\n" : "%03d: %s  %s\n", n, name, value);
			}
		}

		this.drawText(-this.SCWIDTH / 2 + this.DEBUG_FONTSIZE / 2, -this.SCHEIGHT / 2 + this.DEBUG_FONTSIZE / 2, text, this.DEBUG_FONTSIZE, 4294967295, this._scale);
	}

	function open()
	{
		local input = this.getCurrentInput();
		this.fill(this.SCWIDTH * this._scale, this.SCHEIGHT * this._scale, 4282664004);
		local disp = 0;
		local cur = 0;
		this.drawPage(disp, cur);

		while (true)
		{
			::sync();
			local ocur = cur;
			local odisp = disp;
			local update = false;
			local key = this.getPadKey(input);

			switch(key)
			{
			case this.KEY_OK:
				update = this.updateValue(disp, cur);
				break;

			case this.KEY_CANCEL:
				return;
				break;

			case 64:
				if (cur > 0)
				{
					cur--;
				}
				else if (disp > 0)
				{
					disp--;
				}
				else
				{
					disp = this.list.len() - this.maxline;

					if (disp < 0)
					{
						disp = 0;
					}

					cur = this.list.len() - disp - 1;
				}

				break;

			case 128:
				if (cur + 1 < this.maxline)
				{
					if (disp + cur < this.list.len() - 1)
					{
						cur++;
					}
					else
					{
						cur = 0;
					}
				}
				else if (disp + 1 + cur < this.list.len())
				{
					disp++;
				}
				else
				{
					disp = 0;
					cur = 0;
				}

				break;

			case 16:
				if (disp < this.list.len() - this.maxline)
				{
					disp += this.maxline;
				}

				if (disp + cur >= this.list.len())
				{
					cur = this.list.len() - disp - 1;
				}

				break;

			case 32:
				if (disp > this.maxline)
				{
					disp -= this.maxline;
				}

				break;
			}

			if (odisp != disp || ocur != cur || update)
			{
				this.drawPage(disp, cur);
			}
		}

		this.clear();
		::sync();
	}

}

class this.SystemVariableProxy
{
	player = null;
	constructor( player )
	{
		this.player = player;
	}

	function getIntFlags()
	{
		return this.player.getIntSystemFlags();
	}

	function setFlag( name, value )
	{
		this.player.setSystemFlag(name, value);
	}

	function getFlag( name )
	{
		return this.player.getSystemFlag(name);
	}

}

this.globalVariableNames <- [
	"allSeen"
];
function addGlobalVariable( name )
{
	::globalVariableNames.append(name);
}

class this.GlobalVariableProxy
{
	constructor()
	{
	}

	function getIntFlags()
	{
		return this.globalVariableNames;
	}

	function setFlag( name, value )
	{
		local global = ::getroottable();
		global[name] <- value;
	}

	function getFlag( name )
	{
		local global = ::getroottable();
		return global[name];
	}

}

function debugMenu( target, sel )
{
	switch(sel)
	{
	case 0:
		sel = ::select([
			"\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e7\x00b7\x00a8\x00e9\x009b\x0086",
			"\x00e3\x0082\x00b7\x00e3\x0082\x00b9\x00e3\x0083\x0086\x00e3\x0083\x00a0\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e7\x00b7\x00a8\x00e9\x009b\x0086",
			"\x00e3\x0082\x00b0\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0090\x00e3\x0083\x00ab\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e7\x00b7\x00a8\x00e9\x009b\x0086",
			"\x00e5\x0085\x00a8\x00e9\x0091\x0091\x00e8\x00b3\x009e\x00e3\x0083\x0086\x00e3\x0082\x00b9\x00e3\x0083\x0088ON/OFF",
			"\x00e5\x0085\x00a8\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e3\x0083\x0095\x00e3\x0083\x00a9\x00e3\x0082\x00b0\x00e8\x00b5\x00b0\x00e6\x009f\x00bb",
			"\x00e6\x009c\x00aa\x00e8\x00aa\x00ad\x00e7\x00a2\x00ba\x00e8\x00aa\x008d",
			"\x00e4\x00bf\x009d\x00e5\x00ad\x0098\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf\x00e7\x00a0\x00b4\x00e5\x00a3\x008a",
			"\x00e5\x00bc\x00b7\x00e5\x0088\x00b6\x00e5\x0085\x00a8\x00e3\x0082\x00bb\x00e3\x0083\x00bc\x00e3\x0083\x0096"
		], null, 32);

		while (sel != null)
		{
			switch(sel)
			{
			case 0:
				::VariableEditWindow(target, ::baseScreen).open();
				break;

			case 1:
				local proxy = this.SystemVariableProxy(target);
				::VariableEditWindow(proxy, ::baseScreen).open();
				break;

			case 2:
				local proxy = this.GlobalVariableProxy();
				::VariableEditWindow(proxy, ::baseScreen).open();
				throw this.GameStateException("tostart");
				break;

			case 3:
				::allSeen = !::allSeen;
				throw this.GameStateException("tostart");
				break;

			case 4:
				target.parseSFlags();
				throw this.GameStateException("tostart");
				break;

			case 5:
				target.showUnread();
				throw this.GameStateException("tostart");
				break;

			case 6:
				target.breakSaveData();
				break;

			case 7:
				target.testSaveAll();
				break;
			}
		}

		break;

	case 1:
		local scene = ::SceneSelectWindow(target.getSceneList(), ::baseScreen).open("curSceneId" in target ? target.curSceneId : 0);

		if (scene != null)
		{
			this.onDebugSceneSelect();
			local s = {};

			foreach( name, value in scene )
			{
				s[name] <- value;
			}

			s.flags <- clone target.flags;
			throw this.GameStateException("restart", s);
		}

		break;

	case 2:
		sel = ::select([
			"\x00e3\x0083\x00aa\x00e3\x0082\x00bd\x00e3\x0083\x00bc\x00e3\x0082\x00b9\x00e3\x0083\x00a1\x00e3\x0083\x00bc\x00e3\x0082\x00bf",
			"\x00e3\x0083\x0087\x00e3\x0083\x0090\x00e3\x0083\x0083\x00e3\x0082\x00b0\x00e6\x0083\x0085\x00e5\x00a0\x00b1",
			"\x00e3\x0083\x00aa\x00e3\x0083\x0093\x00e3\x0082\x00b8\x00e3\x0083\x00a7\x00e3\x0083\x00b3\x00e6\x0083\x0085\x00e5\x00a0\x00b1"
		], null, 32);

		while (sel != null)
		{
			switch(sel)
			{
			case 0:
				this.System.setResourceMeter(!this.System.getResourceMeter());
				break;

			case 1:
				this.toggleDebugInfo();
				break;

			case 2:
				this.toggleRevisionInfo();
				break;
			}
		}

		break;

	default:
		if (this.confirm("YESNO_TITLE"))
		{
			throw this.GameStateException("totitle");
		}

		break;
	}
}

this.DEBUGOPENKEY <- 512 | 256;
function openDebugMenu()
{
	this.debugMenu();
}

function checkDebug( input )
{
	if (input.isComboKeyPressed(this.DEBUGOPENKEY))
	{
		this.openDebugMenu();
		return true;
	}

	return false;
}

