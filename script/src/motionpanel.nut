function getMotionLayerGetter( player, name )
{
	if (player != null)
	{
		if (name.find("/") >= 0)
		{
			name = name.split("/");
			local count = name.len() - 1;

			for( local i = 0; i < count; i++ )
			{
				player = player.getLayerMotion(name[i]);

				if (player == null)
				{
					return null;
				}
			}

			return player.getLayerGetter(name[count]);
		}
		else
		{
			return player.getLayerGetter(name);
		}
	}
}

function getMotionLayerMotion( player, name )
{
	local lgetter = this.getMotionLayerGetter(player, name);

	if (lgetter != null && lgetter.type == 3)
	{
		return lgetter.motion;
	}
}

function getMotionLayerShape( player, name )
{
	local lgetter = this.getMotionLayerGetter(player, name);

	if (lgetter != null && lgetter.type == 1)
	{
		return lgetter.shape;
	}
}

class this.MotionInfo extends this.Object
{
	buttonlist = null;
	infos = null;
	storage = null;
	chara = null;
	motion = null;
	input = null;
	inputNo = 0;
	charaInfos = null;
	constructor( owner, elm )
	{
		::Object.constructor();
		this.setDelegate(owner);
		this.buttonlist = [];
		this.infos = elm != null ? clone elm : {};
		this.charaInfos = {};
	}

	function setChara( chara, caller )
	{
		this.chara = chara;
		this.charaInfos.clear();

		foreach( info in this.buttonlist )
		{
			local type = ::getval(info, "type");

			if (type == "init")
			{
				if (!("cond" in info) || caller.evalCond(info.name, info.cond))
				{
					foreach( name, value in info )
					{
						if (name != "name" && name != "cond" && name != "type")
						{
							if (!(name in this.charaInfos) && name in this.infos)
							{
								local o = this.infos[name];
								local t = typeof o;

								if (t == "array" || t == "table")
								{
									this.charaInfos[name] <- clone o;
								}
							}

							this._entryParam(name, value, this.charaInfos);
						}
					}
				}
			}
		}
	}

	function _entryParam( name, data, infos )
	{
		if (name in infos)
		{
			local store = infos[name];
			local type = typeof store;

			if (typeof data == type && (type == "table" || type == "array"))
			{
				if (type == "table")
				{
					foreach( n, v in data )
					{
						store[n] <- v;
					}
				}
				else
				{
					foreach( v in data )
					{
						store.append(v);
					}
				}

				return;
			}
			else if (typeof data == "function")
			{
				if (type == "array")
				{
					store.append(data);
					return;
				}
				else if (type == "function")
				{
					local array = [];
					array.append(store);
					array.append(data);
					infos[name] = array;
					return;
				}
			}
		}

		infos[name] <- data;
	}

	function entryParam( name, data )
	{
		this._entryParam(name, data, this.infos);
	}

	function hasParam( name )
	{
		return name in this.charaInfos || name in this.infos;
	}

	function _get( name )
	{
		if (name in this.charaInfos)
		{
			return this.charaInfos[name];
		}
		else if (name in this.infos)
		{
			return this.infos[name];
		}
		else
		{
			return ::Object.get.bindenv(this)(name);
		}
	}

	function _set( name, value )
	{
		if (name in this.charaInfos)
		{
			this.charaInfos[name] = value;
		}
		else if (name in this.infos)
		{
			this.infos[name] = value;
		}
		else
		{
			::Object.set.bindenv(this)(name, value);
		}
	}

}

class this.MotionBase extends this.Object
{
	owner = null;
	elm = null;
	name = null;
	laybase = null;
	layname = null;
	_disable = false;
	variables = null;
	recursive = false;
	digitInfo = null;
	figures = 0;
	zero = false;
	function getFunc( elm, name )
	{
		return name in elm ? (typeof elm[name] == "string" ? this.owner.eval(elm[name]) : elm[name]) : null;
	}

	function getObjectParam( elm, name )
	{
		return name in elm ? (typeof elm[name] == "string" ? this.owner.eval(elm[name]) : elm[name]) : null;
	}

	function getLayerName( elm, lname, laybase = null, name = null )
	{
		local layname = ::getval(elm, lname, name);

		if (layname != null)
		{
			if (typeof layname == "string" && layname.find(","))
			{
				layname = layname.split(",");

				if (laybase != null)
				{
					for( local i = 0; i < layname.len(); i++ )
					{
						layname[i] = laybase + "/" + layname[i];
					}
				}
			}
			else if (laybase != null)
			{
				layname = laybase + "/" + layname;
			}
		}

		return layname;
	}

	function addLayerName( names )
	{
		if (names != null)
		{
			if (typeof this.layname != "array")
			{
				this.layname = [
					this.layname
				];
			}

			if (typeof names == "array")
			{
				foreach( i, v in names )
				{
					this.layname.append(v);
				}
			}
			else
			{
				this.layname.append(names);
			}
		}
	}

	constructor( owner, elm, digitPrefix = "digit" )
	{
		::Object.constructor();
		this.owner = owner.weakref();
		this.elm = clone elm;
		this.name = elm.name;
		this.laybase = ::getval(elm, "layerbase");
		this.layname = this.getLayerName(elm, "layer", this.laybase, this.name);
		this.variables = {};
		this.recursive = ::getval(elm, "recursive");

		if (digitPrefix == "" || digitPrefix + "valuename" in elm || digitPrefix + "getfunc" in elm)
		{
			this.digitInfo = this.MotionValueInfo(owner, elm, digitPrefix);
			this.figures = ::getval(elm, "figures", 1);
			this.zero = ::getval(elm, "zero", false);
		}
	}

	function __setVariable( layer, name, value, flag, time = 0, accel = 0, recursive = false )
	{
		local set = false;

		if (layer.type == 3)
		{
			if (time > 0)
			{
				layer.motion.animateVariable(name, value, time * 60 / 1000, accel);
			}
			else
			{
				layer.motion.setVariable(name, value, flag);
			}

			set = true;
		}

		if (this.recursive || layer.type == 2 || recursive)
		{
			foreach( lay in layer.children )
			{
				if (this.__setVariable(lay, name, value, flag, time, accel, true))
				{
					set = true;
				}
			}
		}

		return set;
	}

	function _setVariable( layname, name, value, flag, time = 0, accel = 0 )
	{
		local layer = this.owner.getLayer(layname);
		local set = false;

		if (layer != null)
		{
			set = this.__setVariable(layer, name, value, flag, time, accel);
		}

		if (!set)
		{
			this.owner.setVariable(this.format("%s::%s", layname, name), value, flag, time, accel);
		}
	}

	function setVariable( name, value, flag = 0, time = 0, accel = 0 )
	{
		this.variables[name] <- value;

		if (typeof this.layname == "array")
		{
			foreach( lname in this.layname )
			{
				this._setVariable(lname, name, value, flag, time, accel);
			}
		}
		else if (this.layname != "")
		{
			this._setVariable(this.layname, name, value, flag, time, accel);
		}
	}

	function getVariable( name, defaultValue = null )
	{
		local ret = name in this.variables ? this.variables[name] : null;

		if (ret == null)
		{
			ret = defaultValue;
		}

		return ret;
	}

	function getLayerMotion()
	{
		if (typeof this.layname == "array")
		{
			foreach( lname in this.layname )
			{
				local l = this.owner.getLayerMotion(lname);

				if (l != null)
				{
					return l;
				}
			}
		}
		else
		{
			return this.owner.getLayerMotion(this.layname);
		}
	}

	function getDisable()
	{
		return this._disable;
	}

	function setDisable( v )
	{
		this._disable = v;
		this.setVariable("disable", v ? 1 : 0);
	}

	function setFigVariable( figno, name, value, flag = 0, time = 0, accel = 0 )
	{
		if (typeof this.layname == "array")
		{
			foreach( lname in this.layname )
			{
				this._setVariable(this.format("%s/fig%d", lname, figno), name, value, flag, time, accel);
			}
		}
		else if (this.layname != "")
		{
			this._setVariable(this.format("%s/fig%d", this.layname, figno), name, value, flag, time, accel);
		}
	}

	function setFigValue( value )
	{
		local result = [];
		local base = 1;
		local n = 1;
		value = ::toint(value);

		for( local i = 0; i < this.figures; i++ )
		{
			local num = ::toint(value / base) % 10;
			result.append(num);

			if (num > 0)
			{
				n = i + 1;
			}

			base *= 10;
		}

		if (this.zero || ::toint(value / base) > 0)
		{
			n = this.figures;
		}

		this.setVariable("figures", n);

		for( local i = 0; i < n; i++ )
		{
			this.setFigVariable(i, "number", result[i], 1);
		}
	}

	function onStart()
	{
		if ("startvar" in this.elm)
		{
			foreach( name, exp in this.elm.startvar )
			{
				try
				{
					if (typeof exp == "table")
					{
						this.setVariable(name, this.eval(::getval(exp, "value")), ::getval(exp, "flag"), ::getval(exp, "time"), ::getval(exp, "accel"));
					}
					else
					{
						this.setVariable(name, this.owner.eval(exp));
					}
				}
				catch( e )
				{
					this.printf("%s:start\x00e6\x0099\x0082\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s:%s\n", this.name, name, exp);
					::printException(e);
				}
			}
		}

		try
		{
			this.setDisable("disable" in this.elm ? this.owner.eval(this.elm.disable) : false);
		}
		catch( e )
		{
			this.printf("%s:start\x00e6\x0099\x0082disable\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", this.name, this.elm.disable);
			::printException(e);
		}
	}

	function onInit( redraw = false )
	{
		if ("initvar" in this.elm)
		{
			foreach( name, exp in this.elm.initvar )
			{
				try
				{
					if (typeof exp == "table")
					{
						this.setVariable(name, this.owner.eval(::getval(exp, "value")), ::getval(exp, "flag"), ::getval(exp, "time"), ::getval(exp, "accel"));
					}
					else
					{
						this.setVariable(name, this.owner.eval(exp));
					}
				}
				catch( e )
				{
					this.printf("%s:init\x00e6\x0099\x0082\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s:%s\n", this.name, name, exp);
					::printException(e);
				}
			}
		}

		if ("disable" in this.elm)
		{
			try
			{
				this.setDisable("disable" in this.elm ? this.owner.eval(this.elm.disable) : false);
			}
			catch( e )
			{
				this.printf("%s:init\x00e6\x0099\x0082disable\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s:%s\n", this.name, this.name, this.exp);
				::printException(e);
			}
		}

		if (this.digitInfo != null)
		{
			this.setFigValue(this.digitInfo.getValue());
		}

		if ("update" in this.elm)
		{
			this.owner.update();
		}
	}

}

class this.MotionArea extends this.MotionBase
{
	enterFlag = false;
	area = null;
	constructor( owner, elm )
	{
		::MotionBase.constructor(owner, elm);
		this.enterFlag = false;
	}

	function __getLayerShape( layer, name, recursive = false )
	{
		if (layer != null)
		{
			if (layer.type == 3)
			{
				local ret = this.getMotionLayerShape(layer.motion, name);

				if (ret != null)
				{
					return ret;
				}
			}

			if (layer.type == 2 || recursive)
			{
				foreach( lay in layer.children )
				{
					local ret = this.__getLayerShape(lay, name, true);

					if (ret != null)
					{
						return ret;
					}
				}
			}
		}
	}

	function _getLayerShape( lname, name )
	{
		return this.__getLayerShape(this.owner.getLayer(lname), name);
	}

	function getLayerShape( name, layname = null )
	{
		if (layname == null)
		{
			layname = this.layname;
		}

		if (typeof layname == "array")
		{
			foreach( lname in layname )
			{
				local shape = this._getLayerShape(lname, name);

				if (shape != null)
				{
					return shape;
				}
			}
		}
		else
		{
			return this._getLayerShape(layname, name);
		}
	}

	function _checkContains( lname, x, y, area = null )
	{
		local layer = this.owner.getLayer(lname);

		if (layer != null)
		{
			if (area != null)
			{
				return layer.containsArea(x, y, area);
			}
			else
			{
				return layer.contains(x, y);
			}
		}
	}

	function checkContains( x, y, area = null, layname = null )
	{
		if (layname == null)
		{
			layname = this.layname;
		}

		if (layname == "__owner__")
		{
			return this.owner.checkButtonContains(this, x, y);
		}

		if (typeof layname == "array")
		{
			foreach( lname in layname )
			{
				if (this._checkContains(lname, x, y, area))
				{
					return true;
				}
			}
		}
		else
		{
			return this._checkContains(layname, x, y, area);
		}
	}

	function getArea( x, y )
	{
		return "";
	}

	function _checkArea( a )
	{
		if (a != null && a != this.area)
		{
			if (this.area != null)
			{
				this.owner.onLeaveArea(this, this.area);
			}

			this.owner.onEnterArea(this, a);
		}
		else if (a == null && this.area != null)
		{
			this.owner.onLeaveArea(this, this.area);
		}

		this.area = a;
	}

	function checkArea( x, y )
	{
		this._checkArea(this.getArea(x, y));
	}

	function checkEnter( init = false )
	{
		if (!this.enterFlag)
		{
			this.enterFlag = true;

			if ("preenter" in this.elm)
			{
				this.owner.exec(this.elm.preenter, this, this.owner, init);
			}

			this.onEnter();

			if ("enter" in this.elm)
			{
				this.owner.exec(this.elm.enter, this, this.owner, init);
			}
		}
	}

	function checkLeave( init = false )
	{
		this._checkArea(null);

		if (this.enterFlag)
		{
			this.enterFlag = false;

			if ("preleave" in this.elm)
			{
				this.owner.exec(this.elm.preleave, this, this.owner, init);
			}

			this.onLeave();

			if ("leave" in this.elm)
			{
				this.owner.exec(this.elm.leave, this, this.owner, init);
			}

			this.owner.onLeaveArea(this, this.area);
		}
	}

	function checkMouseMove( x, y )
	{
		if (this.checkContains(x, y))
		{
			this.checkArea(x, y);
			return true;
		}
		else
		{
			return false;
		}
	}

	function onStop()
	{
	}

	function onEnter()
	{
	}

	function onLeave()
	{
	}

	function onMouseDown( x, y, shift )
	{
		return false;
	}

	function onMouseMove( x, y, shift )
	{
	}

	function onMouseUp( x, y, shift )
	{
	}

}

class this.MotionParts extends this.MotionArea
{
	id = null;
	exp = null;
	bind = null;
	funcbind = null;
	bindnext = null;
	bindprev = null;
	rowcol = null;
	dir_parts = null;
	bindfunc = null;
	nofocus = false;
	drop = null;
	gesture = null;
	textInfo = null;
	imageInfo = null;
	constructor( owner, elm )
	{
		::MotionArea.constructor(owner, elm);
		this.id = ::getval(elm, "id");
		this.exp = ::getval(elm, "exp");
		this.drop = ::getval(elm, "drop");

		if (("row" in elm) && "col" in elm)
		{
			this.rowcol = [
				elm.row,
				elm.col
			];
		}

		this.dir_parts = ::getval(elm, "dir_parts");

		if ("bindprev" in elm)
		{
			this.bindprev = this.getButtonBind(elm.bindprev);
		}

		if ("bindnext" in elm)
		{
			this.bindnext = this.getButtonBind(elm.bindnext);
		}

		if ("bindfunc" in elm)
		{
			this.bindfunc = [];

			foreach( bind, func in elm.bindfunc )
			{
				this.bindfunc.append({
					bind = bind,
					button = this.getButtonBind(bind),
					func = func
				});
			}
		}

		this.nofocus = ::getval(elm, "nofocus", false);

		if ("text" in elm || "textgetfunc" in elm)
		{
			this.textInfo = this.MotionTextInfo(owner, elm, "text", "text");
		}

		if ("image" in elm || "imagegetfunc" in elm)
		{
			this.imageInfo = this.MotionImageInfo(owner, elm, "image", "image");
		}
	}

