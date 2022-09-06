if (!("LayerMovie" in ::getroottable()))
{
	::LayerMovie <- null;
}

if (!("DrawMovie" in ::getroottable()))
{
	::DrawMovie <- null;
}

this.printf("LayerMovie:%s DrawMovie:%s\n", ::LayerMovie, this.DrawMovie);
class this.NoisePicture extends ::LayerRawTex
{
	constructor( owner, noise )
	{
		::LayerRawTex.constructor(owner, noise.width, noise.height);
		this.generateNoise();
		this._thread = ::fork(function ( info )
		{
			while (info.owner != null)
			{
				info.owner.generateNoise();
				::suspend(info.interval);
			}
		}, {
			owner = this.weakref(),
			interval = noise.noise
		});
	}

	function destructor()
	{
		if (this._thread)
		{
			this._thread.exit();
			this._thread = null;
		}

		::LayerRawTex.destructor();
	}

	_thread = null;
}

class this.TilePicture extends ::LayerPicture
{
	constructor( owner, tile )
	{
		::LayerPicture.constructor(owner, tile.data);
		this._tw = tile.data.width;
		this._th = tile.data.height;
		this._width = tile.width;
		this._height = tile.height;
		this._tilex = 0;
		this._tiley = 0;
		this._updateImage();
	}

	function getVariable( name )
	{
		switch(name)
		{
		case "tilex":
			return this._tilex;

		case "tiley":
			return this._tiley;
		}
	}

	function setVariable( name, value, time = 0, accel = 0 )
	{
		switch(name)
		{
		case "tilex":
			this._tilex = ::tonumber(value);
			this._updateImage();
			break;

		case "tiley":
			this._tiley = ::tonumber(value);
			this._updateImage();
			break;
		}
	}

	_tw = 0;
	_th = 0;
	_width = 0;
	_height = 0;
	_tilex = 0;
	_tiley = 0;
	function _updateImage()
	{
		this.clearImageRange();
		local x = this._tilex;
		local y = this._tiley;

		if (this._tw > 0 && this._th > 0)
		{
			x = x % this._tw;
			y = y % this._th;

			if (x > 0)
			{
				x -= this._tw;
			}

			if (y > 0)
			{
				y -= this._th;
			}

			while (y < this._height)
			{
				local x2 = x;

				while (x2 < this._width)
				{
					local dx = x2;
					local dy = y;
					local sx = 0;
					local sy = 0;
					local sw = this._tw;
					local sh = this._th;

					if (dx < 0)
					{
						sx -= dx;
						sw += dx;
						dx = 0;
					}

					if (dy < 0)
					{
						sy -= dy;
						sh += dy;
						dy = 0;
					}

					if (dx + sw > this._width)
					{
						sw = this._width - dx;
					}

					if (dy + sh > this._height)
					{
						sh = this._height - dy;
					}

					this.assignImageRange(sx, sy, sx + sw, sy + sh, dx, dy);
					x2 += this._tw;
				}

				y += this._th;
			}
		}
	}

}

class this.RollPicture extends ::Object
{
	constructor( owner, roll )
	{
		::Object.constructor();
		this._owner = owner.weakref();
		local images;
		local labels;

		if ("images" in roll)
		{
			images = roll.images;
			labels = roll.labels;
		}
		else
		{
			images = [];
			labels = {};
			local inames = {};

			foreach( i, info in roll.data.root.imageList )
			{
				if (info != null)
				{
					inames[info.label] <- i;
				}
			}

			foreach( info in roll.data.root.rollinfo )
			{
				if (info != null)
				{
					if (typeof info[0] == "string")
					{
						labels[info[0]] <- info[1];
					}
					else
					{
						local imageName = info[2];

						if (imageName in inames)
						{
							local image = ::Image(roll.data, imageName);
							images.append({
								x = info[0],
								y = info[1],
								image = image
							});
						}
						else
						{
							this.printf("failed to load rollimage:%s\n", imageName);
						}
					}
				}
			}

			roll.images <- images;
			roll.labels <- labels;
		}

		this._pictures = [];
		this._maxy = 0;

		foreach( info in images )
		{
			local image = info.image;
			local picture = ::LayerPicture(this._owner, image);
			local x = ::toint(info.x);
			local y = ::toint(info.y);
			picture.setCoord(x, y);
			this._pictures.append(picture);
			this._maxy = ::max(info.y, this._maxy);
		}

		if ("*__rollMax__" in labels)
		{
			this._maxy = labels["*__rollMax__"];
		}

		this._startPos = "rollbegin" in roll ? ::getval(labels, roll.rollbegin, 0) : 0;
		this._endPos = "rollend" in roll ? ::getval(labels, roll.rollend, this._maxy) : this._maxy;
	}

	function setOpacity( opacity )
	{
		foreach( picture in this._pictures )
		{
			picture.setOpacity(opacity);
		}
	}

	function setVisible( v )
	{
		foreach( picture in this._pictures )
		{
			picture.setVisible(v);
		}
	}

	function setOffset( x, y )
	{
		if (x != this._offsetx || y != this._offsety)
		{
			this._offsetx = x;
			this._offsety = y;
			this._updateOffset();
		}
	}

	function setRollvalue( value )
	{
		if (this._rollvalue != value)
		{
			this._rollvalue = value;
			this._updateOffset();
		}
	}

	function getRollvalue()
	{
		return this._rollvalue;
	}

	function setVariable( name, value, time = 0, accel = 0 )
	{
		switch(name)
		{
		case "roll":
			this.setRollvalue(this._startPos + (this._endPos - this._startPos) * value);
			break;

		case "rollvalue":
			this.setRollvalue(value);
			break;
		}
	}

	function getVariable( name )
	{
		switch(name)
		{
		case "roll":
			return (this.getRollvalue() - this._startPos) / (this._endPos - this._startPos);

		case "rollvalue":
			return this.getRollvalue();
		}
	}

	_owner = null;
	_pictures = null;
	_maxy = 0;
	_startPos = 0;
	_endPos = 0;
	_rollvalue = 0;
	_offsetx = 0;
	_offsety = 0;
	function _updateOffset()
	{
		foreach( picture in this._pictures )
		{
			picture.setOffset(this._offsetx, this._offsety + this._rollvalue);
		}
	}

}

class this.MotionData extends ::Object
{
	data = null;
	emote = false;
	function createMotion( data, rename = null )
	{
		local id = this._owner.registerMotionResource(data);

		if (rename != null)
		{
			local list = this._owner.getMotionCharaNameList(id);

			foreach( n in list )
			{
				foreach( r, v in rename )
				{
					if (n.find(r) == 0)
					{
						if (v == null || v == "")
						{
							this._owner.removeMotionChara(id, n);
						}
						else
						{
							this._owner.renameMotionChara(id, n, v);
						}
					}
				}
			}
		}

		return id;
	}

