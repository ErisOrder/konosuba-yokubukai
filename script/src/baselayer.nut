class this.BaseLayer extends ::AffineLayer
{
	name = "name";
	constructor( screen = null, name = "layer" )
	{
		::AffineLayer.constructor(screen);
		this.smoothing = true;
		this.name = name;
	}

	function onDraw()
	{
		if (this._clip != null)
		{
			this.setBaseClip(this._clipx + this._clip.x, this._clipy + this._clip.y, this._clip.w, this._clip.h);
		}
		else
		{
			this.resetBaseClip();
		}
	}

	_clip = null;
	_clipx = 0;
	_clipy = 0;
	function setClip( x, y, w, h )
	{
		if (this._clip == null || this._clip.x != x || this._clip.y != y || this._clip.w != w || this._clip.h != h)
		{
			this._clip = {
				x = x,
				y = y,
				w = w,
				h = h
			};
			::AffineLayer.updateAffine();
		}
	}

	function resetClip()
	{
		this._clip = null;
		::AffineLayer.updateAffine();
	}

	function setClipx( v )
	{
		if (v != this._clipx)
		{
			this._clipx = v;

			if (this._clip != null)
			{
				::AffineLayer.updateAffine();
			}
		}
	}

	function getClipx()
	{
		return this._clipx;
	}

	function setClipy( v )
	{
		if (v != this._clipy)
		{
			this._clipy = v;

			if (this._clip != null)
			{
				::AffineLayer.updateAffine();
			}
		}
	}

	function getClipy()
	{
		return this._clipy;
	}

	function _setInnerVisible( visible )
	{
		::AffineLayer.setVisible(visible);
	}

	function _setInnerOpacity( o )
	{
		this._setInnerVisible(o > 0);
	}

	function _calcOpacity()
	{
		this._setInnerOpacity((this._opacity * this._visvalue / 100).tointeger());
	}

	_visvalue = 0;
	function getVisible()
	{
		return this._visvalue > 0;
	}

	function setVisible( v )
	{
		this._visvalue = v ? 100 : 0;
		this._calcOpacity();
	}

	function getVisvalue()
	{
		return this._visvalue;
	}

	function setVisvalue( v )
	{
		this._visvalue = v;
		this._calcOpacity();
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

	function assign( origlayer )
	{
		::AffineLayer.assign(origlayer);
		this._visvalue = origlayer._visvalue;
		this._opacity = origlayer._opacity;
		this._clip = origlayer._clip != null ? clone origlayer._clip : null;
		this._clipx = origlayer._clipx;
		this._clipy = origlayer._clipy;
	}

}

