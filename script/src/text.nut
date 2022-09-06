this.textTable <- ::loadData("config/text.psb");
function _getSystemText( id )
{
	return this.textTable != null && id in this.textTable.root ? this.textTable.root[id] : id;
}

function getSystemText( id )
{
	local text;
	local error;
	local result;
	local dialog;
	local needspace;

	if (typeof id == "table")
	{
		text = this._getSystemText(::getval(id, "text"));
		error = ::getval(id, "error");
		result = ::getval(id, "result");
		dialog = ::getval(id, "dialog");
		needspace = ::getval(id, "needspace");
	}
	else
	{
		text = this._getSystemText(id);
	}

	if (error != null && text.find("$E") != null)
	{
		text = text.replace("$E", this.format("%08x", error));
	}

	if (dialog != null && text.find("$S") != null)
	{
		text = text.replace("$S", dialog);
	}

	if (result != null && text.find("$R") != null)
	{
		text = text.replace("$R", result);
	}

	if (needspace != null && text.find("$NS") != null)
	{
		if (needspace < 1024 * 1024)
		{
			local k = (needspace + (1024 - 1)) / 1024;
			text = text.replace("$NS", k.tostring() + "KB");
		}
		else
		{
			local m = (needspace + (1024 * 1024 - 1)) / (1024 * 1024);
			text = text.replace("$NS", m.tostring() + "MB");
		}
	}

	return text;
}