	constructor( owner, data = null, rename = null )
	{
		::Object.constructor();
		this._owner = owner.weakref();
		this.data = data;

		if (data != null)
		{
			local base;

			if (typeof data == "array")
			{
				base = data[0];
				this._id = [];

				foreach( i, v in data )
				{
					this._id.append(this.createMotion(v, rename));
				}
			}
			else
			{
				base = data;
				this._id = this.createMotion(data, rename);
			}

			this.emote = ("metadata" in base.root) && ("format" in base.root.metadata) && base.root.metadata.format == "emote";
		}
	}

	function destructor()
	{
		if (this._owner != null && this._id != null)
		{
			if (typeof this._id == "array")
			{
				foreach( i, v in this._id )
				{
					this._owner.unregisterMotionResource(v);
				}
			}
			else
			{
				this._owner.unregisterMotionResource(this._id);
			}
		}

		::Object.destructor();
	}

	function cloneObj( newowner = null )
	{
		if (newowner != null && this._owner != newowner)
		{
			return ::MotionData(newowner, this.data);
		}

		return this;
	}

	_id = null;
	_owner = null;
}

class this.MotionPicture extends ::Motion
{
	constructor( owner, another = null )
	{
		::Motion.constructor(owner, another);
		this._owner = owner.weakref();
	}

	_owner = null;
	function onAction( label, action )
	{
		if (this._owner != null && "onMotionAction" in this._owner)
		{
			this._owner.onMotionAction(label, action);
		}
	}

}

class this.TextPicture extends ::TextRender
{
	_owner = null;
	constructor( owner, elm )
	{
		this._owner = owner.weakref();
		::TextRender.constructor(owner);
		this.setDefault(this.convertPSBValue(elm));
		local width = ::getint(elm, "width", this.SCWIDTH);
		local height = ::getint(elm, "height", this.SCHEIGHT);
		this.setRenderSize(width, height);
		this.clear();
		this.render(elm.text, 0, 0, 0, false);
		this.done();
	}

	function onEval( name )
	{
		local ret = this._owner.eval(name);

		if (ret == null)
		{
			ret = " ";
		}

		return ret;
	}

	function findFont( size, face = null, type = 0 )
	{
		local ret = this._owner.findFont(size, face, type);

		if (ret == null && face != null)
		{
			ret = this._owner.findFont(size, null, type);
		}

		return ret;
	}

	function findRubyFont( size )
	{
		return this.findFont(size, "ruby");
	}

}

class this.BasicPicture extends ::Object
{
	constructor( owner )
	{
		::Object.constructor();
		this._owner = owner.weakref();
		this._defaultAfx = "DEFAULT_AFX" in this._owner ? this._owner.DEFAULT_AFX : 0;
		this._defaultAfy = "DEFAULT_AFY" in this._owner ? this._owner.DEFAULT_AFY : 0;
	}

	function destructor()
	{
		this.clear();
		::Object.destructor();
	}

	function isEmote()
	{
		return this._picture instanceof ::Emote;
	}

	function isMotion()
	{
		return this._picture instanceof ::Motion;
	}

	function isImage()
	{
		return this._picture != null && this._image != null;
	}

	function contains( x, y )
	{
		return ("contains" in this._picture) && this._picture.contains(x, y);
	}

	function clear()
	{
		this._imageLeft = 0;
		this._imageTop = 0;
		this.curStorage = -1;
		this._picture = null;
		this._motion = null;
		this._imageinfo = null;
		this._image = null;
		this._color = null;
		this._roll = null;
		this._tile = null;
		this._noise = null;
		this._text = null;
		this._movie = null;
		this._rawimage = null;
		this._options = null;
		this._imgWidth = 0;
		this._imgHeight = 0;
		this._afx = 0;
		this._afy = 0;
		this._width = 0;
		this._height = 0;
		this._resolution = 1.0;
	}

	function loadImage( elm )
	{
		this.initVariable();

		if (typeof elm == "instance" && (elm instanceof ::RawImage))
		{
			this._rawimage = elm;
			this._imgWidth = elm.width;
			this._imgHeight = elm.height;
			this._createPicture();
		}
		else if (typeof elm == "instance" && (elm instanceof ::PSBObject))
		{
			this._loadImage(elm);
			this._createPicture();
		}
		else if (typeof elm == "string")
		{
			local data = this.loadImageData(elm);

			if (data != null)
			{
				this._loadImage(data);
				this.curStorage = elm;
			}

			this._createPicture();
		}
		else if (typeof elm == "table")
		{
			local data = ::getval(elm, "imagedata");
			local storage = ::getval(elm, "storage");

			if (storage == null)
			{
				storage = ::getval(elm, "file");
			}

			if (storage == null)
			{
				this.clear();

				if ("chara" in elm)
				{
					this._motion = {
						type = "motion",
						data = null
					};
					this._options = {
						chara = elm.chara
					};
					this._options.motion <- "motion" in elm ? elm.motion : "show";
					this._options.flag <- "flag" in elm ? elm.flag : 1;

					if ("variables" in elm)
					{
						this._options.variables <- elm.variablesag;
					}
				}
				else
				{
					if ("data" in elm)
					{
						local data = elm.data;

						if (typeof data == "instance" && (data instanceof ::RawImage))
						{
							this._rawimage = data;
							this._imgWidth = data.width;
							this._imgHeight = data.height;
						}
						else
						{
							this._imgWidth = ::getint(elm, "width");
							this._imgHeight = ::getint(elm, "height");
							this._rawimage = {
								data = data,
								width = this._imgWidth,
								height = this._imgHeight
							};
						}
					}
					else if ("roll" in elm)
					{
						if (data == null)
						{
							local l;
							local storage = elm.roll;
							l = storage.find(".");

							if (storage != null && l > 0)
							{
								storage = storage.substr(0, l);
							}

							data = this.loadImageData(storage);
						}

						if (data != null)
						{
							this._roll = {
								data = data
							};

							if ("rollbegin" in elm)
							{
								this._roll.rollbegin <- elm.rollbegin;
							}

							if ("rollend" in elm)
							{
								this._roll.rollend <- elm.rollend;
							}
						}
					}
					else
					{
						if (("options" in elm) && ("resolution" in elm.options) && elm.options.resolution != "")
						{
							this._resolution = ::getfloat(elm.options, "resolution") / 100.0;
						}

						local r = this.getResolution();
						this._imgWidth = ::getint(elm, "width") * r;
						this._imgHeight = ::getint(elm, "height") * r;

						if ("text" in elm)
						{
							this._text = elm;
						}
						else if ("noise" in elm)
						{
							this._noise = {
								noise = ::getint(elm, "noise"),
								width = this._imgWidth,
								height = this._imgHeight
							};
						}
						else
						{
							local opac = ::getint(elm, "coloropacity", 255);
							this._color = {
								color = this.evalColor(::getint(elm, "color", 8947848) | opac << 24),
								width = this._imgWidth,
								height = this._imgHeight
							};
						}
					}

					this._options = ::getval(elm, "options");
				}

				this._createPicture();
			}
			else if (storage != this.curStorage)
			{
				local l;
				local ext;
				l = storage.rfind(".");

				if (storage != null && l > 0)
				{
					ext = storage.substr(l + 1);
				}

				switch(ext)
				{
				case "psb":
				case "mtn":
					if (data == null)
					{
						data = this.loadImageData(storage);
					}

					if (data == null)
					{
						this.printf("failed to load motion:%s\n", storage);
					}
					else
					{
						this.clear();
						data = ::MotionData(this._owner, data);

						if (data.emote)
						{
							this._motion = {
								type = "emote",
								data = data,
								color = null,
								meshdivisionratio = 1,
								bustscale = 1,
								hairscale = 1,
								partsscale = 1
							};
						}
						else
						{
							this._motion = {
								type = "motion",
								data = data
							};
						}
					}

					break;

				case "amv":
					this._initMovie(storage.substr(0, l), true);
					break;

				case "mpg":
				case "wmv":
					this._initMovie(storage.substr(0, l), false);
					break;

				default:
					if ("movie" in elm)
					{
						if (elm.movie == "movie")
						{
							this._initMovie(storage, false, ::getbool(elm, "loop", false));
						}
						else if (elm.movie == "amovie")
						{
							this._initMovie(storage, true, ::getbool(elm, "loop", false));
						}
					}
					else if ("tile" in elm)
					{
						if (data == null)
						{
							data = this.loadImageData(storage);
						}

						local image = ::Image(data);
						this.clear();

						if (image)
						{
							this._imgWidth = ::getval(elm, "width", image.width);
							this._imgHeight = ::getval(elm, "height", image.height);
							this._tile = {
								data = image,
								width = this._imgWidth,
								height = this._imgHeight
							};
						}
					}
					else
					{
						if (data == null)
						{
							data = this.loadImageData(storage);
						}

						if (data != null)
						{
							this._loadImage(data);
							this.curStorage = storage;
						}

						if ("width" in elm)
						{
							this._imgWidth = ::toint(elm.width);
						}

						if ("height" in elm)
						{
							this._imgHeight = ::toint(elm.height);
						}
					}

					break;
				}

				this._options = ::getval(elm, "options");
				this._createPicture();
				this.curStorage = storage;
			}
			else
			{
				this._options = ::getval(elm, "options");
				this._updatePicture();
			}
		}

		this._initOptions();
		this._updatePosition();
	}