	function getPressEnable( touch = false )
	{
		return !this.getDisable();
	}

	function onFocusChange( focus, init = false )
	{
		if ("focus" in this.elm)
		{
			this.owner.exec(this.elm.focus, this, this.owner, init, focus);
		}
	}

	function updateFocus( focus, init = false )
	{
		if (focus)
		{
			this.checkEnter(init);
		}
		else
		{
			this.checkLeave(init);
		}
	}

	function setSelect( n, flag = 0 )
	{
		this.setVariable("select", n, flag);

		if (this.digitInfo != null)
		{
			this.owner.update();
			::MotionArea.onInit();
		}
	}

	function onInit( redraw = false )
	{
		this.setSelect(this.enterFlag ? 1 : 0);

		if (this.textInfo != null)
		{
			this.textInfo.onInit(redraw);
		}

		if (this.imageInfo != null)
		{
			this.imageInfo.onInit(redraw);
		}

		::MotionArea.onInit(redraw);
	}

	function onStop()
	{
		if (this.textInfo != null)
		{
			this.textInfo.onStop(this.owner, this.layname);
		}

		if (this.imageInfo != null)
		{
			this.imageInfo.onStop(this.owner, this.layname);
		}

		::MotionArea.onStop();
	}

	function onEnter()
	{
		this.setSelect(2);

		if (this.textInfo != null)
		{
			this.textInfo.onInit();
		}
	}

	function onLeave()
	{
		this.setSelect(3);

		if (this.textInfo != null)
		{
			this.textInfo.onInit();
		}
	}

	function onPress( x, y, bind = false )
	{
	}

	function onKeyDown( input )
	{
		if (input.keyPressed(64 | 32 | 128 | 16))
		{
			return this.owner.moveCursor(this, input);
		}

		if (this.bindfunc != null)
		{
			foreach( info in this.bindfunc )
			{
				if (input.keyPressed(info.button))
				{
					if (info.func != null)
					{
						this.owner.onExecute();

						try
						{
							this.owner.exec(info.func, this, this.owner);
						}
						catch( e )
						{
							if (e instanceof this.GameStateException)
							{
								throw e;
							}

							this.printf("%s:bindfunc failed:%s:%s:%s\n", this.name, info.bind, info.func);
							::printException(e);
						}
					}

					return true;
				}
			}
		}

		return false;
	}

	function getHotSpot()
	{
		if (typeof this.layname == "array")
		{
			foreach( lname in this.layname )
			{
				local l = this.owner.getLayerPosition(lname);

				if (l != null)
				{
					return l;
				}
			}
		}
		else
		{
			return this.owner.getLayerPosition(this.layname);
		}
	}

	function setExternalVisible( v )
	{
		if (this.textInfo != null)
		{
			this.textInfo.setVisible(v);
		}

		if (this.imageInfo != null)
		{
			this.imageInfo.setVisible(v);
		}
	}

	function setText( text, diff = 0, all = 0, indent = 0 )
	{
		if (this.textInfo != null)
		{
			this.textInfo.setText(text, diff, all, indent);
		}
	}

	function addText( text, diff = 0, all = 0 )
	{
		if (this.textInfo != null)
		{
			this.textInfo.addText(text, diff, all);
		}
	}

	function clearText()
	{
		if (this.textInfo != null)
		{
			this.textInfo.clearText();
		}
	}

	function setTextDefault( init )
	{
		if (this.textInfo != null)
		{
			this.textInfo.setTextDefault(init);
		}
	}

	function getRenderBounds()
	{
		if (this.textInfo != null)
		{
			this.textInfo.getRenderBounds();
		}
	}

	function getScrollMax()
	{
		if (this.textInfo != null)
		{
			this.textInfo.getScrollMax();
		}
	}

	function setScroll( n )
	{
		if (this.textInfo != null)
		{
			this.textInfo.setScroll(n);
		}
	}

}

this._buttonnames <- {
	LEFT = 32,
	RIGHT = 16,
	UP = 64,
	DOWN = 128,
	A = this.KEY_OK,
	B = this.KEY_CANCEL,
	X = 1024,
	Y = 2048,
	L = 512,
	R = 256,
	L2 = 65536,
	R2 = 131072,
	ALL = 33554431,
	L3 = 262144,
	R3 = 524288,
	START = 8,
	SELECT = 4
};
this._funckeynames <- {
	F1 = 1,
	F2 = 2,
	F3 = 4,
	F4 = 8,
	F5 = 16,
	F6 = 32,
	F7 = 64,
	F8 = 128,
	F9 = 256,
	F10 = 512,
	F11 = 1024,
	F12 = 2048,
	LBUTTON = 16777216,
	RBUTTON = 33554432,
	MBUTTON = 134217728
};
function getButtonBind( bind )
{
	if (typeof bind == "string")
	{
		local keys = bind.split("|");
		bind = 0;

		foreach( key in keys )
		{
			if (key in this._buttonnames)
			{
				bind = bind | this._buttonnames[key];
			}
			else if (key != "")
			{
				local n = ::eval(key, null, "");

				if (typeof n == "integer")
				{
					bind = bind | n;
				}
				else
				{
					this.printf("\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0081\x00aa\x00e3\x0082\x00ad\x00e3\x0083\x00bc\x00e6\x008c\x0087\x00e5\x00ae\x009a:%s\n", key);
				}
			}
		}
	}

	return bind;
}

function getFunctionBind( bind )
{
	if (typeof bind == "string")
	{
		local keys = bind.split("|");
		bind = 0;

		foreach( key in keys )
		{
			if (key in this._funckeynames)
			{
				bind = bind | this._funckeynames[key];
			}
			else if (key != "")
			{
				local n = ::eval(key, null, "");

				if (typeof n == "integer")
				{
					bind = bind | n;
				}
				else
				{
					this.printf("\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0081\x00aa\x00e3\x0082\x00ad\x00e3\x0083\x00bc\x00e6\x008c\x0087\x00e5\x00ae\x009a:%s\n", key);
				}
			}
		}
	}

	return bind;
}

class this.MotionButton extends this.MotionParts
{
	result = null;
	wait = false;
	motion = null;
	change = null;
	timeout = null;
	waitfunc = null;
	drag = null;
	dragx = 0;
	dragy = 0;
	dragstart = false;
	dragdiff = 5;
	touchpress = true;
	nopress = false;
	btneval = null;
	constructor( owner, elm )
	{
		::MotionParts.constructor(owner, elm);
		this.result = ::getval(elm, "result");

		if (this.result == "")
		{
			this.result = this.name;
		}

		this.wait = ::getval(elm, "wait");

		if ("motionfunc" in elm)
		{
			this.motion = this.getFunc(elm, "motionfunc");
		}
		else if ("motion" in elm)
		{
			this.motion = elm.motion;
		}

		this.exp = ::getval(elm, "exp");
		this.change = ::getval(elm, "change");
		this.drag = ::getval(elm, "drag");
		this.touchpress = ::getval(elm, "touchpress", true);
		this.nopress = ::getval(elm, "nopress", false);
		this.btneval = ::getval(elm, "eval");

		if ("bind" in elm)
		{
			this.bind = this.getButtonBind(elm.bind);
		}

		if ("funcbind" in elm)
		{
			this.funcbind = this.getFunctionBind(elm.funcbind);
		}

		if ("gesture" in elm)
		{
			this.gesture = elm.gesture;
		}

		if ("timeout" in elm)
		{
			this.timeout = ::getint(elm, "timeout");
		}

		if ("waitfunc" in elm)
		{
			this.waitfunc = this.getFunc(elm, "waitfunc");
		}
	}

	function getPressEnable( touch = false )
	{
		return !this.nopress && (this.touchpress || !touch) && !this.getDisable() && (this.btneval == null || this.owner.eval(this.btneval));
	}

	function onMouseDown( x = 0, y = 0, shift = 0 )
	{
		this.dragstart = false;

		if (this.drag != null)
		{
			this.dragx = x;
			this.dragy = y;
			return true;
		}
	}

	function onMouseMove( x, y, shift )
	{
		if (this.drag != null)
		{
			if (this.dragstart || this.abs(this.dragx - x) > this.dragdiff || this.abs(this.dragy - y) > this.dragdiff)
			{
				this.owner.onMotionDrag(this, x, y, this.dragstart == false ? 0 : 1);
				this.dragstart = true;
			}
		}
	}

	function onMouseUp( x, y, shift )
	{
		if (this.drag != null)
		{
			if (this.dragstart)
			{
				this.dragstart = false;
				this.owner.onMotionDrag(this, x, y, 2);
				return this.owner.onMotionDrop(this, x, y);
			}
		}
	}

	function onPress( x = 0, y = 0, bind = false )
	{
		this.setSelect(4, 1);
		this.owner.onMotionButton(this);

		if (bind && !this.enterFlag)
		{
			this.setSelect(0);
		}

		return true;
	}

	function onKeyDown( input )
	{
		if (this.getPressEnable() && input.keyPressed(this.KEY_OK))
		{
			this.onPress();
			return true;
		}

		return ::MotionParts.onKeyDown(input);
	}

}

class this.MotionValueInfo 
{
	owner = null;
	name = null;
	valuename = null;
	setfunc = null;
	getfunc = null;
	limitfunc = null;
	function getFunc( elm, name )
	{
		return name in elm ? (typeof elm[name] == "string" ? this.owner.eval(elm[name]) : elm[name]) : null;
	}

	constructor( owner, elm, prefix = "" )
	{
		this.owner = owner.weakref();
		this.name = ::getval(elm, "name");
		this.valuename = ::getval(elm, prefix + "valuename");
		this.setfunc = this.getFunc(elm, prefix + "setfunc");
		this.getfunc = this.getFunc(elm, prefix + "getfunc");
		this.limitfunc = this.getFunc(elm, prefix + "limitfunc");
	}

	function checkLimit( value )
	{
		if (typeof this.limitfunc == "function")
		{
			value = this.limitfunc(value);
		}

		return value;
	}

	function fixBool( value )
	{
		return typeof value == "bool" ? (value ? 1 : 0) : value;
	}

	function getValue( arg = null )
	{
		if (typeof this.getfunc == "function")
		{
			try
			{
				if (arg != null)
				{
					  // [015]  OP_POPTRAP        1      0    0    0
					return this.fixBool(this.owner.execFunc(this.getfunc, this, arg));
				}
				else
				{
					  // [025]  OP_POPTRAP        1      0    0    0
					return this.fixBool(this.owner.execFunc(this.getfunc, this));
				}
			}
			catch( e )
			{
				this.printf("%s:getValue failed:%s:%s\n", this.name, this.getfunc, "message" in e ? e.message : e);
				::printException(e);
			}
		}
		else if (this.valuename != null)
		{
			try
			{
				if (typeof this.valuename == "string")
				{
					if (this.valuename.charAt(0) == "!")
					{
						  // [074]  OP_POPTRAP        1      0    0    0
						return this.owner.eval(this.valuename.substr(1)) ? 0 : 1;
					}
					else
					{
						  // [083]  OP_POPTRAP        1      0    0    0
						return this.fixBool(this.owner.eval(this.valuename));
					}
				}
			}
			catch( e )
			{
				this.printf("%s:getValue failed:%s:%s\n", this.name, this.valuename, "message" in e ? e.message : e);
				::printException(e);
			}
		}

		return 0;
	}

	function setValue( value )
	{
		if (typeof this.setfunc == "function")
		{
			try
			{
				this.owner.execFunc(this.setfunc, value, this);
			}
			catch( e )
			{
				this.printf("%s:setValue failed:%s:%s\n", this.name, this.setfunc, "message" in e ? e.message : e);
			}
		}
		else if (this.valuename != null)
		{
			try
			{
				if (typeof this.valuename == "string")
				{
					if (this.valuename.charAt(0) == "!")
					{
						this.owner.eval(this.format("%s=%s", this.valuename.substr(1), value ? 0 : 1));
					}
					else
					{
						this.owner.eval(this.format("%s=%s", this.valuename, value));
					}
				}
			}
			catch( e )
			{
				this.printf("%s:setValue failed:%s:%s\n", this.name, this.valuename, "message" in e ? e.message : e);
			}
		}
	}

}

class this.MotionValue extends this.MotionParts
{
	varname = null;
	max = 0;
	valueInfo = null;
	change = null;
	varmap = null;
	varvalues = null;
	loop = false;
	diff = 1;
	orientation = 0;
	upKey = 0;
	downKey = 0;
	constructor( owner, elm, varnameDefault, maxDefault )
	{
		::MotionParts.constructor(owner, elm);
		this.varname = ::getval(elm, "varname", varnameDefault);
		this.max = ::getint(elm, "max", maxDefault);
		this.valueInfo = this.MotionValueInfo(owner, elm);
		this.change = ::getval(elm, "change");
		this.varmap = this.getObjectParam(elm, "varmap");

		if (this.varmap != null)
		{
			this.max = this.varmap.len() - 1;
		}

		this.varvalues = this.getObjectParam(elm, "varvalues");

		if (this.varvalues != null)
		{
			this.max = this.varvalues.len() - 1;
		}

		this.loop = ::getbool(elm, "loop", false);
		this.orientation = ::getint(elm, "orientation", 0);
		this.downKey = ::getint(elm, "downkey", this.orientation == 0 ? 32 : 64);
		this.upKey = ::getint(elm, "upkey", this.orientation == 0 ? 16 : 128);

		if (this.getint(elm, "swapdir"))
		{
			local t = this.upKey;
			this.upKey = this.downKey;
			this.downKey = t;
		}
	}

	function setVarValue( value )
	{
		if (this.varmap != null)
		{
			this.setVariable(this.varname, this.varmap[value]);
		}
		else
		{
			this.setVariable(this.varname, value);
		}
	}

	function getVarValue()
	{
		local ret = this.getVariable(this.varname);

		if (this.varmap != null)
		{
			foreach( i, v in this.varmap )
			{
				if (v == ret)
				{
					return i;
				}
			}
		}

		return ret;
	}

	function updateData( newvalue, drag = false, force = false )
	{
		local value = this.getVarValue();

		if (newvalue < 0)
		{
			newvalue = 0;
		}

		if (newvalue > this.max)
		{
			newvalue = this.max;
		}

		newvalue = this.valueInfo.checkLimit(newvalue);

		if (newvalue != value || force)
		{
			if (this.change != null || this.exp != null)
			{
				this.owner.onExecute();
			}

			this.owner.exec(this.change, this, newvalue, drag);
			this.setVarValue(newvalue);
			this.setValue(newvalue);
			this.owner.exec(this.exp, this, this.owner);
			return true;
		}
	}

	function updateToggle()
	{
		local newvalue = this.getVarValue() + 1;

		if (newvalue > this.max)
		{
			newvalue = 0;
		}

		return this.updateData(newvalue);
	}

	function setValue( value )
	{
		if (this.varvalues != null)
		{
			if (value >= 0 && value < this.varvalues.len())
			{
				value = this.varvalues[value];
			}
			else
			{
				value = 0;
			}
		}

		this.valueInfo.setValue(value);
	}

	function getValue()
	{
		local value = this.valueInfo.getValue();

		if (this.varvalues != null)
		{
			foreach( i, v in this.varvalues )
			{
				if (value == v)
				{
					return i;
				}
			}

			return 0;
		}

		return value;
	}

	function updateDiff( diff )
	{
		if (this.loop)
		{
			local value = this.getVarValue() + diff;

			if (value < 0)
			{
				value = this.max;
			}
			else if (value > this.max)
			{
				value = 0;
			}

			return this.updateData(value);
		}
		else
		{
			return this.updateData(this.getVarValue() + diff);
		}
	}

	function onInit( redraw = false )
	{
		::MotionParts.onInit(redraw);
		this.setVarValue(this.getValue());
	}

