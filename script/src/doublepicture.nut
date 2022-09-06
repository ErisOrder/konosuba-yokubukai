class this.DoubleImage extends this.Object
{
	ratioList = null;
	imageList = null;
	constructor( rsc )
	{
		::Object.constructor();
		this.ratioList = [];

		if ("ratioList" in rsc.root)
		{
			foreach( ratio in rsc.root.ratioList )
			{
				this.ratioList.append(ratio);
			}
		}
		else
		{
			this.ratioList.append(1.0);
		}

		this.imageList = [];

		foreach( i, ratio in this.ratioList )
		{
			this.imageList.append(::Image(rsc, rsc.root.imageList[i].label));
		}
	}

	function destructor()
	{
		this.imageList.clear();
		::Object.destructor();
	}

	function getValid()
	{
		return this.imageList[0].getValid();
	}

	function getWidth()
	{
		return this.imageList[0].getWidth() / this.ratioList[0];
	}

	function getHeight()
	{
		return this.imageList[0].getHeight() / this.ratioList[0];
	}

}

class this.DoublePicture extends this.Object
{
	pictureList = null;
	zoomRatioList = null;
	_visible = false;
	_scale = 1.0;
	_scaleX = 1.0;
	_scaleY = 1.0;
	_basescale = 1.0;
	_opacity = 255;
	scaleAnimeThread = null;
	opacityAnimeThread = null;
	constructor( ... )
	{
		::Object.constructor();
		this._scale = this._basescale;
		this.pictureList = [];
		this.zoomRatioList = [];
		local base;
		local top = 0;

		if (vargc == 2 || vargc == 6)
		{
			top = 1;
			base = vargv[0];
		}

		local bounds = ::getScreenBounds(base);
		this._basescale = this.min(bounds.width / this.SCWIDTH, bounds.height / this.SCHEIGHT);
		this.zoomRatioList = vargv[top].ratioList;
		local imageList = vargv[top].imageList;

		if (vargc < 5)
		{
			foreach( image in imageList )
			{
				this.pictureList.append(this.Picture(base, image));
			}
		}
		else
		{
			local l;
			local t;
			local r;
			local b;
			l = vargv[top + 1];
			t = vargv[top + 2];
			r = vargv[top + 3];
			b = vargv[top + 4];

			foreach( i, image in imageList )
			{
				local z = this.zoomRatioList[i];
				this.pictureList.append(this.Picture(base, image, l * z, t * z, r * z, b * z));
			}
		}

		this.setScale(1, 1);
		this.setOffset(0, 0);
	}

	function destructor()
	{
		this.stopAnime();
		this.pictureList.clear();
		::Object.destructor();
	}

	function setVisible( state )
	{
		this._visible = state;
		this.updateVisibility();
	}

	function getVisible()
	{
		return this._visible;
	}

	function setBlendMode( mode )
	{
		foreach( picture in this.pictureList )
		{
			picture.setBlendMode(mode);
		}
	}

	function setPriority( priority )
	{
		foreach( picture in this.pictureList )
		{
			picture.setPriority(priority);
		}
	}

	function getPriority()
	{
		return this.picture[0].getPriority();
	}

	function setSmoothing( state )
	{
		foreach( picture in this.pictureList )
		{
			picture.setSmoothing(state);
		}
	}

	function getSmootying()
	{
		return this.pictureList[0].getSmoothing();
	}

	function getAnimating()
	{
		return this.pictureList[0].getAnimating() || this.getScaleAnimating() || this.getOpacityAnimating();
	}

	function stopAnime()
	{
		this.stopScaleAnime();
		this.stopOpacityAnime();

		foreach( picture in this.pictureList )
		{
			picture.stopAnime();
		}
	}

	function getWidth()
	{
		return this.pictureList[0].getWidth() / this.ratioList[0];
	}

	function getHeight()
	{
		return this.pictureList[0].getHeight() / this.ratioList[0];
	}

	function setOffset( x, y )
	{
		local w = this.width;
		local h = this.height;

		foreach( i, picture in this.pictureList )
		{
			local s = this.zoomRatioList[i] - 1.0;
			picture.setOffset(x + w / 2 * s, y + h / 2 * s);
		}
	}

