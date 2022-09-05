this.EMPTY <- {};
function dm( msg )
{
	::print(msg + "\n");
}

function sync()
{
	::suspend();
}

function chopExt( storage )
{
	local f = storage.find(".");

	if (f >= 0)
	{
		return storage.substr(0, f);
	}
	else
	{
		return storage;
	}
}

function exec( script, context = null, error = null )
{
	if (error != null)
	{
		return func();
		  // [018]  OP_POPTRAP        1      0    0    0
		  // [019]  OP_JMP            0      4    0    0
		::printException($[stack offset 4]);
		return error;
	}
	else
	{
		local func = this.compilestring(script);

		if (context != null)
		{
			func = func.bindenv(context);
		}

		return func();
	}
}

function eval( eval, context = null, error = null )
{
	return this.exec("return " + eval, context, error);
}

function tonumber( value )
{
	return value != null ? value.tonumber() : null;
	  // [012]  OP_POPTRAP        1      0    0    0
	  // [013]  OP_JMP            0      6    0    0
	this.printf("warning:can\'t convert to number:%s\n", $[stack offset 1]);
	return 0;
}

function getval( table, name, def = null )
{
	return name in table ? table[name] : def;
}

function getbool( table, name, def = null )
{
	if (name in table)
	{
		local value = table[name];

		if (value != null)
		{
			if (typeof value == "string")
			{
				if (value == "true")
				{
					return true;
				}
				else if (value == "false")
				{
					return false;
				}
			}

			return value.tonumber() != 0;
			  // [025]  OP_POPTRAP        1      0    0    0
			  // [026]  OP_JMP            0     12    0    0
			::printException(value.tonumber() != 0);
			return def != null ? def : false;
		}
	}

	return def;
}

function getint( table, name, def = null )
{
	if (name in table)
	{
		local value = table[name];

		if (value != null)
		{
			if (typeof value == "string")
			{
				if (value == "true")
				{
					return 1;
				}
				else if (value == "false")
				{
					return 0;
				}
			}

			return value.tointeger();
			  // [023]  OP_POPTRAP        1      0    0    0
			  // [024]  OP_JMP            0     12    0    0
			::printException(value.tointeger());
			return def != null ? def : 0;
		}
	}

	return def;
}

function toint( value, def = 0 )
{
	if (value == null)
	{
		return def;
	}

	local type = typeof value;

	if (typeof value == "string")
	{
		if (value == "true")
		{
			return 1;
		}
		else if (value == "false")
		{
			return 0;
		}
	}

	return value.tointeger();
	  // [022]  OP_POPTRAP        1      0    0    0
	  // [023]  OP_JMP            0     12    0    0
	this.printf("warning:can\'t convert to int:%s\n", $[stack offset 1]);
	return def != null ? def : 0;
}

function getfloat( table, name, def = 0 )
{
	if (name in table)
	{
		local value = table[name];

		if (value != null)
		{
			return value.tofloat();
			  // [011]  OP_POPTRAP        1      0    0    0
			  // [012]  OP_JMP            0     12    0    0
			::printException(value.tofloat());
			return def != null ? def : 0;
		}
	}

	return def;
}

function tofloat( value, def = 0 )
{
	if (value == null)
	{
		return def;
	}

	return value.tofloat();
	  // [009]  OP_POPTRAP        1      0    0    0
	  // [010]  OP_JMP            0     12    0    0
	::printException(value.tofloat());
	return def != null ? def : 0;
}

function random( a )
{
	return this.rand1() * a;
}

function rand1()
{
	return this.rand().tofloat() / this.RAND_MAX;
}

function rand0()
{
	return this.rand().tofloat() / (this.RAND_MAX.tofloat() + 1);
}

function intrandom( min = 0, max = 0 )
{
	if (min > max)
	{
		local t = min;
		min = max;
		max = t;
	}

	return (this.rand0() * (max - min + 1)).tointeger() + min;
}