	function updateKeyDiff( diff )
	{
		return this.updateDiff(diff);
	}

	function onDownKey()
	{
		return this.updateKeyDiff(-this.diff);
	}

	function onUpKey()
	{
		return this.updateKeyDiff(this.diff);
	}

	function onKeyDown( input )
	{
		if (input.keyPressed(this.downKey))
		{
			return this.onDownKey();
		}
		else if (input.keyPressed(this.upKey))
		{
			return this.onUpKey();
		}

		return ::MotionParts.onKeyDown(input);
	}

}

class this.MotionSlider extends this.MotionValue
{
	valuemin = 0;
	valuemax = 0;
	slidername = null;
	constructor( owner, elm )
	{
		::MotionValue.constructor(owner, elm, "value", 1.0);
		this.diff = ::getfloat(elm, "diff", this.max / 10);
		this.valuemin = ::getfloat(elm, "valuemin", 0);
		this.valuemax = ::getfloat(elm, "valuemax", this.max);

		if (("reverse" in elm) && elm.reverse)
		{
			local n = this.valuemin;
			this.valuemin = this.valuemax;
			this.valuemax = n;
		}

		this.slidername = this.getLayerName(elm, "sliderlayer", this.laybase);

		if (this.slidername != null)
		{
			this.addLayerName(this.slidername);
		}
	}

	function onInit( redraw = false )
	{
		::MotionValue.onInit(redraw);
	}

	function setValue( value )
	{
		::MotionValue.setValue(value * (this.valuemax - this.valuemin) / this.max + this.valuemin);
	}

	function getValue()
	{
		return (::MotionValue.getValue() - this.valuemin) * this.max / (this.valuemax - this.valuemin);
	}

	function updateKnob( x, y, area, drag = false, force = false )
	{
		local length = this.orientation ? area.height : area.width;
		local value = this.orientation ? y - area.top : x - area.left;

		if (value < 0)
		{
			value = 0;
		}

		if (value > length)
		{
			value = length;
		}

		return this.updateData(this.max * value / length, drag, force);
	}

	dragging = false;
	function onMouseDown( x = 0, y = 0, shift = 0 )
	{
		this.dragging = false;

		if (this.checkContains(x, y, "knobarea", this.slidername))
		{
			this.dragging = true;
			return true;
		}

		local area = this.getLayerShape("area", this.slidername);

		if (area != null && area.contains(x, y))
		{
			this.updateKnob(x, y, area, true);
			this.dragging = true;
			return true;
		}
	}

	function onMouseMove( x, y, shift )
	{
		if (this.dragging)
		{
			local area = this.getLayerShape("area", this.slidername);

			if (area != null)
			{
				this.updateKnob(x, y, area, true);
			}
		}
	}

	function onMouseUp( x, y, shift )
	{
		if (this.dragging)
		{
			local area = this.getLayerShape("area", this.slidername);

			if (area != null)
			{
				this.updateKnob(x, y, area, false, true);
			}

			this.dragging = false;
			return true;
		}
	}

	function updateKeyDiff( diff )
	{
		local ret = this.updateDiff(diff);

		if (false)
		{
			this.owner.update();
			local pos = this.getHotSpot();

			if (pos != null)
			{
				this.owner.setCursorPos(pos.left, pos.top);
			}
		}

		return ret;
	}

	function getHotSpot()
	{
		local knob = this.getLayerShape("knobarea");

		if (knob != null)
		{
			switch(knob.type)
			{
			case 0:
			case 1:
				return {
					left = knob.left,
					top = knob.top
				};

			case 2:
			case 3:
				return {
					left = knob.left + knob.width / 2,
					top = knob.top + knob.height / 2
				};
				break;
			}
		}

		return null;
	}

}

class this.MotionToggle extends this.MotionValue
{
	toggleKey = 0;
	togglename = null;
	toggleArea = false;
	constructor( owner, elm )
	{
		::MotionValue.constructor(owner, elm, "state", 1);

		if (this.orientation == 2)
		{
			this.toggleKey = ::getint(elm, "togglekey", owner.TOGGLEKEY);
			this.downKey = 0;
			this.upKey = 0;
		}
		else
		{
			this.toggleKey = ::getint(elm, "togglekey", owner.TOGGLEKEY);
		}

		this.toggleArea = ::getbool(elm, "toggleArea", false);
		this.togglename = this.getLayerName(elm, "togglelayer", this.laybase);
	}

	function getArea( x, y )
	{
		for( local i = 0; i <= this.max; i++ )
		{
			if (this.checkContains(x, y, this.format("area%d", i), this.togglename))
			{
				return i;
			}
		}

		if (this.max == 1)
		{
			for( local i = 0; i <= this.max; i++ )
			{
				if (this.checkContains(x, y, i == 0 ? "offarea" : "onarea", this.togglename))
				{
					return i;
				}
			}
		}
	}

	function onPress( x = 0, y = 0, bind = false )
	{
		local n = this.getArea(x, y);

		if (n == null && this.toggleArea)
		{
			n = (this.getVariable(this.varname) + 1) % (this.max + 1);
		}

		if (n != null)
		{
			return this.updateData(n);
		}
	}

	function onKeyDown( input )
	{
		if (this.toggleKey && input.keyPressed(this.toggleKey))
		{
			return this.updateToggle();
		}
		else
		{
			return ::MotionValue.onKeyDown(input);
		}
	}

}

class this.MotionRadioGroup 
{
	owner = null;
	name = null;
	list = null;
	value = null;
	info = null;
	change = null;
	elm = null;
	constructor( owner, elm )
	{
		this.owner = owner.weakref();
		this.name = this.getval(elm, "group");
		this.info = this.MotionValueInfo(owner, elm);
		this.change = this.getval(elm, "change");
		this.elm = {
			name = this.name,
			type = "radio"
		};
		this.list = [];
	}

	function add( button )
	{
		this.list.append(button);
	}

	function onStart()
	{
	}

	function onInit( redraw = false )
	{
		this.value = this.info.getValue();

		foreach( i, button in this.list )
		{
			button.updateRadio(i == this.value);
		}
	}

	function onButton( button )
	{
		if (this.list[this.value] != button)
		{
			foreach( i, btn in this.list )
			{
				if (btn == button)
				{
					this.value = i;
					break;
				}
			}

			if (this.change != null || button.exp != null)
			{
				this.owner.onExecute();
			}

			try
			{
				this.owner.exec(this.change, this, this.value, false);
			}
			catch( e )
			{
				this.printf("%s:\x00e3\x0083\x00a9\x00e3\x0082\x00b8\x00e3\x0082\x00aa\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e5\x00a4\x0089\x00e6\x009b\x00b4\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:change:%s\n", this.name, this.change);
				::printException(e);
			}

			foreach( i, btn in this.list )
			{
				btn.updateRadio(this.value == i);
			}

			this.info.setValue(this.value);

			try
			{
				this.owner.exec(button.exp, button, this.owner);
			}
			catch( e )
			{
				if (e instanceof this.GameStateException)
				{
					throw e;
				}

				this.printf("%s:\x00e3\x0083\x00a9\x00e3\x0082\x00b8\x00e3\x0082\x00aa\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s:%s\n", this.name, button.name, button.exp);
				::printException(e);
			}
		}
	}

	function getButton( value )
	{
		if (value >= 0 && value < this.list.len())
		{
			return this.list[value];
		}
	}

}

class this.MotionRadio extends this.MotionParts
{
	group = null;
	varname = null;
	constructor( owner, elm )
	{
		::MotionParts.constructor(owner, elm);
		this.group = ::getval(elm, "group");
		this.varname = ::getval(elm, "varname", this.state);
	}

	function updateRadio( state )
	{
		local motion = this.getLayerMotion();

		if (motion != null)
		{
			this.setVariable(this.varname, state);
		}
	}

	function onPress( x = 0, y = 0, bind = false )
	{
		this.setSelect(4, 1);
		this.owner.onMotionRadioButton(this);

		if (bind && !this.enterFlag)
		{
			this.setSelect(0);
		}

		return true;
	}

	function onKeyDown( input )
	{
		if (this.getPressEnable() && input.keyPressed(this.KEY_OK))
		{
			this.onPress();
			return true;
		}

		::MotionParts.onKeyDown(input);
	}

}

function getLanguageText( text, langId )
{
	if (typeof text == "array")
	{
		local ret;

		if (typeof langId == "integer" && langId > 0 && langId < text.len())
		{
			ret = text[langId];
		}

		if (ret == null)
		{
			ret = text[0];
		}

		return ret;
	}

	return text;
}

class this.MotionTextInfo 
{
	owner = null;
	name = null;
	render = null;
	text = null;
	valueInfo = null;
	shape = null;
	filterfunc = null;
	fontSize = 0;
	rubySize = 0;
	lineHeight = 0;
	scale = 1.0;
	baseScale = true;
	textOption = null;
	textDefault = null;
	textVisible = false;
	textTimeScale = 1.0;
	textPos = null;
	initSize = false;
	textOffx = 0;
	textOffy = 0;
	function getFunc( elm, name )
	{
		return name in elm ? (typeof elm[name] == "string" ? this.owner.eval(elm[name]) : elm[name]) : null;
	}

	constructor( owner, elm, shapeDefault = "text", prefix = "" )
	{
		this.owner = owner.weakref();
		this.name = elm.name;

		if ("text" in elm)
		{
			this.text = elm.text;
		}
		else
		{
			this.valueInfo = this.MotionValueInfo(owner, elm, prefix);
		}

		this.fontSize = ::getval(elm, "fontSize", owner._owner.TEXT_SIZE);
		this.rubySize = ::getval(elm, "rubySize", this.fontSize / 3);
		this.lineHeight = ::getval(elm, "lineHeight", this.fontSize * 1.5);
		this.scale = ::getval(elm, "scale", 1.0);
		this.baseScale = ::getbool(elm, "baseScale", owner._owner.TEXT_BASESCALE);
		local color = ::getval(elm, "color", owner._owner.TEXT_COLOR);
		local shadow = ::getval(elm, "shadow", owner._owner.TEXT_SHADOW);
		local shadowcolor = ::getval(elm, "shadowColor", owner._owner.TEXT_SHADOWCOLOR);
		local shadowdiff = ::getval(elm, "shadowDiff", owner._owner.TEXT_SHADOWDIFF);
		this.textDefault = {
			color = color,
			shadow = shadow,
			shadowcolor = shadowcolor,
			shadowdiff = shadowdiff
		};
		this.assignDict(this.textDefault, ::getval(elm, "textDefault", owner._owner.TEXT_DEFAULT));
		this.textOption = {};
		this.assignDict(this.textOption, ::getval(elm, "textOption", owner._owner.TEXT_OPTION));
		local ignore = ::getval(elm, "textIgnore", owner._owner.TEXT_IGNORE);

		if (ignore != null)
		{
			foreach( name, value in ignore )
			{
				this.textOption["ignore_" + name] <- value;
			}
		}

		this.filterfunc = this.getFunc(elm, "filter");
		this.shape = ::getval(elm, prefix + "shape", shapeDefault);
		this.textOffx = ::getval(elm, prefix + "offsetx", 0);
		this.textOffy = ::getval(elm, prefix + "offsety", 0);
	}

	function renderFilter( text )
	{
		if (typeof text == "array")
		{
			local langId = this.owner.eval("languageId");
			text = ::getLanguageText(text, langId);
		}

		if (typeof this.filterfunc == "function")
		{
			text = this.filterfunc(text);
		}

		return text;
	}

	function _clearText()
	{
		if (this.render != null)
		{
			this.render.clear();
		}
	}

	function _setText( text = null, diff = 0, all = 0, indent = 0, font = null, context = null )
	{
		if (this.render != null)
		{
			text = this.renderFilter(text);

			if (text == null || text == "")
			{
				this.render.clear();
			}
			else
			{
				this.render.render(text, diff, all, indent, font, context);
			}
		}
	}

	function _addText( text = null, diff = 0, all = 0 )
	{
		if (this.render != null)
		{
			text = this.renderFilter(text);

			if (text != null && text != "")
			{
				this.render.add(text, diff, all);
			}
		}
	}

	function onStop( owner, layname = null )
	{
		switch(typeof this.shape)
		{
		case "string":
			local m;
			local s;

			if (layname != null)
			{
				m = owner.getLayerMotion(layname);
			}

			if (m == null)
			{
				s = owner.getLayerShape(this.shape);
			}
			else
			{
				s = this.getMotionLayerShape(m, this.shape);
			}

			if (s != null && (s.type == 2 || s.type == 3))
			{
				this.textPos = [
					::toint(s.left / this.scale),
					::toint(s.top / this.scale),
					::toint(s.width / this.scale),
					::toint(s.height / this.scale)
				];
			}
			else
			{
				if (s != null)
				{
					this.printf("%s:\x00e3\x0083\x00a9\x00e3\x0083\x0099\x00e3\x0083\x00ab\x00e7\x0094\x00a8\x00e3\x0081\x00ae\x00e3\x0082\x00b7\x00e3\x0082\x00a7\x00e3\x0082\x00a4\x00e3\x0083\x0097\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e3\x0081\x00af\x00e3\x0083\x00ac\x00e3\x0082\x00af\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e3\x0082\x00b0\x00e3\x0083\x00ab\x00e3\x0082\x00b7\x00e3\x0082\x00a7\x00e3\x0082\x00a4\x00e3\x0083\x0097\x00e3\x0082\x0092\x00e4\x00bd\x00bf\x00e3\x0081\x00a3\x00e3\x0081\x00a6\x00e3\x0081\x008f\x00e3\x0081\x00a0\x00e3\x0081\x0095\x00e3\x0081\x0084:%s\n", this.name, this.shape);
				}
				else
				{
					this.printf("%s:\x00e3\x0083\x00a9\x00e3\x0083\x0099\x00e3\x0083\x00ab\x00e7\x0094\x00a8\x00e3\x0081\x00ae\x00e3\x0082\x00b7\x00e3\x0082\x00a7\x00e3\x0082\x00a4\x00e3\x0083\x0097\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e3\x0081\x008c\x00e8\x00a6\x008b\x00e3\x0081\x00a4\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0081\x0084:%s\n", this.name, this.shape);
				}

				this.textPos = [
					0,
					0,
					::toint(this.fontSize * owner._owner.TEXT_COLUMNS),
					::toint(this.lineHeight * owner._owner.TEXT_LINES)
				];
			}

			break;

		case "table":
			this.textPos = [
				::getval(this.shape, "left", 0),
				::getval(this.shape, "top", 0),
				::getval(this.shape, "width", ::toint(this.fontSize * owner._owner.TEXT_COLUMNS)),
				::getval(this.shape, "height", ::toint(this.lineHeight * owner._owner.TEXT_LINES))
			];
			break;

		case "array":
			this.textPos = this.shape;
			break;

		default:
			this.textPos = null;
			break;
		}

		this.initSize = true;
		this.onInit(true);
	}

