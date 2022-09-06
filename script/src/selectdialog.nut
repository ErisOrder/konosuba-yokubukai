class this.SelectDialog extends this.MotionPanelLayer
{
	constructor( screen = null, priority = 14, scale = null )
	{
		local info = "defaultMotionInfo" in ::getroottable() ? ::defaultMotionInfo : null;
		::MotionPanelLayer.constructor(screen, info, scale);
		this.setPriority(priority);
	}

	selinfo = null;
	sellist = null;
	function getSelectInfo()
	{
		return this.selinfo;
	}

	function getSelectCount()
	{
		return this.sellist.len();
	}

	function getSelectText( n )
	{
		if (n < this.sellist.len())
		{
			return ::getval(this.sellist[n], "text");
		}
	}

	function getSelectData( n )
	{
		if (n < this.sellist.len())
		{
			return this.sellist[n];
		}
	}

	function select( list, info = null, cur = null, chara = null, storage = null, context = null )
	{
		this.sellist = list;
		this.selinfo = info;

		if (chara == null)
		{
			chara = this.format("SELECT%d", this.sellist.len());
		}

		if (storage == null)
		{
			if (!this.isMotionLoaded())
			{
				storage = "motion/select.psb";
			}
		}

		local e = {
			motion = "show",
			focus = cur,
			selinfo = info
		};

		if (typeof chara == "string")
		{
			e.chara <- chara;
		}
		else if (typeof chara == "table")
		{
			foreach( name, value in chara )
			{
				e[name] <- value;
			}
		}

		return this.open(e, storage, context);
	}

}

function select( selects, screen = null, priority = null )
{
	local list = [];

	foreach( sel in selects )
	{
		list.append({
			text = sel
		});
	}

	local ret = ::SelectDialog(screen, priority).select(list);

	if (ret == "" || ret == "cancel")
	{
		ret = null;
	}

	return ret;
}