	function updateEnvironment( elm )
	{
		if (this._picture instanceof ::Emote)
		{
			if ("wind" in elm)
			{
				local wind = elm.wind;
				this._picture.startWind(wind.start, wind.goal, wind.speed, wind.min, wind.max);
			}
		}
	}

	function fill( w, h, color )
	{
		this.clear();
		this._color = {
			color = color,
			width = w,
			height = h
		};
		this._imgWidth = w;
		this._imgHeight = h;
		this._createPicture();
		this._initOptions();
		this._updatePosition();
	}

	function copyImage( origpicture )
	{
		this.clear();
		this._resolution = origpicture._resolution;
		this._width = origpicture._width;
		this._height = origpicture._height;
		this._imageLeft = origpicture._imageLeft;
		this._imageTop = origpicture._imageTop;
		this._imgWidth = origpicture._imgWidth;
		this._imgHeight = origpicture._imgHeight;
		this._afx = origpicture._afx;
		this._afy = origpicture._afy;
		this.curStorage = origpicture.curStorage;
		this._options = origpicture._options;

		if (origpicture._motion != null)
		{
			local origmotion = origpicture._motion;
			local data = origmotion.data != null ? origmotion.data.cloneObj(this._owner) : null;

			if (origmotion.type == "emote")
			{
				this._motion = {
					type = origmotion.type,
					data = data,
					color = origmotion.color,
					meshdivisionratio = origmotion.meshdivisionratio,
					bustscale = origmotion.bustscale,
					hairscale = origmotion.hairscale,
					partsscale = origmotion.partsscale
				};
			}
			else
			{
				this._motion = {
					type = origmotion.type,
					data = data
				};
			}
		}
		else if (origpicture._image != null)
		{
			this._imageinfo = origpicture._imageinfo;
			this._image = origpicture._image;
			this._lip = origpicture._lip;
			this._eye = origpicture._eye;
		}
		else if (origpicture._noise != null)
		{
			this._noise = origpicture._noise;
		}
		else if (origpicture._text != null)
		{
			this._text = origpicture._text;
		}
		else if (origpicture._color != null)
		{
			this._color = origpicture._color;
		}
		else if (origpicture._roll != null)
		{
			this._roll = origpicture._roll;
		}
		else if (origpicture._tile != null)
		{
			this._tile = origpicture._tile;
		}
		else if (origpicture._movie != null)
		{
			this._movie = origpicture._movie;
		}
		else if (origpicture._rawimage != null)
		{
			this._rawimage = origpicture._rawimage;
		}

		this._createPicture(origpicture._picture);
		this._updatePosition();
	}

	function setOptions( options )
	{
		this._options = options;
		this._updatePicture();
		this._initOptions();
		this._updatePosition();
	}

	function getWidth()
	{
		return this._width;
	}

	function setWidth( v )
	{
		if (this._width != v)
		{
			this._width = v;
			this._calcArea();
		}
	}

	function getHeight()
	{
		return this._height;
	}

	function setHeight( v )
	{
		if (this._width != v)
		{
			this._width = v;
			this._calcArea();
		}
	}

	function setSize( width, height )
	{
		this._width = width;
		this._height = height;
		this._calcArea();
	}

	function getImageLeft()
	{
		return this._imageLeft;
	}

	function setImageLeft( v )
	{
		if (this._imageLeft != v)
		{
			this._imageLeft = v;
			this._calcArea();
		}
	}

	function getImageTop()
	{
		return this._imageTop;
	}

	function setImageTop( v )
	{
		if (this._imageTop != v)
		{
			this._imageTop = v;
			this._calcArea();
		}
	}

	function setScale( x, y )
	{
		this._scalex = x;
		this._scaley = y;
		this._updateImagePosition();
	}

	function setOffset( x, y )
	{
		this._offx = x;
		this._offy = y;
		this._updateImagePosition();
	}

	function getVisible( v )
	{
		return this._visible;
	}

	function setVisible( v )
	{
		if (this._visible != v)
		{
			this._picture.setVisible(v);
			this._visible = v;
		}
	}

	function setSpeed( speed )
	{
		if (this._picture != null && "setSpeed" in this._picture)
		{
			this._picture.setSpeed(speed);
		}
	}

	function setOpacity( o )
	{
		if (this._picture != null && "setOpacity" in this._picture)
		{
			this._picture.setOpacity(o);
		}
	}

	function setType( type )
	{
		if (this._picture != null && "setBlendMode" in this._picture)
		{
			this._picture.setBlendMode(type);
		}
	}

	function setRaster( raster )
	{
		this._raster = raster;

		if (raster != 0)
		{
			if (this._picture == null || !(this._picture instanceof ::DoubleLayerRaster))
			{
				this._calcArea();
			}

			if (this._picture != null && (this._picture instanceof ::DoubleLayerRaster))
			{
				this._picture.raster = raster;
			}
		}
		else if (this._picture == null || (this._picture instanceof ::DoubleLayerRaster))
		{
			this._calcArea();
		}
	}