function inherited( target, source )
{
	local p = target.parent;

	while (p != null)
	{
		if (p == source)
		{
			return true;
		}

		p = p.parent;
	}

	return false;
}

function showDict( dict )
{
	this.dm("\x00e8\x00be\x009e\x00e6\x009b\x00b8\x00e5\x0086\x0085\x00e5\x00ae\x00b9\x00e8\x00a1\x00a8\x00e7\x00a4\x00ba");

	foreach( idx, val in dict )
	{
		this.print(idx + ":" + val + "\n");
	}
}

function assignDict( dest, src )
{
	if (src != null)
	{
		foreach( name, value in src )
		{
			dest[name] <- value;
		}
	}
}

function evalColor( col )
{
	if (typeof col == "integer")
	{
		return col;
	}
	else if (typeof col == "string" && col.len() >= 2 && col.slice(0, 2) == "0x")
	{
		return ::eval(col);
	}

	return 0;
}

this.han2zenmap <- {
	[" "] = "\x00e3\x0080\x0080",
	["!"] = "\x00ef\x00bc\x0081",
	["\""] = "\x00e2\x0080\x009d",
	["#"] = "\x00ef\x00bc\x0083",
	["$"] = "\x00ef\x00bc\x0084",
	["%"] = "\x00ef\x00bc\x0085",
	["&"] = "\x00ef\x00bc\x0086",
	["\'"] = "\x00e2\x0080\x0099",
	["("] = "\x00ef\x00bc\x0088",
	[")"] = "\x00ef\x00bc\x0089",
	["*"] = "\x00ef\x00bc\x008a",
	["+"] = "\x00ef\x00bc\x008b",
	[","] = "\x00ef\x00bc\x008c",
	["-"] = "\x00ef\x00bc\x008d",
	["."] = "\x00ef\x00bc\x008e",
	["/"] = "\x00ef\x00bc\x008f",
	["0"] = "\x00ef\x00bc\x0090",
	["1"] = "\x00ef\x00bc\x0091",
	["2"] = "\x00ef\x00bc\x0092",
	["3"] = "\x00ef\x00bc\x0093",
	["4"] = "\x00ef\x00bc\x0094",
	["5"] = "\x00ef\x00bc\x0095",
	["6"] = "\x00ef\x00bc\x0096",
	["7"] = "\x00ef\x00bc\x0097",
	["8"] = "\x00ef\x00bc\x0098",
	["9"] = "\x00ef\x00bc\x0099",
	[":"] = "\x00ef\x00bc\x009a",
	[";"] = "\x00ef\x00bc\x009b",
	["<"] = "\x00ef\x00bc\x009c",
	["="] = "\x00ef\x00bc\x009d",
	[">"] = "\x00ef\x00bc\x009e",
	["?"] = "\x00ef\x00bc\x009f",
	["@"] = "\x00ef\x00bc\x00a0",
	["["] = "\x00ef\x00bc\x00bb",
	["\\"] = "\x00ef\x00bf\x00a5",
	["]"] = "\x00ef\x00bc\x00bd",
	["^"] = "\x00ef\x00bc\x00be",
	_ = "\x00ef\x00bc\x00bf",
	["`"] = "\x00ef\x00bd\x0080",
	["{"] = "\x00ef\x00bd\x009b",
	["|"] = "\x00ef\x00bd\x009c",
	["}"] = "\x00ef\x00bd\x009d",
	["~"] = "\x00ef\x00bf\x00a3",
	a = "\x00ef\x00bd\x0081",
	b = "\x00ef\x00bd\x0082",
	c = "\x00ef\x00bd\x0083",
	d = "\x00ef\x00bd\x0084",
	e = "\x00ef\x00bd\x0085",
	f = "\x00ef\x00bd\x0086",
	g = "\x00ef\x00bd\x0087",
	h = "\x00ef\x00bd\x0088",
	i = "\x00ef\x00bd\x0089",
	j = "\x00ef\x00bd\x008a",
	k = "\x00ef\x00bd\x008b",
	l = "\x00ef\x00bd\x008c",
	m = "\x00ef\x00bd\x008d",
	n = "\x00ef\x00bd\x008e",
	o = "\x00ef\x00bd\x008f",
	p = "\x00ef\x00bd\x0090",
	q = "\x00ef\x00bd\x0091",
	r = "\x00ef\x00bd\x0092",
	s = "\x00ef\x00bd\x0093",
	t = "\x00ef\x00bd\x0094",
	u = "\x00ef\x00bd\x0095",
	v = "\x00ef\x00bd\x0096",
	w = "\x00ef\x00bd\x0097",
	x = "\x00ef\x00bd\x0098",
	y = "\x00ef\x00bd\x0099",
	z = "\x00ef\x00bd\x009a",
	A = "\x00ef\x00bc\x00a1",
	B = "\x00ef\x00bc\x00a2",
	C = "\x00ef\x00bc\x00a3",
	D = "\x00ef\x00bc\x00a4",
	E = "\x00ef\x00bc\x00a5",
	F = "\x00ef\x00bc\x00a6",
	G = "\x00ef\x00bc\x00a7",
	H = "\x00ef\x00bc\x00a8",
	I = "\x00ef\x00bc\x00a9",
	J = "\x00ef\x00bc\x00aa",
	K = "\x00ef\x00bc\x00ab",
	L = "\x00ef\x00bc\x00ac",
	M = "\x00ef\x00bc\x00ad",
	N = "\x00ef\x00bc\x00ae",
	O = "\x00ef\x00bc\x00af",
	P = "\x00ef\x00bc\x00b0",
	Q = "\x00ef\x00bc\x00b1",
	R = "\x00ef\x00bc\x00b2",
	S = "\x00ef\x00bc\x00b3",
	T = "\x00ef\x00bc\x00b4",
	U = "\x00ef\x00bc\x00b5",
	V = "\x00ef\x00bc\x00b6",
	W = "\x00ef\x00bc\x00b7",
	X = "\x00ef\x00bc\x00b8",
	Y = "\x00ef\x00bc\x00b9",
	Z = "\x00ef\x00bc\x00ba"
};
function han2zen( han )
{
	han = han.tostring();
	local ret = "";
	local s = 0;

	while (s < han.len())
	{
		local n = han.mbnext(s);
		local ch = han.substr(s, n);

		if (ch in this.han2zenmap)
		{
			ret += this.han2zenmap[ch];
		}
		else
		{
			ret += ch;
		}

		s += n;
	}

	return ret;
}

