class this.BasicRender extends this.TextRender
{
	following = "%),:;]}\x00e3\x0080\x0082\x00ef\x00bc\x008c\x00e3\x0080\x0081\x00ef\x00bc\x008e\x00ef\x00bc\x009a\x00ef\x00bc\x009b\x00e3\x0082\x009b\x00e3\x0082\x009c\x00e3\x0083\x00bd\x00e3\x0083\x00be\x00e3\x0082\x009d\x00e3\x0082\x009e\x00e3\x0080\x0085\x00e2\x0080\x0099\x00e2\x0080\x009d\x00ef\x00bc\x0089\x00e3\x0080\x0095\x00ef\x00bc\x00bd\x00ef\x00bd\x009d\x00e3\x0080\x0089\x00e3\x0080\x008b\x00e3\x0080\x008d\x00e3\x0080\x008f\x00e3\x0080\x0091\x00c2\x00b0\x00e2\x0080\x00b2\x00e2\x0080\x00b3\x00e2\x0084\x0083\x00ef\x00bf\x00a0\x00ef\x00bc\x0085\x00e2\x0080\x00b0\x00e3\x0080\x0080!.?\x00e3\x0083\x00bb\x00ef\x00bc\x009f\x00ef\x00bc\x0081\x00e3\x0083\x00bc\x00e3\x0081\x0081\x00e3\x0081\x0083\x00e3\x0081\x0085\x00e3\x0081\x0087\x00e3\x0081\x0089\x00e3\x0081\x00a3\x00e3\x0082\x0083\x00e3\x0082\x0085\x00e3\x0082\x0087\x00e3\x0082\x008e\x00e3\x0082\x00a1\x00e3\x0082\x00a3\x00e3\x0082\x00a5\x00e3\x0082\x00a7\x00e3\x0082\x00a9\x00e3\x0083\x0083\x00e3\x0083\x00a3\x00e3\x0083\x00a5\x00e3\x0083\x00a7\x00e3\x0083\x00ae\x00e3\x0083\x00b5\x00e3\x0083\x00b6";
	leading = "\\$([{\x00e2\x0080\x0098\x00e2\x0080\x009c\x00ef\x00bc\x0088\x00e3\x0080\x0094\x00ef\x00bc\x00bb\x00ef\x00bd\x009b\x00e3\x0080\x0088\x00e3\x0080\x008a\x00e3\x0080\x008c\x00e3\x0080\x008e\x00e3\x0080\x0090\x00ef\x00bf\x00a5\x00ef\x00bc\x0084\x00ef\x00bf\x00a1";
	begin = "\x00e3\x0080\x008c\x00e3\x0080\x008e\x00ef\x00bc\x0088\x00e2\x0080\x0098\x00e2\x0080\x009c\x00e3\x0080\x0094\x00ef\x00bc\x00bb\x00ef\x00bd\x009b\x00e3\x0080\x0088\x00e3\x0080\x008a";
	end = "\x00e3\x0080\x008d\x00e3\x0080\x008f\x00ef\x00bc\x0089\x00e2\x0080\x0099\x00e2\x0080\x009d\x00e3\x0080\x0095\x00ef\x00bc\x00bd\x00ef\x00bd\x009d\x00e3\x0080\x0089\x00e3\x0080\x008b";
	constructor( owner, size, rubysize, lineheight, scale = 1.0, baseScale = false )
	{
		::TextRender.constructor(owner);
		::TextRender.setOption({
			following = this.following,
			leading = this.leading,
			begin = this.begin,
			end = this.end
		});
		this._owner = owner.weakref();

		if (baseScale)
		{
			this._scale = scale * ::BASESCALE;
			this._baseScale = 1.0 / ::BASESCALE;
		}
		else
		{
			this._scale = scale;
			this._baseScale = 1.0;
		}

		this._defaults = {};
		this.setDefault({
			fontsize = this.toint(size * this._scale),
			rubysize = this.toint(rubysize * this._scale),
			linespacing = this.toint((lineheight - size) * this._scale)
		});
		this._updatePosition();
	}

	function _updatePosition()
	{
		::TextRender.setOffset(this.toint(this._offx - this._left * this._scale), this.toint(this._offy - this._top * this._scale));
		::TextRender.setScale(this._scalex * this._baseScale, this._scaley * this._baseScale);
	}

