class this.BasicLayer extends ::Layer
{
	name = "name";
	_picture = null;
	constructor( screen = null, name = "layer" )
	{
		::Layer.constructor(screen);
		this._picture = ::BasePicture(this);
		::Layer.setDelegate(this._picture);
		this.reset();
		this.name = name;
	}

	function destructor()
	{
		this._picture = null;
		::Layer.destructor();
	}

	function setDelegate( target )
	{
		this._picture.setDelegate(target);
	}

	function findFont( size, face = null, style = 0 )
	{
		return this._picture.findFont(size, face, style);
	}

	function contains( x, y )
	{
		return this._picture.contains(x + this.getOffsetX(), y + this.getOffsetY());
	}

	function onUpdatePicture()
	{
		this._calcOpacity();
	}

	function _calcOpacity()
	{
		this._picture.setOpacity(this._opacity);
	}

	_opacity = 255;
	function getOpacity()
	{
		return this._opacity;
	}

	function setOpacity( v )
	{
		if (v > 255)
		{
			v = 255;
		}

		if (this._opacity != v)
		{
			this._opacity = v.tointeger();
			this._calcOpacity();
		}
	}

	function canMove( name )
	{
		return this._picture.canMove(name);
	}

	function loadImage( elm )
	{
		this._picture.loadImage(elm);
	}

	function copyImage( origlayer )
	{
		if ("_picture" in origlayer)
		{
			this._picture.copyImage(origlayer._picture);
		}
	}

	function assign( origlayer )
	{
		if ("_picture" in origlayer)
		{
			this._picture.assign(origlayer._picture);
		}
	}

}

class this.BasicAffineLayer extends ::BaseLayer
{
	_picture = null;
	constructor( screen = null, name = "layer" )
	{
		::BaseLayer.constructor(screen, name);
		this._picture = ::BasePicture(this);
		::Object.setDelegate(this._picture);
		this.reset();
	}

	function destructor()
	{
		this._picture = null;
		::BaseLayer.destructor();
	}

	function setDelegate( target )
	{
		this._picture.setDelegate(target);
	}

	function findFont( size, face = null, style = 0 )
	{
		return this._picture.findFont(size, face, style);
	}

	_scale = 1.0;
	function onScale( x, y )
	{
		this._scale = this.sqrt(x * y);
		this._picture.onScale(this._scale);
	}

	function onUpdatePicture()
	{
		this._calcOpacity();
	}

	function containsImage( x, y )
	{
		return this._picture.contains(x, y);
	}

	function calcImageMatrix( mtx )
	{
		this._picture.calcImageMatrix(mtx);
	}

	function _setInnerOpacity( o )
	{
		this._picture.setOpacity(o);
		::BaseLayer._setInnerOpacity(o);
	}

	function setPos( left, top, width = null, height = null )
	{
		this.setLeft(left.tofloat());
		this.setTop(top.tofloat());

		if (width != null || height != null)
		{
			this.setSize(width, height);
		}
	}

	function canMove( name )
	{
		return this._picture.canMove(name);
	}

	function loadImage( elm )
	{
		this._picture.loadImage(elm);
	}

	function copyImage( origlayer )
	{
		if ("_picture" in origlayer)
		{
			this._picture.copyImage(origlayer._picture);
		}
	}

	function assign( origlayer )
	{
		::BaseLayer.assign(origlayer);

		if ("_picture" in origlayer)
		{
			this._picture.assign(origlayer._picture);
		}
	}

	function reset()
	{
		this.setOpacity(255);
		this.setRotate(0);
		this.setZoom(100);
		this._picture.reset();
	}

}