	function setRasterlines( rasterLines )
	{
		this._rasterLines = rasterLines;

		if (this._picture != null && (this._picture instanceof ::DoubleLayerRaster))
		{
			this._picture.rasterLines = rasterLines;
		}
	}

	function setRastercycle( rasterCycle )
	{
		this._rasterCycle = rasterCycle;

		if (this._picture != null && (this._picture instanceof ::DoubleLayerRaster))
		{
			this._picture.rasterCycle = rasterCycle;
		}
	}

	function reset()
	{
		this.setRaster(0);
		this.setRasterlines(100);
		this.setRastercycle(1000);
	}

	function canMove( name )
	{
		if (this._picture instanceof ::Emote)
		{
			switch(name)
			{
			case "$meshdivisionratio":
			case "$bustscale":
			case "$hairscale":
			case "$partsscale":
				return false;
			}

			return name.charAt(0) == "$";
		}

		return false;
	}

	function initVariable()
	{
		this._lip = 0;
		this._eye = 2;
		this._faceover = null;
	}

	function setVariable( name, value, time = 0, accel = 0 )
	{
		if (this._picture instanceof ::Emote)
		{
			if (typeof accel == "string")
			{
				switch(accel.tolower())
				{
				case "accel":
					accel = 1;

				case "decel":
					accel = -1;

				case "acdec":
					accel = 0;

				case "accos":
					accel = 0;

				case "const":
					accel = 0;
				}
			}

			accel = ::tonumber(accel);
			time = time * 60 / 1000;

			switch(name)
			{
			case "meshdivisionratio":
			case "bustscale":
			case "hairscale":
			case "partsscale":
				this._motion[name] <- value;
			}

			this._picture.setVariable(name, value, time, accel);
			  // [062]  OP_JMP            0      0    0    0
		}
		else if ("setVariable" in this._picture)
		{
			this._picture.setVariable(name, value);
		}
		else
		{
			switch(name)
			{
			case "lip":
				local no = this.toint(value, 0);

				if (this._lip != no)
				{
					this._lip = no;
					this._updatePicture();
				}

				break;

			case "eye":
				local no = this.toint(value, 0);

				if (this._eye != no)
				{
					this._eye = no;
					this._updatePicture();
				}

				break;

			case "face":
				if (this._faceover != value)
				{
					this._faceover = value;
					this._updatePicture();
				}

				break;
			}
		}
	}

	function getVariable( name )
	{
		if (this._picture instanceof ::Emote)
		{
			switch(name)
			{
			case "meshdivisionratio":
			case "bustscale":
			case "hairscale":
			case "partsscale":
				return this._motion[name];
			}

			return this._picture.getVariable(name);
		}
		else if ("getVariable" in this._picture)
		{
			return this._picture.getVariable(name);
		}
		else
		{
			switch(name)
			{
			case "lip":
				return this._lip;

			case "eye":
				return this._eye;
			}
		}
	}

	function isMotion()
	{
		return this._picture instanceof ::Motion;
	}

	function isPlayingMotion()
	{
		return (this._picture instanceof ::Motion) && this._picture.visible && this._picture.playing;
	}

	function playMotion( motion, flag = 0 )
	{
		if (this._picture instanceof ::Motion)
		{
			this._picture.play(motion, flag);
			this._callMotionChange();
		}
	}

	function pauseMotion( state )
	{
		if ((this._picture instanceof ::Motion) && this._picture.visible && this._picture.playing)
		{
			this._picture.pause(state);
		}
		else if (this._picture instanceof ::LayerMovie)
		{
		}
	}

	function getLayerMotion( name )
	{
		if (this._picture instanceof ::Motion)
		{
			return this._picture.getLayerMotion(name);
		}
	}

	function canWaitMovie()
	{
		return (this._picture instanceof ::Motion) && this._picture.visible && this._picture.playing || (this._picture instanceof ::LayerMovie) && this._picture.visible && this._picture.playing;
	}

	function stopMovie()
	{
		if (this._picture instanceof ::Motion)
		{
			if (this._picture.getPlaying())
			{
				this._picture.skipToSync();
			}
		}
		else if (this._picture instanceof ::LayerMovie)
		{
			this._picture = null;
			this._movie = null;
		}
	}

	function canDispSync()
	{
		if (this._picture instanceof ::Emote)
		{
			return this._picture.getAnimating();
		}
		else if (this._picture instanceof ::Motion)
		{
			return this._picture.getLoopTime() < 0 && this._picture.getPlaying();
		}

		return false;
	}

	function dispSync()
	{
		if (this._picture instanceof ::Emote)
		{
			if (this._picture.getAnimating())
			{
				this._picture.pass();
			}
		}
		else if (this._picture instanceof ::Motion)
		{
			if (this._picture.getPlaying())
			{
				this._picture.skipToSync();
			}
		}
	}

	function onScale( scale )
	{
		if (this._picture != null && "onScale" in this._picture)
		{
			this._picture.onScale(scale);
		}
	}

	_owner = null;
	_imageinfo = null;
	_lip = 0;
	_eye = 2;
	_faceover = null;
	_image = null;
	_color = null;
	_motion = null;
	_roll = null;
	_tile = null;
	_noise = null;
	_text = null;
	_movie = null;
	_rawimage = null;
	_picture = null;
	_options = null;
	_imgWidth = 0;
	_imgHeight = 0;
	_visible = true;
	curStorage = -1;
	_width = 0;
	_height = 0;
	_imageLeft = 0;
	_imageTop = 0;
	_raster = 0;
	_rasterLines = 0;
	_rasterCycle = 0;
	_resolution = 1.0;
	_defaultAfx = 0;
	_defaultAfy = 0;
	_afx = 0;
	_afy = 0;
	_afxValue = 0;
	_afyValue = 0;
	_scalex = 1.0;
	_scaley = 1.0;
	_rot = 0;
	_offx = 0;
	_offy = 0;
	_imagex = 0;
	_imagey = 0;
	_imagezoom = 1.0;
	_imagerot = 0;
	function suspend()
	{
		if (this._owner != null && "suspend" in this._owner)
		{
			this._owner.suspend();
		}
		else
		{
			::suspend();
		}
	}

	function eval( exp )
	{
		if (this._owner != null && "eval" in this._owner)
		{
			return this._owner.eval(exp);
		}

		return ::eval(exp);
	}

	function loadData( storage )
	{
		if (this._owner != null && "loadData" in this._owner)
		{
			return this._owner.loadData(storage);
		}
		else
		{
			return ::loadData(storage);
		}
	}

	function _calcArea()
	{
		this._createPicture();
		this._updatePosition();
	}

	function _updateAffine()
	{
		if (this._owner != null && "updateAffine" in this._owner)
		{
			this._owner.updateAffine();
		}
	}

	function _callMotionChange()
	{
		if (this._owner != null && "onMotionChange" in this._owner)
		{
			this._owner.onMotionChange();
		}
	}