	function onInit( redraw = false )
	{
		if (!this.initSize)
		{
			return;
		}

		if (this.render == null || redraw)
		{
			this.render = this.owner.createRender(this.fontSize, this.rubySize, this.lineHeight, this.scale, this.baseScale);
			this.render.setTimeScale(this.textTimeScale);
			this.render.setOption(this.textOption);
			this.render.setDefault(this.textDefault);

			if (this.textPos != null)
			{
				this.render.setPos(this.textPos[0] + this.textOffx, this.textPos[1] + this.textOffy, this.textPos[2], this.textPos[3]);
			}

			this.render.visible = this.textVisible;
		}

		local value = this.text != null ? this.text : this.valueInfo != null ? this.valueInfo.getValue() : null;

		if (value != null)
		{
			switch(typeof value)
			{
			case "array":
				if (value[0] != null)
				{
					local indent = value.len() > 2 ? value[2] : 0;
					local font = value.len() > 3 ? value[3] : null;
					local context = value.len() > 4 ? value[4] : null;
					this._setText(value[0], 0, 0, indent, font, context);

					if (value.len() > 1 && value[1] != null)
					{
						this.render.setShowCount(value[1]);
					}
				}
				else
				{
					this._clearText();
				}

				break;

			case "table":
				if ("text" in value)
				{
					this._setText(value.text, 0, 0, ::getval(value, "indent", 0), ::getval(value, "font"), ::getval(value, "context"));
				}

				if ("showCount" in value)
				{
					this.render.setShowCount(value.showCount);
				}

				if ("offsetx" in value || "offsety" in value)
				{
					this.render.setOffsetPos(::getval(value, "offsetx", 0), ::getval(value, "offsety", 0));
				}

				break;

			case "string":
				this._setText(value);
				break;
			}
		}
		else
		{
			this._clearText();
		}
	}

	function setVisible( v )
	{
		if (this.render != null)
		{
			this.render.visible = v;
		}

		this.textVisible = v;
	}

	function setText( text = null, diff = 0, all = 0, indent = 0 )
	{
		if (text == null)
		{
			this.text = "";
		}
		else
		{
			this.text = [
				text,
				null,
				indent
			];
		}

		this._setText(text, diff, all, indent);
	}

	function addText( text = null, diff = 0, all = 0 )
	{
		if (text != null)
		{
			switch(typeof this.text)
			{
			case "array":
				this.text[0] = ::catLangText(this.text[0], text);
				break;

			case "string":
				this.text += text;

			default:
				this.text = text;
			}

			this._addText(text, diff, all);
		}
	}

	function clearText()
	{
		this.text = "";
		this._clearText();
	}

	function setTextDefault( init )
	{
		if (init != null)
		{
			this.assignDict(this.textDefault, init);

			if (this.render != null)
			{
				this.render.setDefault(init);
			}
		}
	}

	function getRenderBounds()
	{
		return this.render != null ? this.render.getRenderBounds() : null;
	}

	function getScrollMax()
	{
		return this.render != null ? this.render.calcMaxScrollOffsetLine() : 0;
	}

	function setScroll( n )
	{
		if (this.render != null)
		{
			this.render.setOffsetLine(n);
		}
	}

	function setOffset( x, y )
	{
		if (this.render != null)
		{
			this.render.setOffsetPos(x, y);
		}
	}

	function getRenderOver()
	{
		return this.render != null ? this.render.getRenderOver() : 0;
	}

	function getRenderCount()
	{
		return this.render != null ? this.render.getRenderCount() : 0;
	}

	function getRenderDelay()
	{
		return this.render != null ? this.render.getRenderDelay() : 0;
	}

	function setShowCount( count )
	{
		if (this.render != null)
		{
			this.render.setShowCount(count);
		}
	}

	function calcShowCount( currentTime )
	{
		return this.render != null ? this.render.calcShowCount(currentTime) : 0;
	}

	function getKeyWait()
	{
		return this.render != null ? this.render.getKeyWait() : null;
	}

	function setOption( n, v )
	{
		this.textOption[n] <- v;

		if (this.render != null)
		{
			local r = {};
			r[n] <- v;
			return this.render.setOption(r);
		}
	}

	function getTimeScale()
	{
		if (this.render != null)
		{
			return this.render.getTimeScale();
		}
		else
		{
			return this.textTimeScale;
		}
	}

	function setTimeScale( scale )
	{
		this.textTimeScale = scale;

		if (this.render != null)
		{
			this.render.setTimeScale(scale);
		}
	}

}

class this.MotionImageInfo 
{
	owner = null;
	name = null;
	picture = null;
	storage = null;
	valueInfo = null;
	shape = null;
	scale = null;
	x = 0;
	y = 0;
	width = 0;
	height = 0;
	scalex = 1.0;
	scaley = 1.0;
	pictureVisible = false;
	pictureStorage = null;
	pictureOptions = null;
	initSize = false;
	constructor( owner, elm, shapeDefault = "image", prefix = "" )
	{
		this.owner = owner.weakref();
		this.name = elm.name;

		if ("storage" in elm)
		{
			this.storage = elm.storage;
		}
		else
		{
			this.valueInfo = this.MotionValueInfo(owner, elm, prefix);
		}

		this.shape = ::getval(elm, prefix + "shape", shapeDefault);
		this.scale = ::getval(elm, prefix + "scale", 1.0);
	}

	function onStop( owner, layname = null )
	{
		switch(typeof this.shape)
		{
		case "string":
			local m;
			local s;

			if (layname != null)
			{
				m = owner.getLayerMotion(layname);
			}

			if (m == null)
			{
				s = owner.getLayerShape(this.shape);
			}
			else
			{
				s = this.getMotionLayerShape(m, this.shape);
			}

			if (s != null && (s.type == 2 || s.type == 3))
			{
				this.width = s.width;
				this.height = s.height;
				this.x = s.left + this.width / 2;
				this.y = s.top + this.height / 2;
			}

			break;

		case "array":
			if (this.shape.len() >= 3)
			{
				this.width = this.shape[2];
				this.height = this.shape[3];
				this.x = this.shape[0] + this.width / 2;
				this.y = this.shape[1] + this.height / 2;
			}
			else if (this.shape.len() >= 2)
			{
				this.x = this.shape[0];
				this.y = this.shape[1];
			}

			break;

		case "table":
			this.width = "width" in this.shape ? this.shape.width : 0;
			this.height = "height" in this.shape ? this.shape.height : 0;

			if ("left" in this.shape)
			{
				this.x = this.shape.left + this.width / 2;
			}
			else if ("x" in this.shape)
			{
				this.x = this.shape.x;
			}

			if ("top" in this.shape)
			{
				this.y = this.shape.top + this.height / 2;
			}
			else if ("y" in this.shape)
			{
				this.y = this.shape.y;
			}

			break;

		default:
			break;
		}

		switch(typeof this.scale)
		{
		case "array":
			this.scalex = this.scale[0];
			this.scaley = this.scale[1];
			break;

		case "table":
			this.scalex = ::getval(this.scale, "x", 1.0);
			this.scaley = ::getval(this.scale, "y", 1.0);
			break;

		case "integer":
		case "float":
			this.scalex = this.scaley = this.scale;
			break;
		}

		this.initSize = true;
		this.onInit(true);
	}

	function onInit( redraw = false )
	{
		if (!this.initSize)
		{
			return;
		}

		local file = this.storage != null ? this.storage : this.valueInfo.getValue({
			width = this.width,
			height = this.height
		});

		if (redraw || !this.equals(file, this.pictureStorage))
		{
			if (file != null)
			{
				this.picture = this.owner.createPicture(file);
				this.pictureStorage = clone file;
			}
			else
			{
				this.picture = null;
				this.pictureStorage = null;
			}
		}

		if (this.picture != null)
		{
			this.picture.setOffset(-this.x, -this.y);

			if (this.picture.width > 0 && this.picture.height > 0)
			{
				if (this.width > 0 && this.height > 0)
				{
					local sx = this.width / this.picture.width;
					local sy = this.height / this.picture.height;
					this.picture.setScale(sx, sy);
				}
			}
			else if (this.scalex != 1.0 || this.scaley != 1.0)
			{
				this.picture.setScale(this.scalex, this.scaley);
			}

			this.picture.setVisible(this.pictureVisible);

			if (this.pictureOptions != null)
			{
				this.picture.setOptions(this.options);
			}
		}
	}

	function setVisible( v )
	{
		if (this.picture != null)
		{
			this.picture.setVisible(v);
		}

		this.pictureVisible = v;
	}

	function setImageOptions( options )
	{
		if (this.pictureOptions == null)
		{
			this.pictureOptions = {};
		}

		this.assignDict(this.pictureOptions, options);

		if (this.picture != null)
		{
			this.picture.setOptions(options);
		}
	}

}

class this.MotionExternal extends this.MotionBase
{
	info = null;
	constructor( owner, elm, infoClass = null )
	{
		::MotionBase.constructor(owner, elm);
		this.info = infoClass != null ? infoClass(owner, elm, this.name) : null;
	}

	function isText()
	{
		return this.info instanceof this.MotionTextInfo;
	}

	function isImage()
	{
		return this.info instanceof this.MotionImageInfo;
	}

	function onInit( redraw = false )
	{
		if (this.info)
		{
			this.info.onInit(redraw);
		}

		::MotionBase.onInit(redraw);
	}

	function onStop()
	{
		if (this.info)
		{
			this.info.onStop(this.owner, this.layname);
		}
	}

	function setExternalVisible( v )
	{
		if (this.info)
		{
			this.info.setVisible(v);
		}
	}

	function setText( text, diff = 0, all = 0, indent = 0 )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setText(text, diff, all, indent);
		}
	}

	function addText( text, diff = 0, all = 0 )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.addText(text, diff, all);
		}
	}

	function clearText()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.clearText();
		}
	}

	function setTextDefault( init )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setTextDefault(init);
		}
	}

	function getRenderBounds()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getRenderBounds();
		}
	}

	function getScrollMax()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getScrollMax();
		}

		return 0;
	}

	function setScroll( n )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.setScroll(n);
		}
	}

	function setOffset( x, y )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setOffset(x, y);
		}
	}

	function getRenderOver()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getRenderOver();
		}

		return false;
	}

	function getRenderCount()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getRenderCount();
		}

		return 0;
	}

	function getRenderDelay()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getRenderDelay();
		}

		return 0;
	}

	function setShowCount( count )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setShowCount(count);
		}
	}

	function calcShowCount( currentTime )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.calcShowCount(currentTime);
		}

		return 0;
	}

	function getKeyWait()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getKeyWait();
		}

		return null;
	}

	function setOption( n, v )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setOption(n, v);
		}
	}

	function getTimeScale()
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			return this.info.getTimeScale();
		}

		return 1.0;
	}

	function setTimeScale( scale )
	{
		if (this.info instanceof this.MotionTextInfo)
		{
			this.info.setTimeScale(scale);
		}
	}

	function setImageOptions( options )
	{
		if (this.info instanceof this.MotionImageInfo)
		{
			this.info.setImageOptions(options);
		}
	}

}

class this.MotionPanel extends ::BasePicture
{
	TOGGLEKEY = 0;
	PREVKEY = 0;
	NEXTKEY = 0;
	COLUMNS = null;
	ROWS = null;
	noLoop = false;
	nextRow = false;
	nextCol = false;
	choiceMode = false;
	eventEnabled = false;
	mainPanel = false;
	constructor( owner, main = false )
	{
		::BasePicture.constructor(owner);
		::Object.setDelegate(this._owner);
		this.mainPanel = main;
		this._motionItemsCount = 0;
		this._motionButtons = [];
		this._motionButtonMap = {};
		this._motionParts = [];
		this._motionPartsMap = {};
		this._motionBinds = [];
		this._motionFuncBinds = [];
		this._motionGestureBinds = [];
		this._motionTimeouts = [];
		this._motionRadioGroup = {};
		this._motionInfos = [];
		this._motionInfoMap = {};
		this._motionAreas = [];
		this._motionExternalMap = {};
		this._motionCommonMap = {};
		this.checktouch = "getMovePos" in ::Input;
		this._owner.entryPanel(this);
	}

	function destructor()
	{
		this._doneThread();
		this.doneMotion();

		if (this._owner != null)
		{
			this._owner.removePanel(this);
		}

		::BasePicture.destructor();
	}

	function getOwnerLayer()
	{
		return this._owner;
	}

	function getMotionInfo()
	{
		return this.minfo;
	}

	function onAction( label, action )
	{
		this.execMotionFunc("onAction", label, action);
	}

	function findFont( size, face = null, style = 0 )
	{
		local ret;

		if (this.mfont != null)
		{
			ret = this.mfont.findFont(size, face, style);
		}

		if (ret == null)
		{
			ret = ::BasePicture.findFont(size, face, style);
		}

		return ret;
	}

	function setEventEnabled( enabled )
	{
		if (this.eventEnabled != enabled)
		{
			this.eventEnabled = enabled;

			if (this.mplayer != null)
			{
				this.mplayer.eventEnabled = this.eventEnabled;
			}
		}
	}

	function getEventEnabled()
	{
		return this.eventEnabled;
	}

	function getCurrentTick()
	{
		return ::getCurrentTick() * 1000 / 60;
	}

	function eval( exp )
	{
		if (typeof exp == "function")
		{
			return this._execFunc(exp);
		}
		else
		{
			return ::eval(exp, this.minfo);
		}
	}

	function evalCond( name, cond )
	{
		try
		{
			if (typeof cond == "string")
			{
				cond = this.eval(cond);
			}

			if (typeof cond == "function")
			{
				  // [013]  OP_POPTRAP        1      0    0    0
				return cond(this);
			}
			else
			{
				  // [016]  OP_POPTRAP        1      0    0    0
				return cond;
			}
		}
		catch( e )
		{
			this.printf("%s:\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e5\x0087\x00a6\x00e7\x0090\x0086\x00e3\x0081\x00a7\x00e4\x00be\x008b\x00e5\x00a4\x0096:%s:%s\n", $[stack offset 1], cond, "message" in e ? e.message : e);
		}

		return false;
	}

	mplayer = null;
	minfo = null;
	mfont = null;
	mmain = null;
	mtouch = null;
	manalog = null;
	manalogr = null;
	mcontains = null;
	_motionStorage = null;
	_motionIcons = null;
	_motionOpened = false;
	_motionPlaying = false;
	_motionRedraw = 0;
	_motionExternalVisible = null;
	_motionLock = false;
	_motionWork = false;
	_motionExec = null;
	_motionItemsCount = 0;
	_motionButtons = null;
	_motionButtonMap = null;
	_motionParts = null;
	_motionPartsMap = null;
	_motionBinds = null;
	_motionFuncBinds = null;
	_motionGestureBinds = null;
	_motionTimeouts = null;
	_motionStartTime = null;
	_motionRadioGroup = null;
	_motionInfos = null;
	_motionInfoMap = null;
	_motionAreas = null;
	_motionExternalMap = null;
	_motionCommonMap = null;
	_motionFocus = null;
	_motionMouseFocus = null;
	_motionDropFocus = null;
	_motionGrab = false;
	function clearMotionButtons()
	{
		this.doneGesture();
		this.setMotionFocus(null, true);
		this._motionGrab = false;
		this._motionInfos.clear();
		this._motionInfoMap.clear();
		this._motionAreas.clear();
		this._motionExternalMap.clear();
		this._motionButtons.clear();
		this._motionButtonMap.clear();
		this._motionParts.clear();
		this._motionPartsMap.clear();
		this._motionBinds.clear();
		this._motionFuncBinds.clear();
		this._motionGestureBinds.clear();
		this._motionTimeouts.clear();
		this._motionRadioGroup.clear();
		this._motionItemsCount = 0;
		this._motionStartTime = null;
		this._motionMouseFocus = null;
		this._motionDropFocus = null;
	}

	function _addMotionBase( info )
	{
		this._motionInfos.append(info);
		this._motionInfoMap[info.name] <- info;
	}

	function _addMotionExternal( external )
	{
		this._motionExternalMap[external.name] <- external;
		this._motionItemsCount++;
	}

	function _addMotionButton( button )
	{
		this._motionButtons.append(button);
		this._motionButtonMap[button.name] <- button;
		local append = false;

		if (typeof button.layname == "array" || button.layname != "")
		{
			this._motionParts.append(button);
			this._motionPartsMap[button.name] <- button;
			append = true;
		}

		if (("bind" in button) && button.bind != null)
		{
			this._motionBinds.append(button);
			append = true;
		}

		if (("funcbind" in button) && button.funcbind != null)
		{
			this._motionFuncBinds.append(button);
			append = true;
		}

		if (("gesture" in button) && button.gesture != null)
		{
			this._motionGestureBinds.append(button);
			append = true;
		}

		if (("timeout" in button) && button.timeout != null || ("waitfunc" in button) && button.waitfunc != null)
		{
			this._motionTimeouts.append(button);
			append = true;
		}

		if (append)
		{
			this._motionItemsCount++;
		}
	}

