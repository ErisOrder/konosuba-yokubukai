class this.BasicText extends ::Indicator
{
	owner = null;
	scale = 1.0;
	constructor( owner, size, scale = 1.0 )
	{
		this.owner = owner.weakref();
		this.scale = scale;
		local fontSize = size * scale;
		local data = owner.findFont(fontSize);
		local size = ::getFontSize(data);

		if (data == null || size == 0)
		{
			throw this.Exception("faild to load font");
		}

		::Indicator.constructor(owner, data);
		this.fontScale = fontSize / size;
	}

	function setCoord( left, top )
	{
		::Indicator.setCoord(left * this.scale, top * this.scale);
	}

	function getWidth()
	{
		return ::Indicator.getWidth() / this.scale;
	}

	function getHeight()
	{
		return ::Indicator.getHeight() / this.scale;
	}

	function setColor( color )
	{
		::Indicator.setFontColor(this.ARGB2RGBA(color));
	}

	function setPosition( pos )
	{
		local bounds = ::getScreenBounds(this.owner.getOwner());

		switch(pos)
		{
		case 0:
			this.setCoord(bounds.left + 2, bounds.top + 2);
			break;

		case 1:
			this.setCoord(bounds.left + bounds.width - this.getWidth() - 2, bounds.top + 2);
			break;

		case 2:
			this.setCoord(bounds.left + 2, bounds.top + bounds.height - this.getHeight() - 2);
			break;

		case 3:
			this.setCoord(bounds.left + bounds.width - this.getWidth() - 2, bounds.top + bounds.height - this.getHeight() - 2);
			break;
		}
	}

	function print( msg, position = null )
	{
		::Indicator.print(msg);

		if (position != null)
		{
			this.setPosition(position);
		}
	}

}