	function getImageResolution()
	{
		if (this._owner != null && "getImageResolution" in this._owner)
		{
			return this._owner.getImageResolution();
		}

		return 1.0;
	}

	function getResolution()
	{
		return this._resolution * this.getImageResolution();
	}

	function res_align( x )
	{
		local ratio = this.getResolution();

		if (ratio == 1.0)
		{
			return x;
		}

		if (typeof x == "array")
		{
			local ret = [];

			foreach( i, v in x )
			{
				if (v != null)
				{
					ret.append(this.round(v * ratio) / ratio);
				}
			}

			return ret;
		}
		else
		{
			return this.round(x * ratio) / ratio;
		}
	}

	function _calcParam( name )
	{
		local param = "calcParam" in this._owner ? this._owner.calcParam(name) : 1.0;

		if (this._motion != null)
		{
			return this._motion[name] * param;
		}

		return param;
	}

	function _updateImagePosition()
	{
		if (this._picture != null)
		{
			local z = this._imagezoom / this.getResolution();

			if (this._picture instanceof ::Motion)
			{
				this._picture.setCoord(-this._offx + this._imagex, -this._offy + this._imagey);
				this._picture.setZoom(this._scalex * z, this._scaley * z);
				this._picture.setAngleRad(-(this._imagerot + this._rot));
			}
			else if (this._picture instanceof ::Emote)
			{
				this._picture.setCoord(-this._offx + this._imagex, -this._offy + this._imagey);
				this._picture.setScale(this._scalex * z);
				this._picture.setRot(-(this._imagerot + this._rot));
				this._picture.setMeshDivisionRatio(this._calcParam("meshdivisionratio"));
				this._picture.setBustScale(this._calcParam("bustscale"));
				this._picture.setHairScale(this._calcParam("hairscale"));
				this._picture.setPartsScale(this._calcParam("partsscale"));
			}
			else
			{
				if ("setCoord" in this._picture)
				{
					this._picture.setCoord(-this._afxValue, -this._afyValue);
				}

				if ("setOffset" in this._picture)
				{
					this._picture.setOffset(this._offx - this._imagex, this._offy - this._imagey);
				}

				if ("setScale" in this._picture)
				{
					this._picture.setScale(this._scalex * z, this._scaley * z);
				}

				if ("setRot" in this._picture)
				{
					this._picture.setRot(-(this._imagerot + this._rot));
				}
			}
		}
	}

	function calcImageMatrix( x, y, zoom, rot )
	{
		this._imagex = x;
		this._imagey = y;
		this._imagezoom = zoom;
		this._imagerot = rot;
		this._updateImagePosition();
	}

	function _calcCenter( v, base )
	{
		switch(typeof v)
		{
		case "string":
			if (v == "" || v == "default" || v == "void")
			{
				return 0;
			}

			return ::eval(v, {
				center = ::toint(base / 2),
				left = 0,
				top = 0,
				right = base,
				bottom = base
			});

		case "null":
			return ::toint(base / 2);
		}

		return ::tonumber(v) * this.getImageResolution();
	}

	function _updatePosition()
	{
		this._afxValue = this._calcCenter(this._afx, this._imgWidth);
		this._afyValue = this._calcCenter(this._afy, this._imgHeight);
		this._updateAffine();
		this._updateImagePosition();
	}

	function _createPicture( origpicture = null )
	{
		if (this._owner == null)
		{
			return;
		}

		if (this._motion != null)
		{
			if (this._motion.type == "emote")
			{
				this._picture = ::Emote(this._owner, this._motion.data.data);

				if (origpicture instanceof ::Emote)
				{
					this._picture.assignState(origpicture);
				}

				this._motion.main <- {};
				this._motion.diff <- {};

				foreach( name in this._picture.getMainTimelineLabelList() )
				{
					this._motion.main[name] <- true;
				}

				foreach( name in this._picture.getDiffTimelineLabelList() )
				{
					this._motion.diff[name] <- true;
				}

				if (this._motion.color != null)
				{
					this._picture.setColor(this.ARGB2RGBA(4278190080 | this._motion.color));
				}
				else
				{
					this._picture.setColor(this.ARGB2RGBA(4286611584));
				}
			}
			else if (origpicture instanceof ::Motion)
			{
				this._picture = ::MotionPicture(this._owner, origpicture);
				this._picture.eventEnabled = true;
			}
			else
			{
				this._picture = ::MotionPicture(this._owner);
				this._picture.eventEnabled = true;
			}
		}
		else if (this._image != null)
		{
			local rasterTime = (this._picture instanceof ::DoubleLayerRaster) ? this._picture.getRasterTime() : null;

			if (this._imageinfo != null)
			{
				if (this._raster > 0)
				{
					this._picture = ::DoubleLayerRaster(this._owner, this._image);
					this._picture.raster = this._raster;
					this._picture.rasterLines = this._rasterLines;
					this._picture.rasterCycle = this._rasterCycle;

					if (rasterTime != null)
					{
						this._picture.setRasterTime(rasterTime);
					}
				}
				else
				{
					this._picture = ::DoubleLayerPicture(this._owner, this._image);
				}
			}
			else if (this._raster > 0)
			{
				this._picture = ::DoubleLayerRaster(this._owner, this._image, -this._imageLeft, -this._imageTop, this._imgWidth, this._imgHeight);
				this._picture.raster = this._raster;
				this._picture.rasterLines = this._rasterLines;
				this._picture.rasterCycle = this._rasterCycle;

				if (rasterTime != null)
				{
					this._picture.setRasterTime(rasterTime);
				}
			}
			else
			{
				this._picture = ::DoubleLayerPicture(this._owner, this._image, -this._imageLeft, -this._imageTop, this._imgWidth, this._imgHeight);
			}
		}
		else if (this._color != null)
		{
			this._picture = ::FillRect(this._owner);
			this._picture.setSize(this._color.width, this._color.height);
			this._picture.setColor(this.ARGB2RGBA(this._color.color));
		}
		else if (this._roll != null)
		{
			this._picture = ::RollPicture(this._owner, this._roll);

			if (origpicture instanceof ::RollPicture)
			{
				this._picture.rollvalue = origpicture.rollvalue;
			}
		}
		else if (this._tile != null)
		{
			this._picture = ::TilePicture(this._owner, this._tile);

			if (origpicture instanceof ::TilePicture)
			{
				this._picture.tilex = origpicture._tilex;
				this._picture.tiley = origpicture._tiley;
			}
		}
		else if (this._noise != null)
		{
			this._picture = ::NoisePicture(this._owner, this._noise);
		}
		else if (this._text != null)
		{
			this._picture = ::TextPicture(this._owner, this._text);
		}
		else if (this._movie != null)
		{
			if (this._movie instanceof ::DrawMovie)
			{
				this._picture = ::LayerDraw(this._owner, this._movie);
			}
			else if (::LayerMovie != null)
			{
				this._picture = this._createMovie(::LayerMovie(this._owner), this._movie.storage, this._movie.alpha);
			}
		}
		else if (this._rawimage != null)
		{
			this._picture = ::LayerRawTex(this._owner, this._rawimage.width, this._rawimage.height);
			this._picture.restore((this._rawimage instanceof this.RawImage) ? this._rawimage : this._rawimage.data);
		}

		if (this._picture != null)
		{
			this._picture.setVisible(this._visible);
		}

		this._updatePicture();
	}