	function addMotionButton( elm )
	{
		if (this.mplayer != null)
		{
			if (!("name" in elm))
			{
				throw this.Exception("\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e5\x0090\x008d\x00e3\x0081\x008c\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093");
			}

			local type = ::getval(elm, "type");

			switch(type)
			{
			case "init":
				break;

			case "info":
				this._addMotionBase(::MotionBase(this, elm));
				break;

			case "digit":
				this._addMotionBase(::MotionBase(this, elm, ""));
				break;

			case "text":
				this._addMotionExternal(::MotionExternal(this, elm, ::MotionTextInfo));
				break;

			case "image":
				this._addMotionExternal(::MotionExternal(this, elm, ::MotionImageInfo));
				break;

			case "area":
				this._motionAreas.append(this.MotionArea(this, elm));
				break;

			case "button":
				this._addMotionButton(this.MotionButton(this, elm));
				break;

			case "slider":
				this._addMotionButton(this.MotionSlider(this, elm));
				break;

			case "toggle":
				this._addMotionButton(this.MotionToggle(this, elm));
				break;

			case "radio":
				if (!("group" in elm))
				{
					throw this.Exception(this.format("%s:\x00e3\x0083\x00a9\x00e3\x0082\x00b8\x00e3\x0082\x00aa\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e3\x0082\x00b0\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x0097\x00e5\x0090\x008d\x00e3\x0081\x008c\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093", elm.name));
				}
				else
				{
					local group;

					if (elm.group in this._motionRadioGroup[elm.group])
					{
						group = this._motionRadioGroup[elm.group];
					}
					else
					{
						group = this.MotionRadioGroup(this, elm);
						this._motionRadioGroup[elm.group] <- group;
					}

					local radio = this.MotionRadio(this, elm);
					group.append(radio);
					this._addMotionButton(radio);
				}

				break;

			default:
				this.printf("%s:\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0081\x00aa\x00e3\x0083\x0091\x00e3\x0083\x00bc\x00e3\x0083\x0084\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x0097:%s\n", elm.name, type);
			}

			this._motionLock = false;
		}
	}

	function _addMotionCommon( external )
	{
		this._motionCommonMap[external.name] <- external;
	}

	function addMotionCommon( elm )
	{
		local type = ::getval(elm, "type");

		switch(type)
		{
		case "systext":
			this._addMotionCommon(::MotionExternal(this, elm, ::MotionTextInfo));
			break;

		case "sysimage":
			this._addMotionCommon(::MotionExternal(this, elm, ::MotionImageInfo));
			break;
		}
	}

	function _margeButtonInfo( key, value, info )
	{
		if (value == null)
		{
			if (key in info)
			{
				delete info[key];
			}
		}
		else
		{
			switch(key)
			{
			case "enter":
			case "leave":
			case "exp":
			case "change":
				if (typeof value == "array")
				{
					foreach( v in value )
					{
						this._margeButtonInfo(key, v, info);
					}
				}
				else if (!(key in info))
				{
					info[key] <- value;
				}
				else if (typeof info[key] == "array")
				{
					info[key].append(value);
				}
				else
				{
					info[key] <- [
						info[key],
						value
					];
				}

				break;

			default:
				info[key] <- value;
				break;
			}
		}
	}

	function margeButtonInfo( info, src )
	{
		if ("getValue" in src)
		{
			foreach( key, value in src )
			{
				this._margeButtonInfo(key, src.getValue(key), info);
			}
		}
		else
		{
			foreach( key, value in src )
			{
				this._margeButtonInfo(key, value, info);
			}
		}
	}

	function getInfoValue( i, info )
	{
		if (typeof info == "string" && info.len() > 1 && info.charAt(0) == "@")
		{
			try
			{
				info = this.eval(info.substr(1));
			}
			catch( e )
			{
				this.printf("\x00e3\x0083\x00a2\x00e3\x0083\x00bc\x00e3\x0082\x00b7\x00e3\x0083\x00a7\x00e3\x0083\x00b3\x00e3\x0083\x0087\x00e3\x0083\x00bc\x00e3\x0082\x00bf:%d:%s:\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", i, info, "message" in e ? e.message : e);
				info = null;
			}
		}
		else if (typeof info == "table")
		{
			local ret = {};

			foreach( name, value in info )
			{
				ret[name] <- this.getInfoValue(i, value);
			}

			info = ret;
		}

		return info;
	}

	function _addMotionInfo( buttonlist, value, scale )
	{
		if (scale == null)
		{
			buttonlist.append(value);
		}
		else
		{
			local v = {};

			foreach( name, data in value )
			{
				v[name] <- data;
			}

			v.scale <- scale;
			buttonlist.append(v);
		}
	}

	function addMotionInfo( buttonlist, infolist, scale = null )
	{
		if (typeof infolist == "table")
		{
			foreach( key, value in infolist )
			{
				if (key == "buttonlist")
				{
					if (typeof value == "array")
					{
						foreach( v in value )
						{
							this._addMotionInfo(buttonlist, v, scale);
						}
					}
					else
					{
						this._addMotionInfo(buttonlist, this.v, scale);
					}
				}
				else
				{
					this.minfo.entryParam(key, value);
					  // [030]  OP_JMP            0      0    0    0
				}
			}
		}
		else if (typeof infolist == "array")
		{
			local count = infolist.len();

			for( local i = 0; i < count; i++ )
			{
				local info = this.getInfoValue(i, infolist[i]);

				if (typeof info == "function")
				{
					info = this.execFunc(info, this);
				}

				switch(typeof info)
				{
				case "table":
					this._addMotionInfo(buttonlist, info, scale);
					break;

				case "array":
					foreach( value in info )
					{
						this._addMotionInfo(buttonlist, value, scale);
					}

					break;

				case "string":
					i++;
					this.minfo.entryParam(info, this.getInfoValue(i, infolist[i]));
					break;
				}
			}
		}
	}

	function getMotionPlaying()
	{
		return this._motionPlaying || this.mplayer != null && this.mplayer.playing;
	}

	function getMotionLock()
	{
		return this._motionLock || this.mplayer == null || this.mplayer.playing || this._motionItemsCount == 0;
	}

	function calcMotion( focus )
	{
		if (typeof focus == "string")
		{
			local n;

			foreach( i, motion in this._motionParts )
			{
				if (focus == motion.name)
				{
					n = i;
					break;
				}
			}

			focus = n;
		}

		return focus;
	}

	function getMotionFocus()
	{
		return this._motionFocus != null ? this._motionParts[this._motionFocus] : null;
	}

	function getMotionFocusName()
	{
		return this._motionFocus != null ? this._motionParts[this._motionFocus].name : null;
	}

	function updateMotionFocus( init )
	{
		foreach( i, button in this._motionParts )
		{
			button.updateFocus(this._motionFocus == i || this._motionMouseFocus == i || this._motionDropFocus == i, init);
		}
	}

	function setMotionFocus( focus, init = false )
	{
		focus = this.calcMotion(focus);

		if (focus == null || focus >= 0 && focus < this._motionParts.len())
		{
			if (this._motionFocus != focus)
			{
				local old = this._motionFocus;
				this._motionFocus = focus;
				this.updateMotionFocus(init);

				if (old != null)
				{
					this._motionParts[old].onFocusChange(false, init);
				}

				if (this._motionFocus != null)
				{
					this._motionParts[this._motionFocus].onFocusChange(true, init);
				}

				if (this.mainPanel && this._owner)
				{
					this._owner.onMotionFocusChange(old, this._motionFocus);
				}

				this.execMotionFunc("onFocusChange", old, this._motionFocus);
			}
			else
			{
				this.updateMotionFocus(init);
			}
		}
	}

	function moveCursorMotionFocus( to )
	{
		if (to != null)
		{
			this.setMotionFocus(to);
		}

		local pos = this._motionParts[this._motionFocus].getHotSpot();

		if (pos != null)
		{
		}
	}

	function getMotionFunc( funcName )
	{
		if (this.minfo != null && this.minfo.hasParam(funcName))
		{
			local func = this.minfo[funcName];

			if (typeof func == "string")
			{
				try
				{
					func = this.eval(func);
				}
				catch( e )
				{
					this.printf("execMotionFunc:%s:%s:\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", funcName, func, func, "message" in e ? e.message : e);
				}
			}

			return func;
		}
	}

	function execMotionFunc( funcName, ... )
	{
		local func = this.getMotionFunc(funcName);

		if (func != null)
		{
			local args = [];

			for( local i = 0; i < vargc; i++ )
			{
				args.append(vargv[i]);
			}

			try
			{
				return this._execFunc(func, args);
				  // [022]  OP_POPTRAP        1      0    0    0
			}
			catch( e )
			{
				this.printf("%s:\x00e3\x0083\x00a2\x00e3\x0083\x00bc\x00e3\x0082\x00b7\x00e3\x0083\x00a7\x00e3\x0083\x00b3\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e9\x0096\x00a2\x00e6\x0095\x00b0\x00e5\x0091\x00bc\x00e3\x0081\x00b3\x00e5\x0087\x00ba\x00e3\x0081\x0097\x00e4\x00b8\x00ad\x00e3\x0081\x00ab\x00e4\x00be\x008b\x00e5\x00a4\x0096:%s\n", funcName, "message" in e ? e.message : e);
				::printException(e);
			}
		}
	}

	function checkStartMotion()
	{
		if (!this._motionPlaying)
		{
			local motion = this.mplayer.motion;

			if (this.minfo.hasParam("startvar"))
			{
				this.setVariables(this.minfo.startvar, "startvar");
			}

			this.update();

			if (this.mainPanel && this._owner)
			{
				this._owner.onMotionStart(motion);
			}

			this.execMotionFunc("onStart", motion);

			foreach( id, value in this._motionAreas )
			{
				value.onStart();
			}

			foreach( id, value in this._motionButtons )
			{
				value.onStart();
			}

			foreach( key, value in this._motionExternalMap )
			{
				value.onStart();
			}

			foreach( key, value in this._motionRadioGroup )
			{
				value.onStart();
			}

			this.update();

			foreach( id, value in this._motionInfos )
			{
				value.onStart();
			}

			this._motionPlaying = true;
		}
	}

	function checkInit()
	{
		if (this._motionRedraw > 0)
		{
			this.clearPicture();
			::BasePicture.clearText();

			try
			{
				local init = this._motionRedraw == 1;
				local motion = this.mplayer.motion;

				if (this.mainPanel && this._owner)
				{
					this._owner.onMotionPreInit(motion);
				}

				this.execMotionFunc("onPreInit", motion, init);

				if (this.minfo.hasParam("initvar"))
				{
					this.setVariables(this.minfo.initvar, "initvar");
				}

				this.update();

				foreach( id, value in this._motionAreas )
				{
					value.onInit(true);
				}

				foreach( id, value in this._motionButtons )
				{
					value.onInit(true);
				}

				foreach( key, value in this._motionCommonMap )
				{
					value.onInit(true);
				}

				foreach( key, value in this._motionExternalMap )
				{
					value.onInit(true);
				}

				foreach( key, value in this._motionRadioGroup )
				{
					value.onInit(true);
				}

				this.update();

				foreach( id, value in this._motionInfos )
				{
					value.onInit(true);
				}

				if (motion == "hide" || this._motionExternalVisible != null && !this._motionExternalVisible)
				{
					this.setExternalVisible(false);
				}

				if (this.mainPanel && this._owner)
				{
					this._owner.onMotionInit(motion);
				}

				this.execMotionFunc("onInit", motion, init);
			}
			catch( e )
			{
				this.printf("\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e5\x0087\x00a6\x00e7\x0090\x0086\x00e4\x00b8\x00ad\x00e3\x0081\x00ab\x00e4\x00be\x008b\x00e5\x00a4\x0096:%s\n", "message" in e ? e.message : e);
				::printException(e);
			}

			this.checkMotionFocus();
			this._motionRedraw = 0;
			this._motionExternalVisible = null;
		}
	}

	function checkStopMotion()
	{
		if (this._motionPlaying)
		{
			this.checkInit();
			this._motionPlaying = false;

			try
			{
				foreach( id, value in this._motionButtons )
				{
					value.onStop();
				}

				foreach( key, value in this._motionCommonMap )
				{
					value.onStop();
				}

				foreach( key, value in this._motionExternalMap )
				{
					value.onStop();
				}

				local motion = this.mplayer.motion;

				if (motion != "hide")
				{
					this.setExternalVisible(true);
				}

				if (this.mainPanel && this._owner)
				{
					this._owner.onMotionStop(motion);
				}

				this.execMotionFunc("onStop", motion);
			}
			catch( e )
			{
				this.printf("\x00e5\x0081\x009c\x00e6\x00ad\x00a2\x00e5\x0087\x00a6\x00e7\x0090\x0086\x00e4\x00b8\x00ad\x00e3\x0081\x00ab\x00e4\x00be\x008b\x00e5\x00a4\x0096:%s\n", "message" in e ? e.message : e);
				::printException(e);
			}
		}
	}

	function checkButtonContains( button, x, y )
	{
		if (this.mcontains && !this.getMotionLock())
		{
			return this._execFunc(this.mcontains, [
				button,
				x,
				y
			]);
		}
	}

	function checkMouseMove( x, y, init = false )
	{
		foreach( area in this._motionAreas )
		{
			area.checkMouseMove(x, y);
		}

		if (!this._motionGrab)
		{
			local oldFocus = this._motionMouseFocus;
			this._motionMouseFocus = null;

			foreach( i, button in this._motionParts )
			{
				if (button.getPressEnable() && button.checkMouseMove(x, y))
				{
					this._motionMouseFocus = i;
					break;
				}
			}

			if (oldFocus != this._motionMouseFocus)
			{
				this.updateMotionFocus(init);
			}
		}
	}

	function _internalOnMouseMove( x, y, shift, init = false )
	{
		this.checkMouseMove(x, y, init);

		if (this._motionMouseFocus != null)
		{
			this._motionParts[this._motionMouseFocus].onMouseMove(x, y, shift);
			this.update();
		}
	}

	function _internalOnMouseLeave()
	{
		this._motionGrab = false;
		this._motionMouseFocus = null;
		this.updateMotionFocus(true);
	}

	function onMouseMove( x, y, shift = 0, init = false )
	{
		if (!this.getMotionLock())
		{
			this._internalOnMouseMove(x, y, shift, init);
		}
	}

	function onMouseDown( x, y, shift = 0 )
	{
		if (!this.getMotionLock())
		{
			if (this._motionMouseFocus != null)
			{
				local button = this._motionParts[this._motionMouseFocus];

				if (button.getPressEnable())
				{
					if (button.onMouseDown(x, y, shift))
					{
						this._motionGrab = true;
						this.applyMouseMotionFocus(true);
						this.update();
						return true;
					}
				}
			}
		}
	}

	function onMouseUp( x, y, shift = 0 )
	{
		if (!this.getMotionLock())
		{
			local ret;

			if (this._motionMouseFocus != null)
			{
				local button = this._motionParts[this._motionMouseFocus];
				local doup = button.onMouseUp(x, y, shift);

				if (doup != null)
				{
					ret = true;
				}

				if (button.getPressEnable(true) && (doup == null || doup))
				{
					if (button.onPress(x, y, this._motionMouseFocus != this._motionFocus))
					{
						ret = true;
					}
				}

				this.update();
			}

			if (this._motionGrab)
			{
				this._motionGrab = false;
				this.checkMouseMove(x, y);
			}

			return ret;
		}
	}