	function setCenter( x, y )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setCenter(x * z, y * z);
		}
	}

	function setZoom( z )
	{
		this.setScale(z, z);
	}

	function setScale( x, y )
	{
		this._scaleX = x;
		this._scaleY = y;
		this._scale = this.sqrt(x * y) / this._basescale;

		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setScale(x / z, y / z);
		}

		this.updateVisibility();
	}

	function setAngleRad( rad )
	{
		foreach( picture in this.pictureList )
		{
			picture.setAngleRad(rad);
		}
	}

	function setAngleDeg( deg )
	{
		foreach( picture in this.pictureList )
		{
			picture.setAngleDeg(deg);
		}
	}

	function setBaseClip( x, y, w, h )
	{
		foreach( picture in this.pictureList )
		{
			picture.setBaseClip(x, y, w, h);
		}
	}

	function resetBaseClip()
	{
		foreach( picture in this.pictureList )
		{
			picture.setBaseClip();
		}
	}

	function setClip( x, y, w, h )
	{
		foreach( picture in this.pictureList )
		{
			picture.setClip(x, y, w, h);
		}
	}

	function resetClip()
	{
		foreach( picture in this.pictureList )
		{
			picture.setClip();
		}
	}

	function setOpacity( value )
	{
		this._opacity = value;
		this.updateVisibility();
	}

	function getOpacity()
	{
		return this._opacity;
	}

	function clearImageRange()
	{
		foreach( picture in this.pictureList )
		{
			picture.clearImageRange();
		}
	}

	function assignImageRange( ... )
	{
		if (vargc == 4)
		{
			local l;
			local t;
			local r;
			local b;
			l = vargv[0];
			t = vargv[1];
			r = vargv[2];
			b = vargv[3];

			foreach( i, picture in this.pictureList )
			{
				local z = this.zoomRatioList[i];
				picture.assignImageRange(l * z, t * z, r * z, b * z);
			}
		}
		else if (vargc == 6)
		{
			local l;
			local t;
			local r;
			local b;
			local ox;
			local oy;
			l = vargv[0];
			t = vargv[1];
			r = vargv[2];
			b = vargv[3];
			ox = vargv[4];
			oy = vargv[5];

			foreach( i, picture in this.pictureList )
			{
				local z = this.zoomRatioList[i];
				picture.assignImageRange(l * z, t * z, r * z, b * z, ox * z, oy * z);
			}
		}
	}

	function animateOffset( x, y, frames, accel )
	{
		local w = this.width;
		local h = this.height;

		foreach( i, picture in this.pictureList )
		{
			local s = this.zoomRatioList[i] - 1.0;
			picture.animateOffset(x + w / 2 * s, y + h / 2 * s, frames, accel);
		}
	}

	function animateCenter( x, y, frames, accel )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.animateCenter(x * z, y * z, frames, accel);
		}
	}

	function animateRad( rad, frames, accel )
	{
		foreach( picture in this.pictureList )
		{
			picture.animateRad(rad, frames, accel);
		}
	}

	function animateDeg( deg, frames, accel )
	{
		foreach( picture in this.pictureList )
		{
			picture.animateDeg(deg, frames, accel);
		}
	}

	function calcRatio( ratio, accel )
	{
		if (accel == 0)
		{
			return ratio;
		}
		else if (accel > 10)
		{
			if (ratio < 0.5)
			{
				return this.pow(ratio, accel - 10 + 1);
			}
			else
			{
				return 0.5 + 1 - this.pow(1 - (ratio - 0.5), accel - 10 + 1);
			}
		}
		else if (accel < 10)
		{
			if (ratio < 0.5)
			{
				return 1 - this.pow(1 - ratio, -(accel + 10) + 1);
			}
			else
			{
				return 0.5 + this.pow(ratio - 0.5, -(accel + 10) + 1);
			}
		}
		else if (accel > 0)
		{
			return this.pow(ratio, accel + 1);
		}
		else
		{
			return 1 - this.pow(1 - ratio, -accel + 1);
		}
	}

	function animateScale( x, y, frames, accel )
	{
		this.stopScaleAnime();
		this.scaleAnimeThread = ::fork(function () : ( x, y, frames, accel )
		{
			local fromX = this._scaleX;
			local fromY = this._scaleY;
			local toX = x;
			local toY = y;

			for( local i = 0; i < frames; i += ::System.getPassedFrame() )
			{
				local ratio = this.calcRatio(i * 1.0 / frames, accel);
				this.setScale(fromX * (1 - ratio) + toX * ratio, fromY * (1 - ratio) + toY * ratio);
				::wait();
			}

			this.setScale(toX, toY);
			this.scaleAnimeThread = null;
		}.bindenv(this));
	}

	function stopScaleAnime()
	{
		if (this.scaleAnimeThread != null)
		{
			this.scaleAnimeThread.exit(0);
			this.scaleAnimeThread = null;
		}
	}

	function getScaleAnimating()
	{
		return this.scaleAnimeThread != null && this.scaleAnimeThread.status != 0;
	}

	function animateOpacity( value, frames, accel )
	{
		this.stopOpacityAnime();
		this.opacityAnimeThread = ::fork(function () : ( value, frames, accel )
		{
			local fromOpacity = this._opacity;
			local toOpacity = value;

			for( local i = 0; i < frames; i += ::System.getPassedFrame() )
			{
				local ratio = this.calcRatio(i * 1.0 / frames, accel);
				this.setOpacity(fromOpacity * (1 - ratio) + toOpacity * ratio);
				::wait();
			}

			this.setOpacity(toOpacity);
			this.opacityAnimeThread = null;
		}.bindenv(this));
	}

	function stopOpacityAnime()
	{
		if (this.opacityAnimeThread != null)
		{
			this.opacityAnimeThread.exit(0);
			this.opacityAnimeThread = null;
		}
	}

	function getOpacityAnimating()
	{
		return this.opacityAnimeThread != null && this.opacityAnimeThread.status != 0;
	}

	function updateVisibility()
	{
		foreach( picture in this.pictureList )
		{
			picture.visible = false;
		}

		if (!this._visible)
		{
			return;
		}

		if (this._opacity == 255)
		{
			if (this._scale <= this.zoomRatioList[0])
			{
				this.pictureList[0].visible = true;
				this.pictureList[0].opacity = 255;
			}
			else if (this._scale >= this.zoomRatioList[this.zoomRatioList.len() - 1])
			{
				local last = this.pictureList[this.pictureList.len() - 1];
				last.visible = true;
				last.opacity = 255;
			}
			else
			{
				for( local i = 0; i < this.zoomRatioList.len() - 1; i++ )
				{
					local fromZoom = this.zoomRatioList[i];
					local toZoom = this.zoomRatioList[i + 1];

					if (fromZoom == this._scale)
					{
						this.pictureList[i].visible = true;
						this.pictureList[i].opacity = 255;
						break;
					}
					else if (fromZoom < this._scale && this._scale < toZoom)
					{
						this.pictureList[i].visible = true;
						this.pictureList[i].opacity = 255;
						this.pictureList[i + 1].visible = true;
						this.pictureList[i + 1].opacity = 255.0 * (this._scale - fromZoom) / (toZoom - fromZoom);
						break;
					}
				}
			}
		}
		else
		{
			for( local i = this.zoomRatioList.len() - 1; i >= 0; i-- )
			{
				if (i == 0 || this._scale > this.zoomRatioList[i - 1] && this.zoomRatioList[i] / this._scale < this._scale / this.zoomRatioList[i - 1])
				{
					this.pictureList[i].visible = true;
					this.pictureList[i].opacity = this._opacity;
					break;
				}
			}
		}
	}

}