	function _updatePicture()
	{
		if (this._image != null && this._imageinfo != null && this._picture != null)
		{
			local _face = this._faceover != null ? this._faceover : ::getval(this._options, "face", null);

			if ("crop" in this._imageinfo.root || "eyemap" in this._imageinfo.root || "lipmap" in this._imageinfo.root)
			{
				this._picture.clearImageRange();
				local crop = "crop" in this._imageinfo.root ? this._imageinfo.root.crop : {
					x = 0,
					y = 0,
					w = this._imageinfo.root.w,
					h = this._imageinfo.root.h
				};

				if ("eyemap" in this._imageinfo.root || "lipmap" in this._imageinfo.root)
				{
					local eyemap = "eyemap" in this._imageinfo.root ? this._imageinfo.root.eyemap : null;
					local lipmap = "lipmap" in this._imageinfo.root ? this._imageinfo.root.lipmap : null;
					local lipno;
					local eyeno;

					if (_face != null)
					{
						local f = _face.split(":");

						foreach( v in f )
						{
							local e = this._eye > 0 ? v + this._eye : v;
							local l = this._lip > 0 ? v + this._lip : v;

							if (e in eyemap)
							{
								eyeno = eyemap[e];
							}
							else if (l in lipmap)
							{
								lipno = lipmap[l];
							}
						}

						if (eyeno == null)
						{
							local e = this._eye > 0 ? _face + this._eye : _face;

							if (e in eyemap)
							{
								eyeno = eyemap[e];
							}
						}

						if (lipno == null)
						{
							local l = this._lip > 0 ? _face + this._lip : _face;

							if (l in lipmap)
							{
								lipno = lipmap[l];
							}
						}
					}

					if (eyeno == null && lipno == null)
					{
						this._picture.assignImageRange(0, 0, crop.w, crop.h, crop.x, crop.y);
					}
					else if (eyeno == null)
					{
						local ldiff = this._imageinfo.root.lipdiff;
						local lx = ldiff.x - crop.x;
						local ly = ldiff.y - crop.y;
						local lx2 = lx + ldiff.w;
						local ly2 = ly + ldiff.h;
						local ldh = ldiff.h + 2;
						local ldw = ldiff.w + 2;
						local lhc = ::toint(this._image.height / ldh);
						local lfx = ::toint(lipno / lhc);
						local lfy = lipno % lhc;
						local ldx = this._imageinfo.root.lipdiffbase + ldw * lfx + 1;
						local ldy = ldh * lfy + 1;
						this._picture.assignImageRange(0, 0, crop.w, ly, crop.x, crop.y);
						this._picture.assignImageRange(0, ly, lx, ly2, crop.x, ldiff.y);
						this._picture.assignImageRange(ldx, ldy, ldx + ldiff.w, ldy + ldiff.h, ldiff.x, ldiff.y);
						this._picture.assignImageRange(lx2, ly, crop.w, ly2, ldiff.x + ldiff.w, ldiff.y);
						this._picture.assignImageRange(0, ly2, crop.w, crop.h, crop.x, ldiff.y + ldiff.h);
					}
					else if (lipno == null)
					{
						local ediff = this._imageinfo.root.eyediff;
						local ex = ediff.x - crop.x;
						local ey = ediff.y - crop.y;
						local ex2 = ex + ediff.w;
						local ey2 = ey + ediff.h;
						local dh = ediff.h + 2;
						local dw = ediff.w + 2;
						local hc = ::toint(this._image.height / dh);
						local fx = ::toint(eyeno / hc);
						local fy = eyeno % hc;
						local edx = this._imageinfo.root.eyediffbase + dw * fx + 1;
						local edy = dh * fy + 1;
						this._picture.assignImageRange(0, 0, crop.w, ey, crop.x, crop.y);
						this._picture.assignImageRange(0, ey, ex, ey2, crop.x, ediff.y);
						this._picture.assignImageRange(edx, edy, edx + ediff.w, edy + ediff.h, ediff.x, ediff.y);
						this._picture.assignImageRange(ex2, ey, crop.w, ey2, ediff.x + ediff.w, ediff.y);
						this._picture.assignImageRange(0, ey2, crop.w, crop.h, crop.x, ediff.y + ediff.h);
					}
					else if (true)
					{
						local ediff = this._imageinfo.root.eyediff;
						local ex = ediff.x - crop.x;
						local ey = ediff.y - crop.y;
						local ex2 = ex + ediff.w;
						local ey2 = ey + ediff.h;
						local dh = ediff.h + 2;
						local dw = ediff.w + 2;
						local hc = ::toint(this._image.height / dh);
						local fx = ::toint(eyeno / hc);
						local fy = eyeno % hc;
						local edx = this._imageinfo.root.eyediffbase + dw * fx + 1;
						local edy = dh * fy + 1;
						local ldiff = this._imageinfo.root.lipdiff;
						local lx = ldiff.x - crop.x;
						local ly = ldiff.y - crop.y;
						local lx2 = lx + ldiff.w;
						local ly2 = ly + ldiff.h;
						local ldh = ldiff.h + 2;
						local ldw = ldiff.w + 2;
						local lhc = ::toint(this._image.height / ldh);
						local lfx = ::toint(lipno / lhc);
						local lfy = lipno % lhc;
						local ldx = this._imageinfo.root.lipdiffbase + ldw * lfx + 1;
						local ldy = ldh * lfy + 1;

						if (ly > ey2)
						{
							this._picture.assignImageRange(0, 0, crop.w, ey, crop.x, crop.y);
							this._picture.assignImageRange(0, ey, ex, ey2, crop.x, ediff.y);
							this._picture.assignImageRange(edx, edy, edx + ediff.w, edy + ediff.h, ediff.x, ediff.y);
							this._picture.assignImageRange(ex2, ey, crop.w, ey2, ediff.x + ediff.w, ediff.y);
							this._picture.assignImageRange(0, ey2, crop.w, ly, crop.x, ediff.y + ediff.h);
							this._picture.assignImageRange(0, ly, lx, ly2, crop.x, ldiff.y);
							this._picture.assignImageRange(ldx, ldy, ldx + ldiff.w, ldy + ldiff.h, ldiff.x, ldiff.y);
							this._picture.assignImageRange(lx2, ly, crop.w, ly2, ldiff.x + ldiff.w, ldiff.y);
							this._picture.assignImageRange(0, ly2, crop.w, crop.h, crop.x, ldiff.y + ldiff.h);
						}
						else
						{
							local yd = ey2 - ly;
							local yo = ediff.h - yd;
							local ey2x = ey2 - yd;
							local ediffy2 = ediff.y + yo;
							local elxd = ldiff.x - ediff.x;
							this._picture.assignImageRange(0, 0, crop.w, ey, crop.x, crop.y);
							this._picture.assignImageRange(0, ey, ex, ey2x, crop.x, ediff.y);
							this._picture.assignImageRange(edx, edy, edx + ediff.w, edy + ediff.h - yd, ediff.x, ediff.y);
							this._picture.assignImageRange(ex2, ey, crop.w, ey2x, ediff.x + ediff.w, ediff.y);
							this._picture.assignImageRange(0, ey2x, ex, ey2, crop.x, ediffy2);
							this._picture.assignImageRange(edx, edy + yo, edx + elxd, edy + ediff.h, ediff.x, ediffy2);
							this._picture.assignImageRange(ldx, ldy, ldx + ldiff.w, ldy + yd, ldiff.x, ldiff.y);
							this._picture.assignImageRange(edx + elxd + ldiff.w, edy + yo, edx + ediff.w, edy + ediff.h, ediff.x + elxd + ldiff.w, ediffy2);
							this._picture.assignImageRange(ex2, ey2x, crop.w, ey2, ediff.x + ediff.w, ediffy2);
							this._picture.assignImageRange(0, ly + yd, lx, ly2, crop.x, ldiff.y + yd);
							this._picture.assignImageRange(ldx, ldy + yd, ldx + ldiff.w, ldy + ldiff.h, ldiff.x, ldiff.y + yd);
							this._picture.assignImageRange(lx2, ly + yd, crop.w, ly2, ldiff.x + ldiff.w, ldiff.y + yd);
							this._picture.assignImageRange(0, ly2, crop.w, crop.h, crop.x, ldiff.y + ldiff.h);
						}
					}
					else
					{
						local all = ::Region();
						all.set(0, 0, crop.w, crop.h);
						local ediff;
						local eyereg;
						local ex;
						local ey;
						local edx;
						local edy;

						if (eyeno != null)
						{
							ediff = this._imageinfo.root.eyediff;
							ex = ediff.x - crop.x;
							ey = ediff.y - crop.y;
							all.exclude(ex, ey, ediff.w, ediff.h);
							local dh = ediff.h + 2;
							local dw = ediff.w + 2;
							local hc = ::toint(this._image.height / dh);
							local fx = ::toint(eyeno / hc);
							local fy = eyeno % hc;
							edx = this._imageinfo.root.eyediffbase + dw * fx + 1;
							edy = dh * fy + 1;

							if (lipno == null)
							{
								this._picture.assignImageRange(edx, edy, edx + ediff.w, edy + ediff.h, ediff.x, ediff.y);
							}
							else
							{
								eyereg = ::Region();
								eyereg.set(ex, ey, ediff.w, ediff.h);
							}
						}

						if (lipno != null)
						{
							local ldiff = this._imageinfo.root.lipdiff;
							local lx = ldiff.x - crop.x;
							local ly = ldiff.y - crop.y;
							all.exclude(lx, ly, ldiff.w, ldiff.h);

							if (eyereg != null)
							{
								eyereg.exclude(lx, ly, ldiff.w, ldiff.h);
							}

							local ldh = ldiff.h + 2;
							local ldw = ldiff.w + 2;
							local lhc = ::toint(this._image.height / ldh);
							local lfx = ::toint(lipno / lhc);
							local lfy = lipno % lhc;
							local ldx = this._imageinfo.root.lipdiffbase + ldw * lfx + 1;
							local ldy = ldh * lfy + 1;
							this._picture.assignImageRange(ldx, ldy, ldx + ldiff.w, ldy + ldiff.h, ldiff.x, ldiff.y);
						}

						if (eyereg != null)
						{
							eyereg.offset(-ex, -ey);
							local c = eyereg.getCount();

							for( local i = 0; i < c; i++ )
							{
								local rect = eyereg.getRect(i);
								this._picture.assignImageRange(edx + rect.l, edy + rect.t, edx + rect.r, edy + rect.b, ediff.x + rect.l, ediff.y + rect.t);
							}
						}

						local c = all.getCount();

						for( local i = 0; i < c; i++ )
						{
							local rect = all.getRect(i);
							this._picture.assignImageRange(rect.l, rect.t, rect.r, rect.b, crop.x + rect.l, crop.y + rect.t);
						}
					}
				}
				else if (("facemap" in this._imageinfo.root) && "diff" in this._imageinfo.root)
				{
					local faceno = _face != null ? ::getval(this._imageinfo.root.facemap, _face) : null;

					if (faceno == null)
					{
						this._picture.assignImageRange(0, 0, crop.w, crop.h, crop.x, crop.y);
					}
					else
					{
						local diff = this._imageinfo.root.diff;
						local x = diff.x - crop.x;
						local y = diff.y - crop.y;
						local x2 = x + diff.w;
						local y2 = y + diff.h;
						local dh = diff.h + 2;
						local dw = diff.w + 2;
						local hc = ::toint(this._image.height / dh);
						local fx = ::toint(faceno / hc);
						local fy = faceno % hc;
						local dx = ("diffbase" in this._imageinfo.root ? this._imageinfo.root.diffbase : crop.w) + dw * fx + 1;
						local dy = dh * fy + 1;
						local dx2 = dx + diff.w;
						local dy2 = dy + diff.h;
						this._picture.assignImageRange(0, 0, crop.w, y, crop.x, crop.y);
						this._picture.assignImageRange(0, y, x, y2, crop.x, diff.y);
						this._picture.assignImageRange(dx, dy, dx2, dy2, diff.x, diff.y);
						this._picture.assignImageRange(x2, y, crop.w, y2, diff.x + diff.w, diff.y);
						this._picture.assignImageRange(0, y2, crop.w, crop.h, crop.x, diff.y + diff.h);
					}
				}
				else if ("diff" in this._imageinfo.root)
				{
					local diff = this._imageinfo.root.diff;
					local x = diff.x - crop.x;
					local y = diff.y - crop.y;
					local x2 = x + diff.w;
					local y2 = y + diff.h;
					local dx = ("diffbase" in this._imageinfo.root ? this._imageinfo.root.diffbase : crop.w) + 1;
					local dy = this._lip * (diff.h + 2) + 1;
					local dx2 = dx + diff.w;
					local dy2 = dy + diff.h;
					this._picture.assignImageRange(0, 0, crop.w, y, crop.x, crop.y);
					this._picture.assignImageRange(0, y, x, y2, crop.x, diff.y);
					this._picture.assignImageRange(dx, dy, dx2, dy2, diff.x, diff.y);
					this._picture.assignImageRange(x2, y, crop.w, y2, diff.x + diff.w, diff.y);
					this._picture.assignImageRange(0, y2, crop.w, crop.h, crop.x, diff.y + diff.h);
				}
				else
				{
					this._picture.assignImageRange(0, 0, crop.w, crop.h, crop.x, crop.y);
				}
			}
		}
	}

