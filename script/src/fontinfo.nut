class this.FontInfo 
{
	constructor()
	{
		this.fontList = [];
	}

	function clear()
	{
		this.fontList.clear();
	}

	function entryFont( fontname )
	{
		local font;
		local data = ::loadData("font/" + fontname + ".psb");
		local size = this.getFontSize(data);

		if (data != null && size > 0)
		{
			local face = "label" in data.root ? data.root.label : null;
			font = [
				size,
				data,
				face
			];
		}

		if (font != null)
		{
			foreach( i, value in this.fontList )
			{
				if (value[0] > font[0])
				{
					this.fontList.insert(i, font);
					return;
				}
			}

			this.fontList.append(font);
		}
	}

	function findFont( size, face = null, style = 0 )
	{
		local last;
		local ret;

		foreach( value in this.fontList )
		{
			if (face == null || face == "" || value[2] == face)
			{
				last = value;

				if (value[0] >= size)
				{
					ret = value;
					break;
				}
			}
		}

		if (ret == null)
		{
			ret = last;
		}

		if (ret != null)
		{
			return ret[1];
		}
	}

	fontList = null;
}