	function assign( src )
	{
		this.clear();
		this.setVisible(src._visible);
		this.setDefault(src._defaults);
		this._left = src._left;
		this._top = src;
		this._top;
		this._width = src._width;
		this._height = src._height;
		this._context = src._context;
		this._scalex = src._scalex;
		this._scaley = src._scaley;
		this._offx = src._offx;
		this._offy = src._offy;
		this._fitMode = src._fitMode;
		this._updatePosition();

		if (src._text != null)
		{
			::TextRender.setRenderSize(this.toint(this._width * this._scale), this.toint(this._height * this._scale));

			if (src._font != null)
			{
				::TextRender.setFont(src._font);
			}

			::TextRender.render(src._text, src._indent, 0, 0, false);
			::TextRender.done();
			this._updateFit();
		}

		if (src._showCount != null)
		{
			this.setShowCount(src._showCount);
		}
	}

	function getVisible()
	{
		return this._visible;
	}

	function setVisible( v )
	{
		if (this._visible != v)
		{
			this._visible = v;
			::TextRender.setVisible(v);
		}
	}

	function setDefault( options )
	{
		foreach( n, v in options )
		{
			this._defaults[n] <- v;
		}

		::TextRender.setDefault(this._defaults);
	}

	function setOption( options )
	{
		::TextRender.setOption(options);

		if ("fitMode" in options)
		{
			this._fitMode = options.fitMode;

			if (this._fitMode & 1)
			{
				::TextRender.setOption({
					ignore_overx = true
				});
			}

			if (this._fitMode & 2)
			{
				::TextRender.setOption({
					ignore_overy = true
				});
			}
		}
	}

	function setSize( width, height )
	{
		this._width = width;
		this._height = height;
		::TextRender.setRenderSize(this.toint(this._width * this._scale), this.toint(this._height * this._scale));
	}

	function setPos( left, top, width = null, height = null )
	{
		this._left = left;
		this._top = top;
		this._updatePosition();

		if (width != null)
		{
			this.setSize(width, height);
		}
	}

	function setScale( scalex, scaley = null )
	{
		this._scalex = scalex;
		this._scaley = scaley == null ? scalex : scaley;
		this._updatePosition();
	}

	function setOffset( x, y )
	{
		this._offx = x;
		this._offy = y;
		this._updatePosition();
	}

	function _updateFit()
	{
		if (this._fitMode)
		{
			local b = this.getRenderBounds();
			local rw = b != null ? b.width : this._width;
			local rh = b != null ? b.height : this._height;
			local offx = 0;
			local offy = 0;
			local sx = 1.0;
			local sy = 1.0;

			if (this._fitMode & 1 && rw > this._width)
			{
				sx = this._width / rw;
				offx = b.left * sx;
			}

			if (this._fitMode & 2 && rh > this._height)
			{
				sy = this._height / rh;
				offy = b.top * sy;
			}

			this.setOffset(offx, offy);
			this.setScale(sx, sy);
		}
	}

	function render( text, diff = 0, all = 0, indent = 0, font = null, context = null )
	{
		this._context = context;
		this._text = text;
		this._indent = indent;
		this._font = font;
		::TextRender.clear();

		if (this._font != null)
		{
			::TextRender.setFont(this._font);
		}

		local ret = ::TextRender.render(this._text, this._indent, diff, all, false);
		::TextRender.done();
		this._updateFit();
		return ret;
	}

	function add( text, diff = 0, all = 0 )
	{
		::TextRender.clear();

		if (this._text == null)
		{
			this._text = text;
		}
		else
		{
			::TextRender.render(this._text, this._indent, 0, 0, false);
			this._text += text;
		}

		local ret = ::TextRender.render(text, this._indent, diff, all, false);
		::TextRender.done();
		this._updateFit();
		return ret;
	}

	function clear()
	{
		this._text = null;
		this._indent = 0;
		this._font = null;
		this._showCount = null;
		this._context = null;
		::TextRender.clear();
	}

	function setShowCount( count )
	{
		this._showCount = count;
		::TextRender.setShowCount(count);
	}

	function onEval( name )
	{
		if (name in this._context)
		{
			return this._context[name];
		}

		if (this._owner != null)
		{
		}
		else
		{
			local ret = "";
		}

		return ret;
	}

	_owner = null;
	_scale = 1.0;
	_baseScale = 1.0;
	_defaults = null;
	_visible = false;
	_left = 0;
	_top = 0;
	_width = null;
	_height = null;
	_offx = 0;
	_offy = 0;
	_scalex = 1.0;
	_scaley = 1.0;
	_text = null;
	_font = null;
	_indent = 0;
	_showCount = null;
	_context = null;
	_fitMode = 0;
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