class this.DoubleLayerPicture extends this.Object
{
	_owner = null;
	pictureList = null;
	zoomRatioList = null;
	_visible = false;
	_opacity = 255;
	_scale = 1.0;
	_basescale = 1.0;
	constructor( ... )
	{
		::Object.constructor();
		local argv = [];

		for( local i = 0; i < vargc; i++ )
		{
			argv.append(vargv[i]);
		}

		this.init(argv);
	}

	function init( argv )
	{
		this.pictureList = [];
		this.zoomRatioList = [];
		this._owner = argv[0].weakref();
		local bounds = ::getScreenBounds(this._owner.getOwner());
		this._basescale = this.min(bounds.width / this.SCWIDTH, bounds.height / this.SCHEIGHT);
		this.zoomRatioList = argv[1].ratioList;
		local imageList = argv[1].imageList;

		foreach( i, image in imageList )
		{
			local picture = this.createPicture(this._owner, image, this.zoomRatioList[i], argv);
			picture.primaryScale = 1.0 / this.zoomRatioList[i];
			this.pictureList.append(picture);
		}

		this._scale = ::getval(this._owner, "_scale", 1.0) / this._basescale;
		this.updateVisibility();
	}

	function destructor()
	{
		this.pictureList.clear();
		::Object.destructor();
	}

	function contains( x, y )
	{
		foreach( picture in this.pictureList )
		{
			if (picture.visible && picture.contains(x, y))
			{
				return true;
			}
		}

		return false;
	}

	function onScale( scale )
	{
		this._scale = scale / this._basescale;
		this.updateVisibility();
	}

	function createPicture( layer, image, z, argv )
	{
		if (argv.len() == 2)
		{
			return this.LayerPicture(layer, image);
		}
		else
		{
			return this.LayerPicture(layer, image, argv[2] * z, argv[3] * z, argv[4] * z, argv[5] * z);
		}
	}

	function setBlendMode( mode )
	{
		foreach( picture in this.pictureList )
		{
			picture.setBlendMode(mode);
		}
	}

	function setVisible( state )
	{
		this._visible = state;
		this.updateVisibility();
	}

	function getVisible()
	{
		return this._visible;
	}

