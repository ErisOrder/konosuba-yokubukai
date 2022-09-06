class this.BasePicture extends ::Object
{
	_owner = null;
	_base = null;
	_pictures = null;
	_texts = null;
	constructor( owner )
	{
		::Object.constructor();
		this._owner = owner.weakref();
		this._base = ::BasicPicture(this._owner);
		this._pictures = [];
		this._texts = [];
	}

	function isEmote()
	{
		return this._base.isEmote();
	}

	function isMotion()
	{
		return this._base.isMotion();
	}

	function isImage()
	{
		return this._base.isImage();
	}

	function findFont( size, face = null, style = 0 )
	{
		return this.defaultFont.findFont(size, face, style);
	}

	function contains( x, y )
	{
		return this._base.contains(x, y);
	}

	function reset()
	{
		this._base.reset();
	}

	function onUpdatePicture()
	{
		if ("onUpdatePicture" in this._owner)
		{
			this._owner.onUpdatePicture();
		}
	}

	function onScale( scale )
	{
		this._base.onScale(scale);

		foreach( v in this._pictures )
		{
			v.onScale(scale);
		}
	}

	function canMove( name )
	{
		return this._base.canMove(name);
	}

	function setVariable( name, value, time = 0, accel = 0 )
	{
		this._base.setVariable(name, value, time, accel);
	}

	function getVariable( name )
	{
		return this._base.getVariable(name);
	}

	function calcImageMatrix( mtx )
	{
		local imagex = ::AffineLayer.getImagex.bindenv(this._owner)();
		local imagey = ::AffineLayer.getImagey.bindenv(this._owner)();
		local imagezoom = ::AffineLayer.getImagezoom.bindenv(this._owner)() / 100;
		local imagerot = ::AffineLayer.getImagerotate.bindenv(this._owner)() * this.PI * 2 / 360;
		this._base.calcImageMatrix(imagex, imagey, imagezoom, imagerot);

		foreach( v in this._pictures )
		{
			v.calcImageMatrix(imagex, imagey, imagezoom, imagerot);
		}
	}

	function clear()
	{
		this._base.clear();
		this._pictures.clear();
		this._texts.clear();
		this.onUpdatePicture();
	}

	function clearImage()
	{
		this._base.clear();
		this.onUpdatePicture();
	}

	function clearPicture()
	{
		this._pictures.clear();
	}

	function clearText()
	{
		this._texts.clear();
	}

	function createPicture( elm )
	{
		local picture = ::BasicPicture(this._owner);
		picture.loadImage(elm);
		return picture;
	}

	function drawPicture( elm )
	{
		local picture = this.createPicture(elm);
		this._pictures.append(picture);
		this._calcType();
		this.onUpdatePicture();
		return picture;
	}

	function createText( size = 12, color = 4294967295, scale = 1.0 )
	{
		local t = ::BasicText(this._owner, size, scale);
		t.setColor(color);
		t.visible = true;
		return t;
	}

	function drawText( x, y, text, size = 12, color = 4294967295, scale = 1.0 )
	{
		local t = this.createText(size, color, scale);
		t.print(text);
		t.setCoord(x, y);
		this._texts.append({
			type = 0,
			x = x,
			y = y,
			size = size,
			scale = scale,
			color = color,
			text = text,
			t = t
		});
		return t;
	}

	function createRender( size, rubysize, lineheight, scale = 1.0, baseScale = false )
	{
		return ::BasicRender(this._owner, size, rubysize, lineheight, scale, baseScale);
	}

	function drawTextBox( x, y, width, height, text, size = 12, color = 4294967295, space = 5 )
	{
		local c = this.createRender(size, size / 3, size + space);
		c.setPos(x, y, width, height);
		c.setDefault({
			color = color
		});
		c.render(text);
		this._texts.append({
			type = 1,
			x = x,
			y = y,
			width = width,
			height = height,
			size = size,
			scale = this.scale,
			color = color,
			text = text,
			space = space,
			c = c
		});
		return c;
	}

	function loadImage( elm )
	{
		this._base.loadImage(elm);
		this._calcType();
		this.onUpdatePicture();
	}

	function setOptions( elm )
	{
		this._base.setOptions(elm);
		this._calcType();
		this.onUpdatePicture();
	}

	function updateEnvironment( elm )
	{
		this._base.updateEnvironment(elm);
	}

	function getWidth()
	{
		return this._base.getWidth();
	}

	function getHeight()
	{
		return this._base.getHeight();
	}

	function fill( w, h, color )
	{
		this._base.fill(w, h, color);
		this._calcType();
		this.onUpdatePicture();
	}

	function copyImage( origpicture )
	{
		local oldpictures = this._pictures;
		local oldtexts = this._texts;
		this._pictures = [];
		this._texts = [];
		this._base.copyImage(origpicture._base);

		foreach( v in origpicture._pictures )
		{
			local picture = ::BasicPicture(this._owner);
			picture.copyImage(v);
			this._pictures.append(picture);
		}

		foreach( value in origpicture._texts )
		{
			switch(value.type)
			{
			case 0:
				this.drawText(value.x, value.y, value.size, value.text, value.scale, value.color);
				break;

			case 1:
				this.drawTextBox(value.x, value.y, value.width, value.height, value.size, value.text, value.color, value.space);
				break;
			}
		}

		this._calcType();
		oldpictures.clear();
		oldtexts.clear();
		this.onUpdatePicture();
	}

	function assign( orig )
	{
		this.copyImage(orig);
		this._type = orig._type;
		this._calcType();
		this.onUpdatePicture();
	}

	function setSpeed( speed )
	{
		this._base.setSpeed(speed);
	}

	function setOpacity( o )
	{
		this._base.setOpacity(o);

		foreach( v in this._pictures )
		{
			v.setOpacity(o);
		}
	}

	function setOffset( x, y )
	{
		this._base.setOffset(x, y);

		foreach( v in this._pictures )
		{
			v.setOffset(x, y);
		}
	}

	function _calcType()
	{
		this._base.setType(this._type);

		foreach( v in this._pictures )
		{
			v.setType(this._type);
		}
	}

	_type = 0;
	function setType( type )
	{
		this._type = type.tointeger();
		this._calcType();
	}

	function getType()
	{
		return this._type;
	}

	_raster = 0;
	function getRaster()
	{
		return this._raster;
	}

	function setRaster( raster )
	{
		if (raster == "" || raster == null)
		{
			raster = 0;
		}

		this._base.setRaster(raster);
	}

	_rasterLines = 100;
	function setRasterlines( rasterLines )
	{
		rasterLines = this.toint(rasterLines);

		if (this._rasterLines != rasterLines)
		{
			this._rasterLines = rasterLines;
			this._base.setRasterlines(this._rasterLines);
		}
	}

	function getRasterlines()
	{
		return this._rasterLines;
	}

	_rasterCycle = 1000;
	function setRastercycle( rasterCycle )
	{
		rasterCycle = this.toint(rasterCycle);

		if (this._rasterCycle != rasterCycle)
		{
			this._rasterCycle = rasterCycle;
			this._base.setRastercycle(this._rasterCycle);
		}
	}

	function getRastercycle()
	{
		return this._rasterCycle;
	}

	function isMotion()
	{
		return this._base.isMotion();
	}

	function isPlayingMotion()
	{
		return this._base.isPlayingMotion();
	}

	function playMotion( motion, flag = 0 )
	{
		this._base.playMotion(motion, flag);
	}

	function pauseMotion( state )
	{
		this._base.pauseMotion(state);
	}

	function getLayerMotion( name )
	{
		return this._base.getLayerMotion(name);
	}

	function canWaitMovie()
	{
		return this._base.canWaitMovie();
	}

	function stopMovie()
	{
		this._base.stopMovie();
	}

	function canDispSync()
	{
		return this._base.canDispSync();
	}

	function dispSync()
	{
		this._base.dispSync();
	}

}