function loadData( name )
{
	name = name.tolower();
	local rsc = ::Resource();
	rsc.load(name);

	while (rsc.loading)
	{
		::wait();
	}

	local result = rsc.find(name);

	if (result == null)
	{
		this.printf("%s:\x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e3\x0082\x00aa\x00e3\x0083\x00bc\x00e3\x0083\x0097\x00e3\x0083\x00b3\x00e5\x00a4\x00b1\x00e6\x0095\x0097\n", name);
	}

	return result;
}

function loadBinary( name )
{
	name = name.tolower();
	local rsc = ::Resource();
	rsc.loadBinary(name);

	while (rsc.loading)
	{
		::wait();
	}

	local result = rsc.find(name);

	if (result == null)
	{
		this.printf("%s:\x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e3\x0082\x00aa\x00e3\x0083\x00bc\x00e3\x0083\x0097\x00e3\x0083\x00b3\x00e5\x00a4\x00b1\x00e6\x0095\x0097\n", name);
	}

	return result;
}

function waitKey()
{
	while (true)
	{
		this.sync();

		if (this.checkKeyPressed(this.ENTERKEY))
		{
			break;
		}
	}
}

this._inputkeys <- [
	this.KEY_OK,
	this.KEY_CANCEL,
	1024,
	2048,
	4,
	8,
	512,
	256,
	65536,
	131072,
	64,
	128,
	32,
	16
];
function getPadKey( input = null )
{
	local keys = input ? input.keyPressed(this.KEY_OKLL) : this.checkKeyPressed(this.KEY_OKLL);

	foreach( key in this._inputkeys )
	{
		if ((key & keys) != 0)
		{
			return key;
		}
	}
}