	function onMouseLeave()
	{
		this._internalOnMouseLeave();
	}

	function getLayerPosition( name )
	{
		local lgetter = this.getMotionLayerGetter(this.mplayer, name);

		if (lgetter != null)
		{
			return {
				left = lgetter.left,
				top = lgetter.top
			};
		}
	}

	function getLayer( name )
	{
		return this.getMotionLayerGetter(this.mplayer, name);
	}

	function getLayerMotion( name )
	{
		return this.getMotionLayerMotion(this.mplayer, name);
	}

	function getLayerShape( name )
	{
		return this.getMotionLayerShape(this.mplayer, name);
	}

	function setVariable( name, value, flag = 0, time = 0, accel = 0 )
	{
		if (this.mplayer != null)
		{
			if (time > 0)
			{
				this.mplayer.animateVariable(name, value, time * 60 / 1000, accel);
			}
			else
			{
				this.mplayer.setVariable(name, value, flag);
			}
		}
	}

	function setVariables( vars, type )
	{
		foreach( name, exp in vars )
		{
			try
			{
				if (typeof exp == "table")
				{
					this.setVariable(name, this.eval(::getval(exp, "value")), ::getval(exp, "flag"), ::getval(exp, "time"), ::getval(exp, "accel"));
				}
				else
				{
					this.setVariable(name, this.eval(exp));
				}
			}
			catch( e )
			{
				this.printf("%s:\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x0088\x009d\x00e6\x009c\x009f\x00e5\x008c\x0096\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s:%s\n", type, name, exp);
				::printException(e);
			}
		}
	}

	function getVariable( name )
	{
		if (this.mplayer != null)
		{
			return this.mplayer.getVariable(name);
		}
	}

	function update()
	{
		if (this.mplayer != null)
		{
			this.mplayer.progress(0);
		}
	}

	function redraw( init = true )
	{
		this._motionRedraw = init ? 1 : 2;
	}

	function getButton( name )
	{
		return ::getval(this._motionButtonMap, name);
	}

	function pressButton( name )
	{
		local button = this.getButton(name);

		if (button != null && button.getPressEnable())
		{
			return button.onPress(0, 0, true);
		}
	}

	function upButton( name )
	{
		local button = this.getButton(name);

		if (button != null && "onUpKey" in button)
		{
			return button.onUpKey();
		}
	}

	function downButton( name )
	{
		local button = this.getButton(name);

		if (button != null && "onDownKey" in button)
		{
			return button.onDownKey();
		}
	}

	function foreachButton( func )
	{
		foreach( i, value in this._motionButtons )
		{
			func(i, value);
		}
	}

	function getText( name )
	{
		if (name in this._motionCommonMap)
		{
			return this._motionCommonMap[name];
		}
		else if (name in this._motionExternalMap)
		{
			return this._motionExternalMap[name];
		}

		local button = this.getButton(name);

		if (button != null)
		{
			return button.textInfo;
		}
	}

	function clearText( name )
	{
		local text = this.getText(name);

		if (text != null)
		{
			text.clearText();
		}
	}

	function getImage( name )
	{
		local ret;

		if (name in this._motionCommonMap)
		{
			ret = this._motionCommonMap[name];
		}
		else if (name in this._motionExternalMap)
		{
			ret = this._motionExternalMap[name];
		}

		if (ret != null && ret.isImage())
		{
			return ret;
		}

		local button = this.getButton(name);

		if (button != null)
		{
			return button.imageInfo;
		}

		return null;
	}

	function initButton( name )
	{
		if (name in this._motionCommonMap)
		{
			this._motionCommonMap[name].onInit();
		}
		else if (name in this._motionRadioGroup)
		{
			this._motionRadioGroup[name].onInit();
		}
		else if (name in this._motionButtonMap)
		{
			this._motionButtonMap[name].onInit();
		}
		else if (name in this._motionExternalMap)
		{
			this._motionExternalMap[name].onInit();
		}
		else if (name in this._motionInfoMap)
		{
			this._motionInfoMap[name].onInit();
		}
	}

	function initInfo()
	{
		if (this.minfo.hasParam("initvar"))
		{
			this.setVariables(this.minfo.initvar, "initvar");
		}

		foreach( id, value in this._motionInfos )
		{
			value.onInit();
		}

		foreach( key, value in this._motionExternalMap )
		{
			if (value.info instanceof this.MotionTextInfo)
			{
				value.onInit();
			}
		}
	}

	function setDisable( name, disable )
	{
		if (name in this._motionButtonMap)
		{
			this._motionButtonMap[name].setDisable(disable);
		}
		else if (name in this._motionExternalMap)
		{
			this._motionExternalMap[name].setDisable(disable);
		}
	}

	function initMotionFocus( focus )
	{
		local cur = this.calcMotion(focus);
		local i;
		local cnt = this._motionParts.len();

		if (cur == null)
		{
			cur = 0;
		}

		for( i = 0; i < cnt; i++ )
		{
			local button = this._motionParts[cur];

			if (!button.getDisable() && !button.nofocus)
			{
				break;
			}

			if (cur < cnt - 1)
			{
				cur++;
			}
			else
			{
				cur = 0;
			}
		}

		this.setMotionFocus(i < cnt ? cur : null, true);
	}

	function prevMotionFocus()
	{
		local i;
		local cnt = this._motionParts.len();
		local cur = this._motionFocus;

		for( i = 0; i < cnt; i++ )
		{
			if (cur != null && cur > 0)
			{
				cur--;
			}
			else
			{
				cur = cnt - 1;
			}

			local button = this._motionParts[cur];

			if (!button.getDisable() && !button.nofocus)
			{
				break;
			}
		}

		if (i < cnt)
		{
			this.moveCursorMotionFocus(cur);
		}
	}

	function nextMotionFocus()
	{
		local i;
		local cnt = this._motionParts.len();
		local cur = this._motionFocus;

		for( i = 0; i < cnt; i++ )
		{
			if (cur != null && cur < cnt - 1)
			{
				cur++;
			}
			else
			{
				cur = 0;
			}

			local button = this._motionParts[cur];

			if (!button.getDisable() && !button.nofocus)
			{
				break;
			}
		}

		if (i < cnt)
		{
			this.moveCursorMotionFocus(cur);
		}
	}

	function checkMotionFocus()
	{
		local target = this.getMotionFocus();

		if (target != null && target.getDisable())
		{
			if (this.COLUMNS != null && this.ROWS != null && target.rowcol != null)
			{
				local row = target.rowcol[0];
				local col = target.rowcol[1];
				local button;
				button = this.findNextRow(row, col, -1, this.COLUMNS);

				if (button != null)
				{
					this.moveCursorMotionFocus(button.name);
					return;
				}
			}

			this.prevMotionFocus();
		}
	}

	function _execFunc( func, args = null )
	{
		if (typeof func == "function")
		{
			if (func.getenv() == null)
			{
				func = func.bindenv(this.minfo);
			}

			if (args == null)
			{
				return func();
			}
			else
			{
				switch(args.len())
				{
				case 0:
					return func();

				case 1:
					return func(args[0]);

				case 2:
					return func(args[0], args[1]);

				case 3:
					return func(args[0], args[1], args[2]);

				case 4:
					return func(args[0], args[1], args[2], args[3]);
				}

				return func(args[0], args[1], args[2], args[3], args[4]);
			}
		}
		else if (typeof func == "array")
		{
			foreach( f in func )
			{
				this._execFunc(f, args);
			}
		}
		else
		{
			return func;
		}
	}

	function execFunc( func, ... )
	{
		switch(typeof func)
		{
		case "function":
		case "array":
			local args = [];

			for( local i = 0; i < vargc; i++ )
			{
				args.append(vargv[i]);
			}

			return this._execFunc(func, args);
		}
	}

	function _exec( exp, args )
	{
		if (typeof exp == "array")
		{
			foreach( i, e in exp )
			{
				this._exec(e, args);
			}
		}
		else
		{
			if (typeof exp == "string")
			{
				try
				{
					exp = this.eval(exp);
				}
				catch( e )
				{
					if (e instanceof this.GameStateException)
					{
						throw e;
					}

					this.printf("_exec:%s:\x00e5\x00bc\x008f\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", exp, "message" in e ? e.message : e);
					::printException(e);
				}
			}

			return this._execFunc(exp, args);
		}
	}

	function exec( exp, ... )
	{
		if (exp != null)
		{
			local args = [];

			for( local i = 0; i < vargc; i++ )
			{
				args.append(vargv[i]);
			}

			return this._exec(exp, args);
		}
	}

	function onEnterArea( button, id )
	{
		this.execMotionFunc("onEnter", button, id);
	}

	function onLeaveArea( button, id )
	{
		this.execMotionFunc("onLeave", button, id);
	}

	function onMotionDrag( button, x, y, state = 0 )
	{
		this.onExecute();

		try
		{
			this.exec(button.drag, button, x, y, state);
		}
		catch( e )
		{
			this.printf("%s:\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0083\x00a9\x00e3\x0083\x0083\x00e3\x0082\x00b0\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:drag:%s\n", button.name, button.drag);
			::printException(e);
		}

		local oldFocus = this._motionDropFocus;
		this._motionDropFocus = null;

		if (state == 0 || state == 1)
		{
			foreach( i, target in this._motionParts )
			{
				if (!target.getDisable() && target.checkContains(x, y) && target.drop != null)
				{
					this._motionDropFocus = i;
					break;
				}
			}
		}

		if (oldFocus != this._motionDropFocus)
		{
			this.updateMotionFocus(true);
		}
	}

	function onMotionDrop( button, x, y )
	{
		local ret;

		foreach( i, target in this._motionParts )
		{
			if (!target.getDisable() && target.checkContains(x, y) && target.drop != null)
			{
				this.onExecute();
				local ret;

				try
				{
					ret = this.exec(target.drop, target, button, x, y);
				}
				catch( e )
				{
					this.printf("%s:\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0083\x00ad\x00e3\x0083\x0083\x00e3\x0083\x0097\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:drop:%s\n", target.name, target.drop);
					::printException(e);
				}

				return ret;
			}
		}

		return this.execMotionFunc("onDrop", button, x, y);
	}

	function onMotionButton( button )
	{
		if (button.change != null || button.exp != null)
		{
			this.onExecute();
		}

		try
		{
			this.exec(button.change, button, 0, false);
		}
		catch( e )
		{
			this.printf("%s:\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e5\x00a4\x0089\x00e6\x009b\x00b4\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:change:%s\n", button.name, button.change);
			::printException(e);
		}

		local ret;

		try
		{
			ret = this.exec(button.exp, button, this);
		}
		catch( e )
		{
			if (e instanceof this.GameStateException)
			{
				throw e;
			}

			this.printf("%s:\x00e3\x0083\x009c\x00e3\x0082\x00bf\x00e3\x0083\x00b3\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e6\x0099\x0082\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", button.name, button.exp);
			::printException(e);
		}

		if (ret == null || ret)
		{
			if (button.wait != null)
			{
				for( local i = button.wait; i > 0; i-- )
				{
					this.workSync();
				}
			}

			local motion;

			if (typeof button.motion == "function")
			{
				try
				{
					motion = this.execFunc(button.motion, button);
				}
				catch( e )
				{
					if (e instanceof this.GameStateException)
					{
						throw e;
					}

					this.printf("_exec:%s:\x00e5\x00bc\x008f\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", this.exp, "message" in e ? e.message : e);
					this.printf("%s:motion func failed:%s\n", button.name, "message" in e ? e.message : e);
				}
			}
			else
			{
				motion = button.motion;
			}

			if (motion != null)
			{
				if ("hide" in motion)
				{
					this.playWait(motion.hide, 8);
				}

				this.setMotion(motion);
			}

			if (button.result != null)
			{
				this.onProcess(button.result);
			}
		}
	}

	function onMotionRadioButton( button )
	{
		if (button.group in this._motionRadioGroup)
		{
			this._motionRadioGroup[button.group].onButton(button);
		}
	}

	function setExternalVisible( v )
	{
		foreach( key, value in this._motionButtonMap )
		{
			value.setExternalVisible(v);
		}

		foreach( key, value in this._motionExternalMap )
		{
			value.setExternalVisible(v);
		}

		foreach( key, value in this._motionCommonMap )
		{
			value.setExternalVisible(v);
		}
	}

	function findRowColButton( row, col )
	{
		foreach( i, button in this._motionParts )
		{
			if (button.rowcol != null && button.rowcol[0] == row && button.rowcol[1] == col && !button.getDisable() && !button.nofocus)
			{
				return button;
			}
		}

		return null;
	}

	function findNextRow( row, col, diff, rows, count = null )
	{
		if (count == null)
		{
			count = rows;
		}

		for( local i = 0; i < count; i++ )
		{
			row = (row + diff + rows) % rows;
			local button = this.findRowColButton(row, col);

			if (button != null)
			{
				return button;
			}
		}
	}

	function findNextCol( row, col, diff, columns, count = null )
	{
		if (count == null)
		{
			count = columns;
		}

		for( local i = 0; i < count; i++ )
		{
			col = (col + diff + columns) % columns;
			local button = this.findRowColButton(row, col);

			if (button != null)
			{
				return button;
			}
		}
	}

	function findNextRowNextCol( row, col, diff, rows, columns )
	{
		for( local i = 0; i < rows; i++ )
		{
			row = row + diff;

			if (row < 0)
			{
				col = (col - 1 + columns) % columns;
			}
			else if (row >= rows)
			{
				col = (col + 1 + columns) % columns;
			}

			row = (row + rows) % rows;
			local button = this.findRowColButton(row, col);

			if (button != null)
			{
				return button;
			}
		}
	}

	function findNextColNextRow( row, col, diff, rows, columns )
	{
		for( local i = 0; i < columns * rows; i++ )
		{
			col = col + diff;

			if (col < 0)
			{
				row = (row - 1 + rows) % rows;
			}
			else if (col >= columns)
			{
				row = (row + 1 + rows) % rows;
			}

			col = (col + columns) % columns;
			local button = this.findRowColButton(row, col);

			if (button != null)
			{
				return button;
			}
		}
	}

	function moveCursor( target, input )
	{
		if (this.COLUMNS != null && this.ROWS != null && target.rowcol != null)
		{
			local row = target.rowcol[0];
			local col = target.rowcol[1];
			local button;

			if (input.keyPressed(32))
			{
				if (this.noLoop)
				{
					button = col > 0 ? this.findNextCol(row, col, -1, this.COLUMNS, col) : null;
				}
				else
				{
					button = this.nextRow ? this.findNextColNextRow(row, col, -1, this.ROWS, this.COLUMNS) : this.findNextCol(row, col, -1, this.COLUMNS);
				}
			}
			else if (input.keyPressed(16))
			{
				if (this.noLoop)
				{
					button = col < this.COLUMNS - 1 ? this.findNextCol(row, col, 1, this.COLUMNS, this.COLUMNS - 1 - col) : null;
				}
				else
				{
					button = this.nextRow ? this.findNextColNextRow(row, col, 1, this.ROWS, this.COLUMNS) : this.findNextCol(row, col, 1, this.COLUMNS);
				}
			}
			else if (input.keyPressed(64))
			{
				if (this.noLoop)
				{
					button = row > 0 ? this.findNextRow(row, col, -1, this.ROWS, row) : null;
				}
				else
				{
					button = this.nextCol ? this.findNextRowNextCol(row, col, -1, this.ROWS, this.COLUMNS) : this.findNextRow(row, col, -1, this.ROWS);
				}
			}
			else if (input.keyPressed(128))
			{
				if (this.noLoop)
				{
					button = row < this.ROWS - 1 ? this.findNextRow(row, col, 1, this.ROWS, this.ROWS - 1 - row) : null;
				}
				else
				{
					button = this.nextCol ? this.findNextRowNextCol(row, col, 1, this.ROWS, this.COLUMNS) : this.findNextRow(row, col, 1, this.ROWS);
				}
			}

			if (button != null)
			{
				this.moveCursorMotionFocus(button.name);
			}

			return true;
		}

		local prev = target.bindprev != null ? target.bindprev : this.PREVKEY;

		if (input.keyPressed(prev))
		{
			this.prevMotionFocus();
			return true;
		}

		local next = target.bindnext != null ? target.bindnext : this.NEXTKEY;

		if (input.keyPressed(next))
		{
			this.nextMotionFocus();
			return true;
		}

		return false;
	}