	function _playTimeline( name, ratio = 1.0, time = 0, easing = 0 )
	{
		if (this._picture.getTimelinePlaying(name))
		{
			if (name in this._motion.diff)
			{
				this._picture.setTimelineBlendRatio(name, ratio, time * 60 / 1000, easing);
			}
		}
		else if (name in this._motion.main)
		{
			this._picture.playTimeline(name, 1);
		}
		else if (name in this._motion.diff)
		{
			this._picture.playTimeline(name, 3);
			this._picture.setTimelineBlendRatio(name, 0, 0, 0);
			this._picture.setTimelineBlendRatio(name, ratio, time * 60 / 1000, easing);
		}
	}

	function _stopTimeline( name, time = 0, easing = 0 )
	{
		if (this._picture.getTimelinePlaying(name))
		{
			if (name in this._motion.main)
			{
				this._picture.stopTimeline(name);
			}
			else if (name in this._motion.diff)
			{
				this._picture.fadeOutTimeline(name, time * 60 / 1000, easing);
			}
		}
	}

	function _setEmoteOptions( _options )
	{
		if ("variables" in _options)
		{
			local vars = _options.variables;

			if (typeof vars == "string")
			{
				vars = this.eval(vars);
			}

			foreach( name, value in vars )
			{
				this._picture.setVariable(name, value);
			}
		}

		local time = ::getint(_options, "time", 0);
		local easing = ::getint(_options, "easing", 0);
		local ratio = ::getint(_options, "ratio", 1.0);

		if ("timelines" in _options)
		{
			if (typeof _options.timelines == "string")
			{
				local stoptls = this._picture.getPlayingTimelineInfoList();
				local tls = _options.timelines.split(":");
				local e = {};

				foreach( tl in tls )
				{
					e[tl] <- true;
				}

				foreach( tl in stoptls )
				{
					if (!(tl.label in e))
					{
						this._stopTimeline(tl.label);
					}
				}

				foreach( tl in tls )
				{
					this._playTimeline(tl);
				}
			}
			else
			{
				local stoptls = this._picture.getPlayingTimelineInfoList();
				local tls = _options.timelines;
				local e = {};

				foreach( tl in tls )
				{
					e[tl] <- true;
				}

				foreach( tl in stoptls )
				{
					if (!(tl.label in e))
					{
						this._stopTimeline(tl.label);
					}
				}

				foreach( tl in tls )
				{
					this._playTimeline(tl.label, ::getfloat(tl, "blendRatio", 1.0));
				}
			}
		}

		if ("stoptimeline" in _options)
		{
			local timeline = _options.stoptimeline;

			if (typeof timeline == "table")
			{
				this._setEmoteOptions(timeline);
			}
			else if (typeof timeline == "array")
			{
				foreach( tl in timeline )
				{
					this._setEmoteOptions(tl);
				}
			}
			else if (timeline == 1 || timeline == "")
			{
				local tls = this._picture.getPlayingTimelineInfoList();

				foreach( tl in tls )
				{
					this._stopTimeline(tls.label, time, easing);
				}
			}
			else
			{
				local tls = timeline.split(":");

				foreach( tl in tls )
				{
					this._stopTimeline(tl, time, easing);
				}
			}
		}

		if ("timeline" in _options)
		{
			local timeline = _options.timeline;

			if (typeof timeline == "table")
			{
				this._setEmoteOptions(timeline);
			}
			else if (typeof timeline == "array")
			{
				foreach( tl in timeline )
				{
					this._setEmoteOptions(tl);
				}
			}
			else if (timeline == 1 || timeline == "")
			{
				local tls = this._picture.getPlayingTimelineInfoList();

				foreach( tl in tls )
				{
					this._stopTimeline(tl.label, time, easing);
				}
			}
			else
			{
				local tls = timeline.split(":");

				foreach( tl in tls )
				{
					this._playTimeline(tl, ratio, time, easing);
				}
			}
		}

		if ("color" in _options)
		{
			if (_options.color == "")
			{
				this._motion.color = null;
				this._picture.setColor(this.ARGB2RGBA(4286611584), time * 60 / 1000, easing);
			}
			else
			{
				this._motion.color = ::toint(_options.color);
				this._picture.setColor(this.ARGB2RGBA(4278190080 | this._motion.color), time * 60 / 1000, easing);
			}
		}
	}

