class this.ConfirmDialog extends this.MotionPanelLayer
{
	_basescale = 1.0;
	constructor( screen = null, priority = 30, shift = 0 )
	{
		local info = "defaultMotionInfo" in ::getroottable() ? ::defaultMotionInfo : null;
		::MotionPanelLayer.constructor(screen, info);
		local bounds = ::getScreenBounds(screen);
		this._basescale = this.min(bounds.width / this.BASEWIDTH, bounds.height / this.BASEHEIGHT);
		this.setPriority(priority);
		this.setShift(shift);
	}

	function setShift( v )
	{
		v = -this._basescale * v;
		this.setOffset(v, v);
	}

	_text = null;
	function getMessage()
	{
		return this._text;
	}

	function setMessage( text )
	{
		this._text = this.getSystemText(text);
		this.redraw();
	}

	function show( text, cur = null, chara = "NOTIFY", storage = null )
	{
		this._text = this.getSystemText(text);

		if (storage == null)
		{
			if (!this.isMotionLoaded())
			{
				storage = "motion/dialog.psb";
			}
		}

		::MotionPanelLayer.show({
			chara = chara,
			focus = cur
		}, storage);
		this.sync();
	}

	function open( text, cur = 0, chara = "YESNO", storage = null )
	{
		this._text = this.getSystemText(text);

		if (storage == null)
		{
			if (!this.isMotionLoaded())
			{
				storage = "motion/dialog.psb";
			}
		}

		return ::MotionPanelLayer.open({
			chara = chara,
			motion = "show",
			focus = cur
		}, storage);
	}

	function confirm( text, cur = 0 )
	{
		return this.open(text, cur, "YESNO");
	}

	function inform( text, cur = 0 )
	{
		return this.open(text, cur, "OK");
	}

	function halt( text )
	{
		this.show(text);

		while (true)
		{
			this.sync();
		}
	}

}

function confirm( text, cur = 0, screen = null, priority = 30, shift = 0 )
{
	return ::ConfirmDialog(screen, priority, shift).confirm(text, cur) != 0;
}

function inform( text, screen = null, priority = 30, shift = 0 )
{
	::ConfirmDialog(screen, priority, shift).inform(text);
}

function halt( text, screen = null, priority = 30, shift = 0 )
{
	::ConfirmDialog(screen, priority, shift).halt(text);
}