	function isMotionLoaded()
	{
		return this._motionStorage != null;
	}

	function findStorage( storage )
	{
		if (this._motionStorage != null)
		{
			foreach( data in this._motionStorage )
			{
				if (data.storage == storage)
				{
					return data;
				}
			}
		}
	}

	function checkStorage( storage )
	{
		if (typeof storage == "array" && typeof this._motionStorage == "array")
		{
			if (storage.len() != this._motionStorage.len())
			{
				return false;
			}

			foreach( i, name in storage )
			{
				if (name != this._motionStorage[i].storage)
				{
					return false;
				}
			}

			return true;
		}

		return typeof storage == "string" && typeof this._motionStorage == "table" && this._motionStorage.storage == storage;
	}

	function getMotionData()
	{
		local data;

		if (this._motionStorage != null)
		{
			data = typeof this._motionStorage == "array" ? this._motionStorage[0].data : this._motionStorage.data;
		}
		else
		{
			data = this._owner.getMotionData();
		}

		if (data != null && "motioninfo" in data.root)
		{
			local mscale = "scaleinfo" in data.root ? data.root.scaleinfo.scale : null;
			return {
				info = data.root.motioninfo,
				scale = mscale
			};
		}
	}

	function openMotion( storage, context = null, elm = null )
	{
		if (this._motionStorage == null || this.minfo == null || !this.checkStorage(storage))
		{
			this.doneMotion();

			if (storage != null)
			{
				this._motionStorage = this._owner.openMotionStorage(storage, false);
			}

			if (context == null)
			{
				context = this;
			}
			else if (context instanceof this.Object)
			{
				context.setDelegate(this);
			}

			this.minfo = ::MotionInfo(context, elm);
			this.minfo.storage = storage;
			this.minfo.inputNo = 0;
			this.minfo.input = null;
			local buttonlist = [];
			this.addMotionInfo(buttonlist, this._owner._defaultMotionInfo);
			local data = this.getMotionData();

			if (data != null)
			{
				this.addMotionInfo(buttonlist, data.info, data.scale);
			}

			if (this.minfo.hasParam("fontList") && typeof this.minfo.fontList == "array")
			{
				this.mfont = ::FontInfo();

				foreach( value in this.minfo.fontList )
				{
					this.mfont.entryFont(value);
				}
			}

			local defaultInfo;

			foreach( info in buttonlist )
			{
				if (typeof info == "table")
				{
					if (!("name" in info))
					{
						if (defaultInfo == null)
						{
							defaultInfo = {};
						}

						this.margeButtonInfo(defaultInfo, info);
					}
					else if (info.name != null)
					{
						local binfo = {};

						if (defaultInfo != null)
						{
							this.margeButtonInfo(binfo, defaultInfo);
						}

						this.margeButtonInfo(binfo, info);
						this.minfo.buttonlist.append(binfo);
					}
				}
			}

			if (this.mainPanel && this._owner)
			{
				this._owner.onMotionLoad();
			}

			this.execMotionFunc("onLoad");

			foreach( info in this.minfo.buttonlist )
			{
				local type = ::getval(info, "type");

				if (type == "systext" || type == "sysimage")
				{
					if (!("cond" in info) || this.evalCond(info.name, info.cond))
					{
						this.addMotionCommon(info);
					}
				}
			}
		}
	}

	function getMotionFlags( elm, motion )
	{
		local flags = ::getval(elm, "flags", motion.len() >= 4 && motion.substr(0, 4) == "hide" ? 8 : 1);

		if (typeof flags == "string")
		{
			local flagnames = {
				FORCE = 1,
				CHAIN = 2,
				AS_CAN = 4,
				JOIN = 8,
				STEALTH = 16
			};
			local ret = 0;
			local flags = flags.split("|");

			foreach( f in flags )
			{
				if (f in flagnames)
				{
					ret = ret | flagnames[f];
				}
				else
				{
					local n = ::eval(f, null, "");

					if (typeof n == "integer")
					{
						ret = ret | n;
					}
					else
					{
						this.printf("\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0081\x00aa\x00e3\x0083\x0095\x00e3\x0083\x00a9\x00e3\x0082\x00b0\x00e6\x008c\x0087\x00e5\x00ae\x009a:%s\n", f);
					}
				}
			}

			return ret;
		}
		else
		{
			return ::toint(flags);
		}
	}

	function registerIcon( image, source, label, ox = null, oy = null )
	{
		local id;

		if (ox != null)
		{
			id = this._owner.registerMotionSourceIconImage(image, source, label, ox, oy);
		}
		else
		{
			id = this._owner.registerMotionSourceIconImage(image, source, label);
		}

		if (this._motionIcons == null)
		{
			this._motionIcons = [];
		}

		this._motionIcons.append(id);
		return id;
	}

	function unregisterIcon( id )
	{
		local pos = this._motionIcons.find(id);

		if (pos >= 0)
		{
			this._owner.unregisterMotionSourceIconImage(id);
			this._motionIcons.remove(pos);
		}
	}

	function setMotion( elm, force = false )
	{
		if (typeof elm == "string")
		{
			elm = {
				motion = elm
			};
		}

		if ("back" in elm)
		{
			try
			{
				this.loadImage(elm.back);
			}
			catch( e )
			{
				this.printf("\x00e8\x0083\x008c\x00e6\x0099\x00af\x00e8\x00aa\x00ad\x00e3\x0081\x00bf\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e5\x00a4\x00b1\x00e6\x0095\x0097\n");
				::printException(e);
			}
		}

		if (this.mplayer == null)
		{
			this.mplayer = ::Motion(this._owner, this.getbool(elm, "fore", false) ? 1 : 0);
			this.mplayer.visible = true;
			this.mplayer.setDelegate(this);
			this.mplayer.eventEnabled = this.eventEnabled;
		}

		force = this.getval(elm, "force", force);
		local updateChara = false;
		local updateFlag = false;

		if ("chara" in elm)
		{
			if (force || this.mplayer.chara != elm.chara)
			{
				this.mplayer.setChara(elm.chara);
				this.minfo.setChara(elm.chara, this);
				updateChara = true;
				updateFlag = true;
			}
		}

		if (!this._motionOpened)
		{
			if (this.mainPanel && this._owner)
			{
				this._owner.onMotionOpen(elm);
			}

			this.execMotionFunc("onOpen", elm);
			this._motionOpened = true;
		}

		if (updateChara || this.getval(elm, "reinit"))
		{
			this.checkStopMotion();
			this.TOGGLEKEY = this.minfo.hasParam("toggleKey") ? this.getButtonBind(this.minfo.toggleKey) : this.KEY_OK;
			this.PREVKEY = this.minfo.hasParam("prevKey") ? this.getButtonBind(this.minfo.prevKey) : 64 | 32;
			this.NEXTKEY = this.minfo.hasParam("nextKey") ? this.getButtonBind(this.minfo.nextKey) : 128 | 16;
			this.COLUMNS = this.minfo.hasParam("columns") ? this.minfo.columns : null;
			this.ROWS = this.minfo.hasParam("rows") ? this.minfo.rows : null;
			this.nextRow = this.minfo.hasParam("nextRow") ? this.minfo.nextRow : false;
			this.nextCol = this.minfo.hasParam("nextCol") ? this.minfo.nextCol : false;
			this.noLoop = this.minfo.hasParam("noLoop") ? this.minfo.noLoop : false;
			this.clearMotionButtons();

			foreach( info in this.minfo.buttonlist )
			{
				local type = ::getval(info, "type");

				if (typeof type == "string" && type.len() > 1 && type.charAt(0) == "@")
				{
					try
					{
						type = this.eval(type.substr(1));
					}
					catch( e )
					{
						this.printf("\x00e3\x0083\x00a2\x00e3\x0083\x00bc\x00e3\x0082\x00b7\x00e3\x0083\x00a7\x00e3\x0083\x00b3TYPE\x00e6\x008c\x0087\x00e5\x00ae\x009a:%s:\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e3\x0082\x00a8\x00e3\x0083\x00a9\x00e3\x0083\x00bc:%s\n", type, "message" in e ? e.message : e);
					}
				}

				if (!(type == "systext" || type == "sysimage"))
				{
					if (!("cond" in info) || this.evalCond(info.name, info.cond))
					{
						this.addMotionButton(info);
					}
				}
			}

			this.touchEnable = this.minfo.hasParam("touchEnable") ? this.minfo.touchEnable : false;
			this.analogEnable = this.minfo.hasParam("analogEnable") ? this.minfo.analogEnable : false;

			if (this.analogEnable)
			{
				this.inputHub.transferAnalogToDigital = false;
			}

			this.analogRightEnable = this.minfo.hasParam("analogRightEnable") ? this.minfo.analogRightEnable : false;

			if (this.analogRightEnable)
			{
				this.inputHub.transferRightAnalogToDigital = false;
			}

			this.choiceMode = ::getval(elm, "choice");
			this.initGesture();
			this.mmain = this.getMotionFunc("onMain");
			this.mtouch = this.getMotionFunc("onTouch");
			this.manalog = this.getMotionFunc("onAnalog");
			this.manalogr = this.getMotionFunc("onAnalogRight");
			this.mcontains = this.getMotionFunc("onContains");
			this.execMotionFunc("onChara", this.mplayer.chara);
		}

		if ("motion" in elm)
		{
			this._motionExternalVisible = ::getval(elm, "externalVisible");

			if (force || updateChara || this.mplayer.motion != elm.motion)
			{
				this.checkStopMotion();
				this.mplayer.play(elm.motion, this.getMotionFlags(elm, elm.motion));
				this.minfo.motion = elm.motion;
				this._motionStartTime = this.getCurrentTick();
				this.checkStartMotion();
				this._motionRedraw = 1;
				updateFlag = true;
			}
		}

		if ("tickcount" in elm)
		{
			local tickcount = this.toint(elm.tickcount);

			if (this.mplayer.tickCount != tickcount)
			{
				this.mplayer.tickCount = tickcount;
				updateFlag = true;
			}
		}

		if ("speed" in elm)
		{
			local speed = this.tonumber(elm.speed);

			if (this.mplayer.speed != speed)
			{
				this.mplayer.speed = speed;
				updateFlag = true;
			}
		}

		if (("focus" in elm) && elm.focus != null)
		{
			this.initMotionFocus(elm.focus);
			updateFlag = true;
		}

		this.checkMotionFocus();

		if ("variables" in elm)
		{
			local flag = ::getval(elm, "flag", 0);

			foreach( name, value in elm.variables )
			{
				this.setVariable(name, value, flag);
			}

			updateFlag = true;
		}

		if (updateFlag)
		{
			this.update();
		}

		this._motionExec = "exec" in elm ? elm.exec : null;
	}

	function getMotionTime()
	{
		return this.getCurrentTick() - this._motionStartTime;
	}

	function checkTimeout()
	{
		if (this._motionTimeouts.len() > 0 && this._motionStartTime != null)
		{
			local timeout = this.getCurrentTick() - this._motionStartTime;

			foreach( button in this._motionTimeouts )
			{
				if (("timeout" in button) && button.timeout != null && timeout > button.timeout || ("waitfunc" in button) && button.waitfunc != null && this.execFunc(button.waitfunc, button))
				{
					button.onPress(0, 0, true);
					return true;
				}
			}
		}

		return false;
	}

	checktouch = false;
	touchEnable = false;
	analogEnable = false;
	analogRightEnable = false;
	gesture = null;
	function onAnalog( x, y )
	{
		if (this.manalog && this._execFunc(this.manalog, [
			x,
			y
		]))
		{
			this.onExecute();
			return true;
		}
	}

	function onAnalogRight( x, y )
	{
		if (this.manalogr && this._execFunc(this.manalogr, [
			x,
			y
		]))
		{
			this.onExecute();
			return true;
		}
	}

	function applyMouseMotionFocus( init = false )
	{
		if (this._motionMouseFocus != null && this._motionMouseFocus != this._motionFocus)
		{
			local button = this._motionParts[this._motionMouseFocus];

			if (button != null && !button.nofocus)
			{
				this.setMotionFocus(this._motionMouseFocus, init);
			}
		}
	}

	function onTouchEnd( x, y, work = false )
	{
		if (this.onMouseUp(x, y, 1))
		{
			work = true;
		}

		this.applyMouseMotionFocus(work);
		this._motionMouseFocus = null;
		this.updateMotionFocus(true);
		return work;
	}

	function checkTouchContains( x, y )
	{
		local ret;

		foreach( i, button in this._motionParts )
		{
			if (button.getPressEnable() && button.checkContains(x, y))
			{
				return true;
			}
		}
	}

	function onTouch( x, y, force = true )
	{
		if (this.checkTouchContains(x, y))
		{
			this.onMouseMove(x, y, 1, true);
			local ret = false;

			if (this.onMouseDown(x, y, 1))
			{
				ret = true;
			}

			if ((force || !this._motionGrab) && this.onTouchEnd(x, y, ret))
			{
				ret = true;
			}

			return ret;
		}

		if (this.mtouch && !this.getMotionLock())
		{
			if (this._execFunc(this.mtouch, [
				x,
				y
			]))
			{
				this.onExecute();
				return true;
			}
		}
	}

	function initGesture()
	{
		if (this._motionGestureBinds.len() > 0)
		{
			this.gesture = this.GestureInfo(this);
		}
		else
		{
			this.gesture = null;
		}
	}

	function doneGesture()
	{
		this.gesture = null;
	}

	function onGesture( name, param )
	{
		if (name == "touch" && this.onTouch(param.x, param.y))
		{
			return true;
		}

		foreach( button in this._motionGestureBinds )
		{
			if (button.getPressEnable() && name == button.gesture)
			{
				button.onPress(0, 0, true);
				return true;
			}
		}
	}

	function findNextDir( v, key )
	{
		while (v != null && v != "" && v in this._motionPartsMap)
		{
			local target = this._motionPartsMap[v];

			if (!target.getDisable())
			{
				return v;
			}

			v = target.dir_parts != null && key in target.dir_parts ? target.dir_parts[key] : "";
		}

		return "";
	}