	function _initOptions()
	{
		if (("resolution" in this._options) && this._options.resolution != "")
		{
			this._resolution = ::getfloat(this._options, "resolution") / 100.0;
		}

		this._afx = "afx" in this._options ? this._options.afx : this._defaultAfx;
		this._afy = "afy" in this._options ? this._options.afy : this._defaultAfy;
		local rr = 1.0 / this.getResolution();
		this._width = this._imgWidth * rr;
		this._height = this._imgHeight * rr;

		if (this._picture != null && this._options != null)
		{
			if (this._motion != null)
			{
				if (this._picture instanceof ::Emote)
				{
					this._setEmoteOptions(this._options);
				}
				else if (this._picture instanceof ::MotionPicture)
				{
					if ("chara" in this._options)
					{
						this._picture.chara = this._options.chara;
					}

					if ("motion" in this._options)
					{
						this._picture.play(this._options.motion, ::getval(this._options, "flag", 1));
						this._callMotionChange();
					}

					if ("tickCount" in this._options)
					{
						this._picture.tickCount = this._options.tickCount;
					}

					if ("variables" in this._options)
					{
						local vars = this._options.variables;

						if (typeof vars == "string")
						{
							vars = this.eval(vars);
						}

						foreach( name, value in vars )
						{
							this._picture.setVariable(name, value);
						}
					}
				}
			}
		}
	}

	function _loadImage( data )
	{
		local info;

		if (data instanceof "table")
		{
			info = ::getval(data, "info");
			data = ::getval(data, "data");
		}

		if (data != null)
		{
			this.clear();

			if ("rollinfo" in data.root)
			{
				this._roll = {
					data = data
				};
			}
			else
			{
				if (info != null)
				{
					this._imageinfo = info;
				}
				else if ("crop" in data.root || "eyemap" in data.root || "lipmap" in data.root)
				{
					this._imageinfo = data;
				}
				else
				{
					this._imageinfo = null;
				}

				this._image = ::DoubleImage(data);
				this._lip = 0;
				this._eye = 2;

				if (this._imageinfo != null)
				{
					this._imgWidth = this._imageinfo.root.w;
					this._imgHeight = this._imageinfo.root.h;
				}
				else
				{
					this._imgWidth = this._image.width;
					this._imgHeight = this._image.height;
				}
			}
		}
	}

	function _createMovie( movie, storage, alpha )
	{
		movie.visible = true;
		movie.volume = this.getMovieVolume();
		movie.useAlpha = alpha;
		movie.play("movie/" + storage + ::movieExt);

		while (!movie.playStart)
		{
			this.suspend();
		}

		return movie;
	}

	function _initMovie( storage, alpha, loop = false )
	{
		this.clear();

		if (this.DrawMovie != null)
		{
			this._movie = this._createMovie(this.DrawMovie(), storage, alpha);
		}
		else
		{
			this._movie = {
				storage = storage,
				alpha = alpha
			};
		}
	}

}