function equals( o1, o2 )
{
	local type = typeof o1;

	if (type != typeof o2)
	{
		return false;
	}

	if (type == "array" || type == "table")
	{
		if (o1 == o2)
		{
			return true;
		}

		if (type == "array")
		{
			if (o1.len() != o2.len())
			{
				return false;
			}
		}

		foreach( n, v in o1 )
		{
			if (!(n in o2) || !this.equals(o2[n], v))
			{
				return false;
			}
		}

		return true;
	}
	else
	{
		return o1 == o2;
	}
}

function _duplicate( type, src )
{
	switch(type)
	{
	case "table":
		local result = {};

		foreach( key, value in src )
		{
			type = typeof value;

			switch(type)
			{
			case "array":
			case "table":
				result[key] <- this._duplicate(type, value);
				break;

			default:
				result[key] <- value;
				break;
			}
		}

		return result;

	case "array":
		local result = [];

		foreach( key, value in src )
		{
			type = typeof value;

			switch(type)
			{
			case "array":
			case "table":
				result.append(this._duplicate(type, value));
				break;

			default:
				result.append(value);
				break;
			}
		}

		return result;
	}
}

function duplicate( src )
{
	return this._duplicate("array", [
		src
	])[0];
}

function round( x )
{
	return x > 0 ? (x + 0.5).tointeger().tofloat() : (x - 0.5).tointeger().tofloat();
}

function getFontSize( data )
{
	if (data != null && (data instanceof ::PSBObject) && ("id" in data.root) && data.root.id == "font")
	{
		return "size" in data.root ? data.root.size : "maxHeight" in data.root ? data.root.maxHeight : 0;
	}

	return 0;
}

function loadImageData( storage )
{
	local l;
	l = storage.rfind(".");

	if (storage != null && l > 0)
	{
	}

	try
	{
		switch(storage.substr(l + 1))
		{
		case "psb":
		case "mtn":
			if (storage.find(":"))
			{
				local slist = storage.split(":");
				local data = [];

				foreach( name in slist )
				{
					if (name != "")
					{
						l = name.rfind(".");

						if (l > 0)
						{
							name = name.substr(0, l);
						}

						name += ".psb";
						local d = this.loadData("motion/" + name);

						if (d != null)
						{
							data.append(d);
						}
					}
				}

				if (data.len() == 0)
				{
					data = null;
				}

				  // [069]  OP_POPTRAP        1      0    0    0
				return data;
			}
			else
			{
				local s;

				if (storage.substr(l + 1) == "mtn")
				{
					s = storage.substr(0, l) + ".psb";
				}
				else
				{
					s = storage;
				}

				  // [087]  OP_POPTRAP        1      0    0    0
				return this.loadData("motion/" + s);
			}

			break;

		default:
			l = $[stack offset 1].find(".imginfo");

			if (l > 0)
			{
				local base = $[stack offset 1].substr(0, l);
				  // [116]  OP_POPTRAP        1      0    0    0
				return {
					data = this.loadData("image/" + base + ".psb"),
					info = this.loadData("image/" + $[stack offset 1])
				};
			}
			else
			{
				  // [125]  OP_POPTRAP        1      0    0    0
				return this.loadData("image/" + $[stack offset 1] + ".psb");
			}

			break;
		}
	}
	catch( e )
	{
		local message = (e instanceof this.Exception) ? e.message : e;
		this.printf("failed to load image:%s:%s\n", $[stack offset 1], message);
	}

	return null;
}