	function checkInput( no, input )
	{
		if (this.checkDebug(input) || this._owner.checkCommand(input) || this.checkTimeout())
		{
			return null;
		}

		this.minfo.inputNo = no;
		this.minfo.input = input;

		if (this.checktouch && this.touchEnable)
		{
			if (this.gesture != null)
			{
				if (input.driveTouchEvent(this.gesture))
				{
					return true;
				}
			}
			else
			{
				if (input.getTouched())
				{
					local pos = input.getMovePos();

					if (this.onTouch(pos.x, pos.y, false))
					{
						return true;
					}
				}

				if (this._motionGrab)
				{
					local pos = input.getMovePos();

					if (!input.getTouching())
					{
						if (this.onTouchEnd(pos.x, pos.y))
						{
							return true;
						}
					}
					else
					{
						this.onMouseMove(pos.x, pos.y, 1, true);
					}
				}
			}
		}
		else if ("getMouseMove" in input)
		{
			local ret;
			local move = input.getMouseMove();
			local pos = input.getMousePos();

			if (move.x != 0 || move.y != 0)
			{
				this.onMouseMove(pos.x, pos.y);
				this.applyMouseMotionFocus();
			}

			if (input.getMouseButtonPressed() & 1)
			{
				if (this.onMouseDown(pos.x, pos.y))
				{
					ret = true;
				}
			}

			if (input.getMouseButtonReleased() & 1)
			{
				if (this.onMouseUp(pos.x, pos.y))
				{
					ret = true;
				}
			}

			if (ret)
			{
				return true;
			}
		}

		if (this.analogEnable && "getAnalogStickX" in input)
		{
			local x = input.getAnalogStickX();
			local y = input.getAnalogStickY();

			if (x != 0 || y != 0)
			{
				if (this.onAnalog(x, y))
				{
					return true;
				}
			}
		}

		if (this.analogRightEnable && "getRightAnalogStickX" in input)
		{
			local x = input.getRightAnalogStickX();
			local y = input.getRightAnalogStickY();

			if (x != 0 || y != 0)
			{
				if (this.onAnalogRight(x, y))
				{
					return true;
				}
			}
		}

		if (!this._motionGrab)
		{
			foreach( button in this._motionBinds )
			{
				if (button.getPressEnable() && input.keyPressed(button.bind))
				{
					button.onPress(0, 0, true);
					return true;
				}
			}

			foreach( button in this._motionFuncBinds )
			{
				if (button.getPressEnable() && ::funcKeyPressed(button.funcbind))
				{
					button.onPress(0, 0, true);
					return true;
				}
			}

			if (this._motionFocus == null)
			{
				if (this._motionParts.len() > 0)
				{
					if (input.keyPressed(this.PREVKEY))
					{
						this.prevMotionFocus();
						return true;
					}
					else if (input.keyPressed(this.NEXTKEY))
					{
						this.nextMotionFocus();
						return true;
					}
				}
			}
			else
			{
				local target = this._motionParts[this._motionFocus];

				if (target != null && !target.getDisable())
				{
					if (target.dir_parts != null)
					{
						foreach( key, v in target.dir_parts )
						{
							if (key in this._buttonnames)
							{
								if (input.keyPressed(this._buttonnames[key]))
								{
									v = this.findNextDir(v, key);

									if (v != "")
									{
										this.moveCursorMotionFocus(v);
									}

									return true;
								}
							}
						}
					}

					if ("onKeyDown" in target)
					{
						return target.onKeyDown(input);
					}
				}
			}
		}

		return false;
	}

	function workSync()
	{
		this.sync();

		if (this.mainPanel && this._owner)
		{
			this._owner.onMotionUpdate();
		}

		this._execFunc(this.mmain);
	}

	function _work()
	{
		if (this.mainPanel && this._owner)
		{
			this._owner.onMotionUpdate();
		}

		this._execFunc(this.mmain);
		local ret;

		if (!this.getMotionLock())
		{
			if (this._motionExec != null)
			{
				if (typeof this._motionExec == "function")
				{
					try
					{
						this._execFunc(this._motionExec);
					}
					catch( e )
					{
						if (e instanceof this.GameStateException)
						{
							throw e;
						}

						this.printf("motionExec failed\n");
						::printException(e);
					}
				}
				else if (this._motionExec in this._motionPartsMap)
				{
					local button = this._motionPartsMap[this._motionExec];

					if (button.getPressEnable())
					{
						button.onPress(0, 0, true);
					}
				}

				this._motionExec = null;
				ret = true;
			}
			else
			{
				ret = this.checkInputFunc(this.checkInput.bindenv(this), this.choiceMode);
			}
		}

		this.checkInit();

		if (!(this.mplayer != null && this.mplayer.playing))
		{
			this.checkStopMotion();
		}

		return ret;
	}

	function work()
	{
		this.sync();
		this._work();
	}

	function lockMotion()
	{
		this._motionLock = true;
		this._internalOnMouseLeave();
	}

	function unlockMotion()
	{
		this._motionLock = false;

		if (false && !this.getMotionLock())
		{
			this._internalOnMouseMove(this.cursorX, this.cursorY, 0);
		}
	}

	function startMotionWork()
	{
		this._motionWork = true;
	}

	function endMotionWork()
	{
		this._motionWork = false;
	}

	function stopMotion()
	{
		if (this.mplayer != null && this._motionPlaying)
		{
			this.mplayer.tickCount = this.mplayer.lastTime;
			this.mplayer.progress(0);
			this.mplayer.stop();
			this.checkStopMotion();
		}
	}

	function doneMotion()
	{
		if (this.mplayer != null)
		{
			this.stopMotion();
			this.checkStopMotion();
			this.clearMotionButtons();
			this.mplayer = null;
		}

		this._motionCommonMap.clear();
		this.clearImage();
		this.minfo = null;
		this.mmain = null;
		this.mtouch = null;
		this.manalog = null;
		this.mcontains = null;
		this.mfont = null;

		if (this._motionIcons != null)
		{
			foreach( id in this._motionIcons )
			{
				this._owner.unregisterMotionSourceIconImage(id);
			}

			this._motionIcons = null;
		}

		this._motionStorage = null;
		this._motionOpened = false;
		this._motionExec = null;
	}

	function closeMotion( elm = null )
	{
		if (this.isMotion())
		{
			do
			{
				this.sync();
			}
			while (this.isPlayingMotion());
		}

		this.execMotionFunc("onClose", elm);
	}

	result = null;
	function onProcess( result )
	{
		this.result = result;

		if (this.isMotion())
		{
			this.playMotion("hide", 8);
		}

		this.lockMotion();
		this.endMotionWork();
	}

	function _show( elm, storage = null, context = null )
	{
		local loading;

		if ("loading" in elm)
		{
			loading = ::MotionLayer(this._owner, "motion/loading.psb", "LOADING");
		}

		if (loading)
		{
			loading.setPriority(100);
			loading.play("show");
		}

		if (!("chara" in elm))
		{
			elm.chara <- "main";
		}

		if (!("motion" in elm))
		{
			elm.motion <- "show";
		}

		this.result = null;

		if (storage == null)
		{
			if (!this.isMotionLoaded())
			{
				throw this.Exception("\x00e3\x0083\x00a2\x00e3\x0083\x00bc\x00e3\x0082\x00b7\x00e3\x0083\x00a7\x00e3\x0083\x00b3\x00e3\x0081\x008c\x00e3\x0083\x00ad\x00e3\x0083\x00bc\x00e3\x0083\x0089\x00e3\x0081\x0095\x00e3\x0082\x008c\x00e3\x0081\x00a6\x00e3\x0081\x0084\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093");
			}
		}
		else
		{
			this.openMotion(storage, context, elm);
		}

		if (loading)
		{
			loading.playWait("hide", 8);
			loading = null;
		}

		this.setMotion(elm, true);
		this.checkInit();
	}

	function open( elm, storage = null, context = null )
	{
		local anal = this.inputHub.transferAnalogToDigital;
		local analr = this.inputHub.transferRightAnalogToDigital;

		try
		{
			this._show(elm, storage, context);
			this.startMotionWork();

			do
			{
				this.work();
			}
			while (this._motionWork || this.getMotionPlaying());

			this.closeMotion(elm);
			this.doneMotion();
			this.inputHub.transferAnalogToDigital = anal;
			this.inputHub.transferRightAnalogToDigital = analr;
		}
		catch( e )
		{
			this.doneMotion();
			this.inputHub.transferAnalogToDigital = anal;
			this.inputHub.transferRightAnalogToDigital = analr;
			throw e;
		}

		return this.result;
	}

	function show( elm, storage = null, context = null )
	{
		try
		{
			this._show(elm, storage, context);

			do
			{
				this.work();
			}
			while (this.getMotionPlaying());
		}
		catch( e )
		{
			::printException(e);
			this.doneMotion();
			throw e;
		}
	}

	function hide( cur = null )
	{
		if (this.minfo != null)
		{
			this.setMotion({
				motion = "hide",
				focus = cur
			});
			this.checkInit();

			do
			{
				this.work();
			}
			while (this.getMotionPlaying());

			this.closeMotion();
		}
	}

	function play( motion, flags = null )
	{
		local m = {
			motion = motion
		};

		if (flags != null)
		{
			m.flags <- flags;
		}

		this.setMotion(m);
		this.checkInit();
		this.lockMotion();
	}

	function playWait( motion, flags = null )
	{
		this.play(motion, flags);

		do
		{
			this.work();
		}
		while (this.getMotionPlaying());

		this.unlockMotion();
	}

	_thread = null;
	function _doneThread()
	{
		if (this._thread != null)
		{
			this._thread.exit();
			this._thread = null;
		}
	}

	function start( elm, storage = null, context = null )
	{
		this._doneThread();
		this._thread = ::fork(function () : ( elm, storage, context )
		{
			this.open(elm, storage, context);
			this._thread = null;
		}.bindenv(this));
	}

	function stop()
	{
		if (this._thread != null && this._thread.status == 4)
		{
			this.setMotion("hide");
			this.onProcess("");
		}
	}

}

class this.MotionPanelLayer extends ::BasicLayer
{
	DEFAULT_AFX = "center";
	DEFAULT_AFY = "center";
	TEXT_SIZE = 16;
	TEXT_SHADOW = false;
	TEXT_COLOR = 4294967295;
	TEXT_SHADOWCOLOR = 4278190080;
	TEXT_SHADOWDIFF = 1;
	TEXT_DEFAULT = null;
	TEXT_COLUMNS = 10;
	TEXT_LINES = 1;
	TEXT_IGNORE = {
		over = true
	};
	TEXT_OPTION = {};
	TEXT_BASESCALE = false;
	scale = null;
	_defaultMotionInfo = null;
	_storagelist = null;
	_panellist = null;
	panel = null;
	constructor( screen = null, defaultMotionInfo = null, scale = null )
	{
		::BasicLayer.constructor(screen);

		if (scale == null)
		{
			local bounds = ::getScreenBounds(screen);
			scale = ::min(bounds.width / ::SCWIDTH, bounds.height / ::SCHEIGHT);
		}

		this.setScale(scale, scale);
		this.scale = scale;
		this.smoothing = true;
		this._defaultMotionInfo = defaultMotionInfo;
		this._panellist = [];
		this._storagelist = [];
	}

	function destructor()
	{
		this.panel = null;
		this._panellist.clear();
		this._storagelist.clear();
		::BasicLayer.destructor();
	}

	function findFont( size, face = null, style = 0 )
	{
		if (this.panel != null)
		{
			return this.panel.findFont(size, face, style);
		}

		return ::BasicLayer.findFont(size, face, style);
	}

	function entryPanel( panel )
	{
		this.removePanel(panel);
		this._panellist.append(panel.weakref());
	}

	function removePanel( panel )
	{
		this._panellist.removeValue(panel);
	}

	function findStorage( data, store )
	{
		local storage;
		local rename;

		if (typeof data == "table")
		{
			if ("rename" in data)
			{
				rename = data.rename;
			}

			if ("filename" in data)
			{
				storage = data.filename;
			}
			else if ("storage" in data)
			{
				storage = data.storage;
			}
			else
			{
				throw "storage not found";
			}
		}
		else
		{
			storage = data;
		}

		foreach( data in this._storagelist )
		{
			if (("storage" in data) && data.storage == storage)
			{
				return data;
			}
		}

		foreach( panel in this._panellist )
		{
			local data;
			data = panel.findStorage(storage);

			if (panel != null && data != null)
			{
				if (store)
				{
					this._storagelist.append(data);
				}

				return data;
			}
		}

		local data = ::MotionData(this, this.loadData(storage), rename);

		if (store)
		{
			this._storagelist.append(data);
		}

		return data;
	}

	function openMotionStorage( storage, store = true )
	{
		local ret = [];

		if (typeof storage == "array")
		{
			foreach( name in storage )
			{
				ret.append(this.findStorage(name, store));
			}
		}
		else if (storage != null)
		{
			ret.append(this.findStorage(storage, store));
		}

		return ret.len() > 0 ? ret : null;
	}

	function getMotionData()
	{
		if (this._storagelist.len() > 0)
		{
			return this._storagelist[0].data;
		}
	}

	function getPanel()
	{
		if (this.panel == null)
		{
			this.panel = ::MotionPanel(this, true);
		}

		return this.panel;
	}

	function setEventEnabled( enabled )
	{
		this.getPanel().setEventEnabled(enabled);
	}

	function getEventEnabled()
	{
		return this.getPanel().getEventEnabled();
	}

	function setVariable( name, value, flag = 0, time = 0, accel = 0 )
	{
		this.getPanel().setVariable(name, value, flag, time, accel);
	}

	function getVariable( name )
	{
		return this.getPanel().getVariable(name);
	}

	function onExecute()
	{
	}

	function _work()
	{
		return this.getPanel()._work();
	}

	function work()
	{
		this.getPanel().work();
	}

	function update()
	{
		this.getPanel().update();
	}

	function redraw()
	{
		this.getPanel().redraw();
	}

	function getButton( name )
	{
		return this.getPanel().getButton(name);
	}

	function foreachButton( func )
	{
		return this.getPanel().foreachButton(func);
	}

	function getText( name )
	{
		return this.getPanel().getText(name);
	}

	function clearText( name )
	{
		this.getPanel().clearText(name);
	}

	function getImage( name )
	{
		return this.getPanel().getImage(name);
	}

	function initButton( name )
	{
		return this.getPanel().initButton(name);
	}

	function setDisable( name, disable )
	{
		this.getPanel().setDisable(name, disable);
	}

	function openMotion( storage, context = null, elm = null )
	{
		this.getPanel().openMotion(storage, context, elm);
	}

	function setMotion( elm, force = false )
	{
		this.getPanel().setMotion(elm, force);
	}

	function isMotionLoaded()
	{
		return this.getPanel().isMotionLoaded();
	}

	function open( elm, storage = null, context = null )
	{
		local ret;
		local ishide = !this.visible;

		try
		{
			this.visible = true;
			ret = this.getPanel().open(elm, storage, context);

			if (ishide)
			{
				this.visible = false;
			}
		}
		catch( e )
		{
			if (ishide)
			{
				this.visible = false;
			}

			throw e;
		}

		return ret;
	}

	function show( elm, storage = null, context = null )
	{
		this.visible = true;
		this.getPanel().show(elm, storage, context);
	}

	function hide( cur = null )
	{
		this.getPanel().hide(cur);
		this.visible = false;
	}

	function play( motion, flags = null )
	{
		if (this.visible)
		{
			this.getPanel().play(motion, flags);
		}
	}

	function playWait( motion, flags = null )
	{
		if (this.visible)
		{
			this.getPanel().playWait(motion, flags);
		}
	}

	function onMotionLoad()
	{
	}

	function onMotionOpen( elm )
	{
	}

	function onMotionStart( motion )
	{
	}

	function onMotionPreInit( motion )
	{
	}

	function onMotionInit( motion )
	{
	}

	function onMotionUpdate()
	{
	}

	function onMotionStop( motion )
	{
	}

	function onMotionFocusChange( old, focus )
	{
	}

	function checkCommand( input )
	{
		return false;
	}

	function createPanel( elm = null, storage = null, context = null )
	{
		local ret = ::MotionPanel(this);

		if (elm != null)
		{
			storage = null;
			context = null;
			ret.start(elm, storage, context);
		}

		return ret;
	}

}

function waitMultiMotion( targets, sync )
{
	local list = [];

	foreach( v in targets )
	{
		if ((v instanceof this.MotionPanelLayer) && v.panel != null)
		{
			list.append(v.panel);
		}
		else if (v instanceof this.MotionPanel)
		{
			list.append(v);
		}
	}

	if (list.len() > 0)
	{
		local working;

		do
		{
			sync();

			foreach( v in list )
			{
				v._work();
			}

			working = false;

			foreach( v in list )
			{
				if (v.getMotionPlaying())
				{
					working = true;
					break;
				}
			}
		}
		while (working);

		foreach( v in list )
		{
			v.unlockMotion();
		}
	}
}