	function setOffset( x, y )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setOffset(x * z, y * z);
		}
	}

	function setScale( x, y )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setScale(x * z, y * z);
		}
	}

	function setRot( r )
	{
		foreach( i, picture in this.pictureList )
		{
			picture.setRot(r);
		}
	}

	function setCoord( x, y )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setCoord(x * z, y * z);
		}
	}

	function setLeft( value )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setLeft(value * z);
		}
	}

	function getLeft()
	{
		return this.pictureList[0].getLeft() / this.zoomRatioList[0];
	}

	function setTop( value )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setTop(value * z);
		}
	}

	function getTop()
	{
		return this.pictureList[0].getTop() / this.zoomRatioList[0];
	}

	function getWidth()
	{
		return this.pictureList[0].getWidth() / this.zoomRatioList[0];
	}

	function getHeight()
	{
		return this.pictureList[0].getHeight() / this.zoomRatioList[0];
	}

	function setOpacity( value )
	{
		this._opacity = value;
		this.updateVisibility();
	}

	function getOpacity()
	{
		return this._opacity;
	}

	function clearImageRange()
	{
		foreach( picture in this.pictureList )
		{
			picture.clearImageRange();
		}
	}

	function assignImageRange( ... )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];

			if (vargc == 4)
			{
				picture.assignImageRange(vargv[0] * z, vargv[1] * z, vargv[2] * z, vargv[3] * z);
			}
			else if (vargc == 6)
			{
				picture.assignImageRange(vargv[0] * z, vargv[1] * z, vargv[2] * z, vargv[3] * z, vargv[4] * z, vargv[5] * z);
			}
		}
	}

	function updateVisibility()
	{
		foreach( picture in this.pictureList )
		{
			picture.visible = false;
		}

		if (!this._visible)
		{
			return;
		}

		if (this._opacity == 255)
		{
			if (this._scale <= this.zoomRatioList[0])
			{
				this.pictureList[0].visible = true;
				this.pictureList[0].opacity = 255;
			}
			else if (this._scale >= this.zoomRatioList[this.zoomRatioList.len() - 1])
			{
				local last = this.pictureList[this.pictureList.len() - 1];
				last.visible = true;
				last.opacity = 255;
			}
			else
			{
				for( local i = 0; i < this.zoomRatioList.len() - 1; i++ )
				{
					local fromZoom = this.zoomRatioList[i];
					local toZoom = this.zoomRatioList[i + 1];

					if (fromZoom == this._scale)
					{
						this.pictureList[i].visible = true;
						this.pictureList[i].opacity = 255;
						break;
					}
					else if (fromZoom < this._scale && this._scale < toZoom)
					{
						this.pictureList[i].visible = true;
						this.pictureList[i].opacity = 255;
						this.pictureList[i + 1].visible = true;
						this.pictureList[i + 1].opacity = 255.0 * (this._scale - fromZoom) / (toZoom - fromZoom);
						break;
					}
				}
			}
		}
		else
		{
			for( local i = this.zoomRatioList.len() - 1; i >= 0; i-- )
			{
				if (i == 0 || this._scale > this.zoomRatioList[i - 1] && this.zoomRatioList[i] / this._scale < this._scale / this.zoomRatioList[i - 1])
				{
					this.pictureList[i].visible = true;
					this.pictureList[i].opacity = this._opacity;
					break;
				}
			}
		}
	}

}

class this.DoubleLayerRaster extends this.DoubleLayerPicture
{
	constructor( ... )
	{
		::Object.constructor();
		local argv = [];

		for( local i = 0; i < vargc; i++ )
		{
			argv.append(vargv[i]);
		}

		this.init(argv);
	}

	function createPicture( layer, image, z, argv )
	{
		if (argv.len() == 2)
		{
			return this.LayerRaster(layer, image);
		}
		else
		{
			return this.LayerRaster(layer, image, argv[2] * z, argv[3] * z, argv[4] * z, argv[5] * z);
		}
	}

	function getRasterTime()
	{
		return this.pictureList.len() > 0 ? this.pictureList[0].getRasterTime() : 0;
	}

	function setRasterTime( time )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setRasterTime(time);
		}
	}

	function setRaster( value )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setRaster(value * z);
		}
	}

	function getRaster()
	{
		return this.pictureList[0].getRaster() / this.zoomRatioList[0];
	}

	function setRasterCycle( value )
	{
		foreach( picture in this.pictureList )
		{
			picture.setRasterCycle(value);
		}
	}

	function getRasterCycle()
	{
		return this.pictureList[0].getRasterCycle();
	}

	function setRasterLines( value )
	{
		foreach( i, picture in this.pictureList )
		{
			local z = this.zoomRatioList[i];
			picture.setRasterLines(value * z);
		}
	}

	function getRasterLines()
	{
		return this.pictureList[0].getRasterLines() / this.zoomRatioList[0];
	}

}

