class this.PlayerControlException extends this.GameStateException
{
	constructor( type )
	{
		::GameStateException.constructor(type);
	}

}

class this.HistoryJumpException extends this.PlayerControlException
{
	pos = null;
	constructor( pos )
	{
		::PlayerControlException.constructor("history");
		this.pos = pos;
	}

}

class this.NextJumpException extends this.PlayerControlException
{
	constructor()
	{
		::PlayerControlException.constructor("next");
	}

}

class this.OutlineChangeException extends this.PlayerControlException
{
	constructor()
	{
		::PlayerControlException.constructor("outline");
	}

}

class this.RedrawException extends this.PlayerControlException
{
	constructor()
	{
		::PlayerControlException.constructor("redraw");
	}

}

function convLangText( ret, data )
{
	if (data.len() > 0 && data[0] != null && data[0] != "")
	{
		ret.disp <- data[0];
	}

	if (data.len() > 1 && data[1] != null && data[1] != "")
	{
		ret.text <- data[1];
	}
}

function convertSceneText( array )
{
	if (array != null)
	{
		local ret = {};
		ret.name <- array[0];
		ret.disp <- array[1];

		if (typeof array[2] == "array")
		{
			local l = array[2];
			this.convLangText(ret, l[0]);
			local language = [];

			foreach( v in l )
			{
				local ret = {};
				this.convLangText(ret, v);
				language.append(ret);
			}

			ret.language <- language;
		}
		else
		{
			ret.text <- array[2];
		}

		local voice = array[3];

		if (typeof voice == "string")
		{
			ret.voice <- [
				{
					name = ret.name,
					voice = voice
				}
			];
		}
		else if (voice != null)
		{
			ret.voice <- voice;
		}

		local flag = array[4];
		ret.flag <- flag;
		ret.indent <- flag & 128 ? (flag & 256 ? -1 : 1) : 0;
		ret.state <- array[5];

		if (array.len() > 6)
		{
			ret.nowaitTime <- array[6];
		}
		else
		{
			ret.nowaitTime <- 0;
		}

		return ret;
	}
}

function parseLangTextName( text )
{
	if ("language" in text)
	{
		local lang = text.language;
		local ret = [];
		ret.resize(lang.len());
		ret[0] = ("disp" in text) && text.disp != null ? text.disp : text.name;

		foreach( i, tl in lang )
		{
			if ("disp" in tl)
			{
				ret[i] = tl.disp;
			}
			else if ("name" in tl)
			{
				ret[i] = tl.name;
			}
		}

		return ret;
	}

	if (("disp" in text) && text.disp != null)
	{
		return text.disp;
	}

	return "name" in text ? text.name : "";
}

function parseLangText( text, name )
{
	if ("language" in text)
	{
		local lang = text.language;
		local ret = [];
		ret.resize(lang.len());
		ret[0] = name in text ? text[name] : "";

		foreach( i, tl in lang )
		{
			if (name in tl)
			{
				ret[i] = tl[name];
			}
		}

		return ret;
	}

	return name in text ? text[name] : "";
}

function catLangText( text1, text2 )
{
	if (typeof text1 == "array" || typeof text2 == "array")
	{
		local l = ::max(typeof text1 == "array" ? text1.len() : 1, typeof text2 == "array" ? text2.len() : 0);
		local ret = [];

		for( local i = 0; i < l; i++ )
		{
			ret.append(::getLanguageText(text1, i) + ::getLanguageText(text2, i));
		}

		return ret;
	}

	return text1 + text2;
}

class this.StorageData extends this.Object
{
	storage = null;
	data = null;
	scenes = null;
	sceneMap = null;
	outlines = null;
	constructor( storage )
	{
		this.Object.constructor();
		this.storage = storage;
		this.sceneMap = {};
		local path = "scenario/" + storage + ".scn";
		this.data = ::loadData(path);
		this.scenes = this.data.root.scenes;

		foreach( scene in this.scenes )
		{
			this.sceneMap[scene.label] <- scene;

			if ("jumplabels" in scene)
			{
				foreach( name, value in scene.jumplabels )
				{
					this.sceneMap[name] <- scene;
				}
			}
		}

		this.outlines = this.data.root.outlines;
	}

	function findScene( label )
	{
		if (this.scenes != null)
		{
			if (label == "" || label == null)
			{
				return this.scenes[0];
			}

			if (label in this.sceneMap)
			{
				return this.sceneMap[label];
			}
		}

		throw "\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0083\x00a9\x00e3\x0083\x0099\x00e3\x0083\x00ab\x00e3\x0081\x00ab\x00e5\x0090\x0088\x00e8\x0087\x00b4\x00e3\x0081\x0099\x00e3\x0082\x008b\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e3\x0081\x008c\x00e8\x00a6\x008b\x00e3\x0081\x00a4\x00e3\x0081\x008b\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093:" + label;
	}

	function findSceneLine( line )
	{
		if (this.scenes != null)
		{
			local count = this.scenes.len();

			for( local i = 0; i < count - 1; i++ )
			{
				local scene = this.scenes[i];
				local nscene = this.scenes[i + 1];

				if (line < nscene.firstLine)
				{
					return scene;
				}
			}

			if (count > 0)
			{
				return this.scenes[count - 1];
			}
		}

		throw "\x00e6\x008c\x0087\x00e5\x00ae\x009a\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e8\x00a1\x008c\x00e3\x0081\x00ab\x00e5\x0090\x0088\x00e8\x0087\x00b4\x00e3\x0081\x0099\x00e3\x0082\x008b\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e3\x0081\x008c\x00e8\x00a6\x008b\x00e3\x0081\x00a4\x00e3\x0081\x008b\x00e3\x0082\x008a\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093:" + line;
	}

	function getText( label, idx, title = false )
	{
		local scene = this.findScene(label);
		local ret = this.convertSceneText(scene.texts[idx - 1]);

		if (ret != null && title)
		{
			ret.title <- scene.title;
		}

		return ret;
	}

	function getOutlineLine( no, cur )
	{
		if (no < this.outlines.len())
		{
			local olines = this.outlines[no].lines;

			if (cur < olines.len())
			{
				return olines[cur];
			}
		}
	}

	function getOutlineText( no, idx )
	{
		if (no < this.outlines.len())
		{
			local otexts = this.outlines[no].texts;
			idx--;

			if (idx < otexts.len())
			{
				return this.convertSceneText(otexts[idx]);
			}
		}
	}

}

class this.EnvMessage extends ::MotionPanelLayer
{
	languageId = 0;
	currentType = null;
	currentText = null;
	currentCount = 0;
	currentName = null;
	currentWait = 0;
	currentReaded = 0;
	currentIndent = 0;
	currentShow = false;
	currentTimeScale = 1.0;
	_clearFlag = false;
	constructor( screen, priority, scale = null )
	{
		local info = "defaultMotionInfo" in ::getroottable() ? ::defaultMotionInfo : null;
		::MotionPanelLayer.constructor(screen, info, scale);
		this.setPriority(priority);
	}

	function onExecute()
	{
		this.onExecuteCommand();
	}

	function getTimeScale()
	{
		return this.currentTimeScale;
	}

	function setTimeScale( scale )
	{
		this.currentTimeScale = scale;
	}

	function entryTrans()
	{
		this.entryTransitionLayer(this);
	}

	function doneTrans()
	{
		this.doneTransitionLayer(this);
	}

	function onPrepareTransition( msgchange )
	{
		if (msgchange == null || this.currentShow == msgchange)
		{
			this.entryTrans();
		}
		else if (msgchange)
		{
			this.doneTrans();
		}
	}

	function onSetupTransition( msgchange )
	{
		if (msgchange != null)
		{
			if (msgchange)
			{
				this.msgon(0);
			}
		}
	}

	function doneTransition( msgchange )
	{
		if (msgchange != null)
		{
			if (!msgchange)
			{
				this.msgoff(0);
			}

			this.doneTrans();
		}
	}

	function updateTransparency()
	{
		this.setVariable("transparency", this.getConfig("transparency", 0));
		this.setVariable("opacity", this.getConfig("opacity", 0));
	}

	function updateMsg()
	{
	}

	function setType( type )
	{
		if (this.currentType != type)
		{
			this.currentType = type;
			this.updateTransparency();
			this.setMotion({
				chara = type
			});
		}

		this.clear();
	}

	function _setDefaultColor( text, readed )
	{
		if (text == null)
		{
			return;
		}

		local color;
		local shadowcolor;

		if (readed)
		{
			color = ::getval(text.elm, "readedColor");
			shadowcolor = ::getval(text.elm, "readedShadowColor");
		}

		if (color == null)
		{
			color = ::getval(text.elm, "color");
		}

		if (shadowcolor == null)
		{
			shadowcolor = ::getval(text.elm, "shadowColor");
		}

		if (color != null || shadowcolor != null)
		{
			local def = {};

			if (color != null)
			{
				def.color <- color;
			}

			if (shadowcolor != null)
			{
				def.shadowcolor <- shadowcolor;
			}

			text.setTextDefault(def);
		}
	}

	function setDefaultColor( readed )
	{
		this._setDefaultColor(this.getText("name"), readed);
		this._setDefaultColor(this.getText("message"), readed);
	}

	function writeName( name )
	{
		if (typeof name == "array")
		{
			name = name[0];
		}

		if (this.currentName != name)
		{
			this.currentName = name;
			this.setVariable("nameVisible", name != null && name != "" && name != " ");
			local _text = this.getText("name");

			if (_text != null)
			{
				_text.setText(this.currentName);
			}
		}
	}

	function write( text, diff = 0, all = 0, indent = 0 )
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			_text.setTimeScale(this.currentTimeScale);

			if (this.currentText == null)
			{
				_text.setText(text, diff, all, indent);
				this.currentIndent = indent;
			}
			else
			{
				_text.addText(text, diff, all);
			}

			this.currentCount = _text.getRenderCount();
		}

		this.currentText = this.currentText == null ? text : this.currentText + text;
	}

	function clear()
	{
		this.currentName = null;
		this.currentText = null;
		this.currentIndent = false;
		this.currentCount = 0;
		this.clearText("name");
		this.clearText("message");
		this.setVariable("nameVisible", false);
		this._clearFlag = false;
	}

	function setClear()
	{
		this._clearFlag = true;
	}

	function doClear()
	{
		if (this._clearFlag)
		{
			this.clear();
		}
	}

	function msgon( time = 0, wait = true )
	{
		if (!this.currentShow)
		{
			this.currentShow = true;
			this.doClear();
			this.updateTransparency();
			this.updateMsg();
			this.visible = true;
			local motion = time > 0 ? "show" : "normal";

			if (wait)
			{
				this.playWait(motion);
			}
			else
			{
				this.play(motion);
			}
		}
	}

	function msgoff( time = 0, wait = true )
	{
		if (this.currentShow)
		{
			this.currentShow = false;
			this.updateTransparency();
			this.updateMsg();

			if (time > 0)
			{
				if (wait)
				{
					this.playWait("hide");
					this.visible = false;
				}
				else
				{
					this.play("hide");
				}
			}
			else
			{
				this.visible = false;
			}
		}
	}

	function getRenderOver()
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			return _text.getRenderOver();
		}

		return false;
	}

	function getRenderCount()
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			return _text.getRenderCount();
		}

		return 0;
	}

	function getRenderDelay()
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			return _text.getRenderDelay();
		}

		return 0;
	}

	function getKeyWait()
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			return _text.getKeyWait();
		}
	}

	function setShowCount( count )
	{
		if (this.currentCount != count)
		{
			this.currentCount = count;
			local _text = this.getText("message");

			if (_text != null)
			{
				_text.setShowCount(count);
			}
		}
	}

	function calcShowCount( time )
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			return _text.calcShowCount(time);
		}

		return 0;
	}

	function updateWaitState()
	{
		this.setVariable("wait", this.currentWait);
		this.setVariable("readed", this.currentReaded);
	}

	function setWait( wait, readed = false )
	{
		this.currentWait = wait;
		this.currentReaded = readed;
		this.updateWaitState();
	}

	function setOption( name, value )
	{
		local _text = this.getText("message");

		if (_text != null)
		{
			_text.setOption(name, value);
		}
	}

	function getMessageText()
	{
		return [
			this.currentText,
			this.currentCount,
			this.currentIndent
		];
	}

	function getNameText()
	{
		return this.currentName;
	}

	function getNameVisible()
	{
		return this.currentName != null && this.currentName != "";
	}

	function getFaceVisible()
	{
		return this.env.checkMsgwinLayer();
	}

	function getWait()
	{
		return this.currentWait;
	}

	function getReaded()
	{
		return this.currentReaded;
	}

}

class this.GetSet 
{
	getter = null;
	setter = null;
	constructor( getter, setter )
	{
		this.getter = getter;
		this.setter = setter;
	}

	function _get( name )
	{
		return this.getter(name);
	}

	function _set( name, value )
	{
		this.setter(name, value);
	}

}

class this.EnvVoice extends this.SimpleSound
{
	constructor( owner = null )
	{
		::SimpleSound.constructor(owner);
	}

	target = null;
	name = null;
	function clearTarget()
	{
		if (this.target)
		{
			foreach( t in this.target )
			{
				this.owner.onFlip(t);
			}

			this.target = null;
		}
	}

	function _stop()
	{
		::SimpleSound._stop();
		this.name = null;
		this.clearTarget();
	}

	function onPlayState( state, user = false )
	{
		::SimpleSound.onPlayState(state, user);

		if (!state)
		{
			this.name = null;
			this.clearTarget();
		}
	}

	function _working( storage, option )
	{
		if (option == null || !("player" in option))
		{
			return;
		}

		local player = option.player;
		this.name = ::getval(option, "name");

		if (option.vols != null && option.vols.len() > 0)
		{
			this.target = option.target;

			if (0)
			{
				local vlimit1 = [];
				local vlimit2 = [];

				if (this.target != null)
				{
					foreach( t in this.target )
					{
						local level = player.getVoiceLevel(t);

						if (level != null)
						{
							vlimit1.append(level[0]);
							vlimit2.append(level[1]);
						}
						else
						{
							vlimit1.append(26);
							vlimit2.append(115);
						}
					}
				}

				local vols = option.vols;
				local labels = option.labels;
				local n = 0;
				local vl = vols != null ? vols.len() : 0;
				local ll = labels != null ? labels.len() : 0;
				local i = 0;
				local p;

				for( p = this.getVoicePlaying() && n < vl; p || i < ll; n += this.System.getPassedFrame() )
				{
					if (p)
					{
						if (this.target != null)
						{
							foreach( i, t in this.target )
							{
								local val = vols[n];
								local v = val * 0.5;
								local l;

								if (v > vlimit2[i])
								{
									l = 2;
								}
								else if (v > vlimit1[i])
								{
									l = 1;
								}
								else
								{
									l = 0;
								}

								this.owner.onFlip(t, l, val);
							}
						}
					}

					while (i < ll && n >= labels[i])
					{
						player.extractDelay(labels[i + 1]);
						i += 2;
					}

					::suspend();
				}

				this.clearTarget();
			}
			else
			{
				local vols = option.vols;
				local labels = option.labels;
				local n = 0;
				local vl = vols != null ? vols.len() : 0;
				local ll = labels != null ? labels.len() : 0;
				local i = 0;
				local p;

				for( p = this.getVoicePlaying() && n < vl; p || i < ll; n += this.System.getPassedFrame() )
				{
					if (p)
					{
						if (this.target != null)
						{
							foreach( t in this.target )
							{
								local val = vols[n];
								this.owner.onFlip(t, val, val);
							}
						}
					}

					while (i < ll && n >= labels[i])
					{
						player.extractDelay(labels[i + 1]);
						i += 2;
					}

					::suspend();
				}

				this.clearTarget();
			}
		}
		else if (option.labels != null && option.labels.len() > 0)
		{
			local labels = option.labels;
			local n = 0;
			local ll = labels != null ? labels.len() : 0;

			for( local i = 0; i < ll; n += this.System.getPassedFrame() )
			{
				while (i < ll && n >= labels[i])
				{
					player.extractDelay(labels[i + 1]);
					i += 2;
				}

				::suspend();
			}
		}
	}

}

class this.EnvVoiceBase extends this.MultiSound
{
	owner = null;
	constructor( owner, count, group )
	{
		::MultiSound.constructor(count, group, this.EnvVoice);

		if (owner != null)
		{
			this.owner = owner.weakref();
		}
	}

	function findName( name )
	{
		foreach( se in this._ses )
		{
			if (se.name == name)
			{
				return se;
			}
		}
	}

	function clearTarget()
	{
		foreach( se in this._ses )
		{
			se.clearTarget();
		}
	}

	function onStart()
	{
		if (this.owner != null)
		{
			this.owner.onVoiceStart();
		}
	}

	function onStop()
	{
		if (this.owner != null)
		{
			this.owner.onVoiceStop();
		}
	}

	function onFlip( name = null, level = null, value = 0 )
	{
		if (this.owner != null)
		{
			this.owner.onVoiceFlip(name, level, value);
		}
	}

}

class this.EnvSelectDialog extends ::SelectDialog
{
	constructor( screen, priority = 14, scale = null )
	{
		::SelectDialog.constructor(screen, priority, scale);
	}

	function hide()
	{
		this.playWait("hide");
	}

	function show()
	{
		this.playWait("show");
	}

	firstFlag = false;
	function select( list, info = null, cur = null, chara = null, storage = null, context = null )
	{
		this.firstFlag = true;
		return ::SelectDialog.select(list, info, cur, chara, storage, context);
	}

	function onMotionStop( motion )
	{
		::SelectDialog.onMotionStop(motion);

		if (motion == "show" && this.firstFlag)
		{
			this.onFirstSelectShow(this.selinfo);
			this.firstFlag = false;
		}
	}

	function checkCommand( input )
	{
		return this.checkSelectCommand();
	}

	function entryDefault( target, name, value )
	{
		if (!(name in target))
		{
			target[name] <- value;
		}
	}

	buttonInit = null;
	function createSelectButtons( init = null )
	{
		this.buttonInit = init;
		local ret = [];

		foreach( i, value in this.sellist )
		{
			local button = {};

			if (init != null)
			{
				foreach( name, value in init )
				{
					button[name] <- value;
				}
			}

			local namebase = init != null && "name" in init ? init.name : "select%d";
			button.name <- this.format(namebase, i + 1);
			button.type <- "button";
			button.result <- i;
			button.text <- [
				::parseLangText(value, "text")
			];
			this.entryDefault(button, "textshape", "text");
			this.entryDefault(button, "fontSize", this.SELECT_TEXT_FONTSIZE);
			this.entryDefault(button, "rubySize", this.SELECT_TEXT_RUBYSIZE);
			this.entryDefault(button, "shadow", this.SELECT_TEXT_SHADOW);
			this.entryDefault(button, "textDefault", this.SELECT_TEXT_DEFAULT);
			this.initDefaultColor(value, init, button);
			this.entryDefault(button, "motion", "hide");
			ret.append(button);
		}

		return ret;
	}

	function getSelReaded( value )
	{
		local readed = ::getval(value, "readed");

		if (readed == null || readed == "")
		{
			local selidx = "selidx" in value ? value.selidx : null;
			return selidx != null && this.getSelectReaded(this.curSceneId, selidx);
		}

		local storage = "storage" in value ? value.storage.tolower() : "";

		if (typeof readed == "integer" && readed != 0 || readed == "*")
		{
			if ("target" in value)
			{
				value.target;
			}
			else
			{
				local target = "";
			}

			readed = storage + target;
		}
		else if (typeof readed == "string" && readed.find("*") == 0)
		{
			readed = storage + readed;
		}

		return this.isSceneReaded(readed);
	}

	function initDefaultColor( value, init, button )
	{
		local color;
		local shadowColor;

		if (this.readedSelectColor && this.getSelReaded(value))
		{
			color = ::getval(init, "readedColor", this.SELECT_TEXT_READED_COLOR);
			shadowColor = ::getval(init, "readedShadowColor", this.SELECT_TEXT_READED_SHADOWCOLOR);
		}
		else
		{
			color = ::getval(init, "color", this.SELECT_TEXT_READED_COLOR);
			shadowColor = ::getval(init, "shadowColor", this.SELECT_TEXT_READED_SHADOWCOLOR);
		}

		button.color <- color;
		button.shadowColor <- shadowColor;
	}

	function _updateButtonColor( i, button )
	{
		local text = button.textInfo;

		if (text != null)
		{
			local value = this.sellist[button.result];
			local def = {};
			this.initDefaultColor(value, this.buttonInit, def);
			text.setTextDefault(def);
		}
	}

	function setDefaultColor()
	{
		this.foreachButton(this._updateButtonColor.bindenv(this));
	}

	function prepareTransition()
	{
		this.entryTransitionLayer(this);
	}

	function doneTransition()
	{
		this.doneTransitionLayer(this);
	}

}

class this.EnvPlayer extends ::EnvPlayerBase
{
	selectKey = this.ENTERKEY;
	cancelKey = this.KEY_CANCEL;
	scalex = 1.0;
	scaley = 1.0;
	cameraoffsetx = 0;
	cameraoffsety = 0;
	cameraoffsetz = -100;
	cameraoffsetzmax = 1000;
	camerarh = true;
	standLevels = [
		50,
		100,
		150
	];
	emote_meshdivisionratio = 1.0;
	emote_bustscale = 1.0;
	emote_hairscale = 1.0;
	emote_partsscale = 1.0;
	VOICESTOPFADE = 100;
	area = {
		width = 1920,
		height = 1080
	};
	infobase = null;
	classIdMap = null;
	env = null;
	voice = null;
	forcePlayVoice = false;
	input = null;
	addkey = 0;
	prevaddkey = 0;
	gesture = null;
	gestures = null;
	gestureth = null;
	constructor( app, envclip = true )
	{
		::EnvPlayerBase.constructor(app.getScreen(), envclip);
		this.setDelegate(app);
		this.input = this.getCurrentInput();
		this.afterQueue = [];
		this.initAction();
		this.initCopyValue();
		this.classIdMap = this.IdMap("scenario/classlist.scn");
		this.env = this.Environment(this);
		this.voice = this.EnvVoiceBase(this, 5, "voice");
		this.voiceLevels = {};
		this.initCache();

		if ("getMovePos" in ::Input)
		{
			this.initGesture();
		}
	}

	_capture = null;
	function entryCapture( capture )
	{
		this._capture = capture;
	}

	function clearCapture()
	{
		this._capture = null;
	}

	function isSelectCapture()
	{
		return this.selectPanel != null && this.selectPanel.visible && !this.canHideSelect();
	}

	function getCapturePriority()
	{
		return this.isSelectCapture() ? 21 : 10;
	}

	function getScreenCapture()
	{
		return this._capture != null ? this._capture : ::EnvPlayerBase.getScreenCapture(this.screen, this.getCapturePriority());
	}

	function onPrepareTransition( msgchange )
	{
		foreach( layer in this.env.layerList )
		{
			layer.prepareTransition();
		}
	}

	function onSetupTransition( msgchange )
	{
		this.updateSource(null, false);
	}

	function onCompleteTransition( msgchange )
	{
		if (this.env != null)
		{
			foreach( layer in this.env.layerList )
			{
				layer.doneTransition();
			}
		}
	}

	function entryAfter( obj, elm )
	{
		this.afterQueue.append([
			obj,
			elm
		]);
	}

	function updateSource( name, redraw )
	{
		foreach( lay in this.env.layerList )
		{
			lay.updateSource(name, redraw);
		}
	}

	function doAfter()
	{
		foreach( value in this.afterQueue )
		{
			if (value[0] != null)
			{
				value[0].updateAfter(value[1]);
			}
		}

		this.afterQueue.clear();
		this.updateSource(null, true);
	}

	function destructor()
	{
		this.doneGesture();
		this.infobase = null;
		this.voice = null;
		this.env = null;
		this.classIdMap = null;
		this.setEnableScreenSaver(true);
		::EnvPlayerBase.destructor();
	}

	function calcLevel( z )
	{
		local count = this.standLevels.len();

		for( local i = 0; i < count; i++ )
		{
			if (z <= this.standLevels[i])
			{
				return i;
			}
		}

		if (count > 0)
		{
			z = z - this.standLevels[count - 1];
		}
		else
		{
			z = z - 50;
		}

		return count + ::toint(z / 50);
	}

	function createMotionPanelLayer( priority )
	{
		local info = "defaultMotionInfo" in ::getroottable() ? ::defaultMotionInfo : null;
		local ret = ::MotionPanelLayer(this.getBaseScreen(), info);
		ret.setDelegate(this);
		ret.setPriority(priority);
		return ret;
	}

	function initInfoBase( storage = null )
	{
		if (this.infobase == null)
		{
			this.infobase = this.createMotionPanelLayer(20);

			if (storage != null)
			{
				this.infobase.openMotionStorage(storage);
			}
		}
	}

	function createInfoPicture( elm )
	{
		if (this.infobase != null)
		{
			return this.infobase.createPicture(elm);
		}
	}

	function createInfoText( fontSize )
	{
		if (this.infobase != null)
		{
			return this.infobase.createText(fontSize);
		}
	}

	function createInfoPanel( elm = null, storage = null, context = null )
	{
		if (this.infobase != null)
		{
			return this.infobase.createPanel(elm, storage, context);
		}
	}

	function getClassInfo( cname )
	{
		return this.classIdMap.getInfo(cname);
	}

	function updateGesture()
	{
		this.prevaddkey = this.addkey;
		this.addkey = 0;
		this.gestures.clear();
		this.input.driveTouchEvent(this.gesture);
	}

	function _gestureFunc( arg )
	{
		while (arg.player != null)
		{
			arg.player.updateGesture();
			::sync();
		}
	}

	function initGesture()
	{
		this.gesture = this.GestureInfo(this);
		this.gestures = {};
		this.gestureth = ::fork(this._gestureFunc, {
			player = this.weakref()
		});
		this.gestureth.priority = 0;
		this.printf("init gesture priority:%s %s\n", this.gestureth.priority, this.getCurrentThread().priority);
	}

	function doneGesture()
	{
		if (this.gestureth != null)
		{
			this.gestureth.exit();
			this.gestureth = null;
			this.gesture = null;
		}
	}

	function onGesture( name, param )
	{
		switch(name)
		{
		case "touchdown":
			this.addkey = this.addkey | this.ENTERKEY;
			break;

		case "touch":
			this.addkey = this.addkey & ~this.ENTERKEY;
			break;

		default:
			this.gestures[name] <- true;
			break;
		}
	}

	function checkGesture( name )
	{
		return name in this.gestures;
	}

	function checkKeyPressed( key )
	{
		return this.input.keyPressed(key) || ((this.addkey ^ this.prevaddkey) & this.addkey & key) != 0;
	}

	function checkInputFunc( func, choice = false )
	{
		return func(0, this.input);
	}

	function checkComboKeyPressed( key )
	{
		return this.input.isComboKeyPressed(key);
	}

	function checkKey( key )
	{
		return this.input.key(key) || (this.addkey & key) != 0;
	}

	function doVibrate( time )
	{
		if (this.vibration)
		{
			this.input.rumble(time);
		}
	}

	dataCache = null;
	function initCache()
	{
		this.dataCache = [];
	}

	function clearCache()
	{
		this.dataCache.clear();
	}

	function waitCache()
	{
		while (this.dataCache.len() > 0 && this.isWaitCache(this.dataCache))
		{
			this.sysSync();
		}
	}

	function addFileCache( target, base, elm )
	{
		if (base in elm)
		{
			local names = elm[base].split(",");

			foreach( n in names )
			{
				target.append(this.format("%s/%s.psb", base, n));
			}
		}
	}

	function eval( eval, error = null )
	{
		return this.exec("return " + eval);
	}

	function evalStorage( filename )
	{
		if (filename.charAt(0) == "&")
		{
			try
			{
				filename = this.eval(filename.substr(1));
			}
			catch( e )
			{
				this.printf("\x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e5\x0090\x008d\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s\n", filename, e);
			}
		}

		return filename;
	}

	function exec( script, error = null )
	{
		return ::exec(script, this, error);
	}

	copyValueTarget = null;
	function initCopyValue()
	{
		this.copyValueTarget = {};
	}

	function clearCopyValue()
	{
		this.copyValueTarget.clear();
	}

	function updateCopyValue( name, value )
	{
		if (name in this.copyValueTarget)
		{
			local list = this.copyValueTarget[name];

			for( local i = 0; i < list.len();  )
			{
				local info = list[i];

				if (info != null && info.target != null)
				{
					::setProperty(info.target, info.propName, value == null ? info.init : value);
					i++;
				}
				else
				{
					list.erase(i);
				}
			}
		}
	}

	function addCopyValue( target, propName, name, init = null )
	{
		local list;

		if (name in this.copyValueTarget)
		{
			list = this.copyValueTarget[name];
		}
		else
		{
			list = [];
			this.copyValueTarget[name] <- list;
		}

		list.append({
			target = target.weakref(),
			propName = propName,
			init = init
		});
	}

	function delCopyValue( target, propName = null )
	{
		local keys = this.copyValueTarget.keys();

		foreach( name in keys )
		{
			local list = this.copyValueTarget[name];

			for( local i = list.len() - 1; i >= 0; i-- )
			{
				local info = list[i];

				if (target == info.target && (propName == null || propName == info.propName))
				{
					if (info.init != null)
					{
						::setProperty(info.target, info.propName, info.init);
					}

					list.erase(i);
				}
			}

			if (list.len() == 0)
			{
				delete this.copyValueTarget[name];
			}
		}
	}

	function copyCopyValue( target, propName, src )
	{
		local keys = this.copyValueTarget.keys();

		foreach( name in keys )
		{
			local list = this.copyValueTarget[name];

			for( local i = list.len() - 1; i >= 0; i-- )
			{
				local info = list[i];

				if (propName == null || propName == info.propName)
				{
					if (target == info.target)
					{
						list.erase(i);
					}
					else if (src == info.target)
					{
						list.append({
							target = target.weakref(),
							propName = info.propName,
							init = info.init
						});
					}
				}
			}
		}
	}

	allActions = null;
	actionTick = 0;
	actionCompleteQueue = null;
	function initAction()
	{
		this.allActions = {};
		this.actionTick = 0;
		this.actionCompleteQueue = [];
	}

	function getActionInfo( target, create = false )
	{
		local targetName = target.tostring();

		if (targetName in this.allActions)
		{
			return this.allActions[targetName];
		}
		else if (create)
		{
			local info = ::ActionTargetInfo(target);
			this.allActions[targetName] <- info;
			return info;
		}

		return null;
	}

	function isWorkingAction( target = null )
	{
		if (target)
		{
			local info = this.getActionInfo(target);
			return info != null && info.getWorking();
		}
		else
		{
			foreach( info in this.allActions )
			{
				if (info.getWorking())
				{
					return true;
				}
			}

			return false;
		}
	}

	function isWorkingWaitAction( target = null )
	{
		if (target)
		{
			local info = this.getActionInfo(target);
			return info != null && info.getWorkingWait();
		}
		else
		{
			foreach( info in this.allActions )
			{
				if (info.getWorkingWait())
				{
					return true;
				}
			}

			return false;
		}
	}

	function hasAction( target, propName )
	{
		local action = this.getActionInfo(target);
		return action != null && action.hasAction(propName);
	}

	function delAction( target, propName )
	{
		if (target)
		{
			local info = this.getActionInfo(target);

			if (info != null)
			{
				local queue = [];
				info.delAction(propName, queue);
				this.execQueue(queue);
			}
		}
	}

	function addAction( target, propName, actionList )
	{
		if (target != null)
		{
			local act = [];

			foreach( ac in actionList )
			{
				if (this.checkAction(ac))
				{
					act.append(ac);
				}
			}

			this.getActionInfo(target, true).addAction(propName, act);
		}
	}

	function copyAction( target, propName, from )
	{
		if (target != null && from != null)
		{
			local src = this.getActionInfo(from);

			if (src != null)
			{
				local queue = [];
				local dest = this.getActionInfo(target, true);
				dest.copyAction(propName, src, queue);
				this.execQueue(queue);
			}
		}
	}

	function setActionComplete( target, propName, complete, after = null )
	{
		if (target != null)
		{
			local action = this.getActionInfo(target);

			if (action != null)
			{
				action.setComplete(propName, complete, after);
			}
		}
	}

	function assignAction( src, dest )
	{
		this.stopAction(dest, true);
		local targetName = src.tostring();

		if (targetName in this.allActions)
		{
			local srcAction = this.allActions[targetName];
			local destAction = srcAction.cloneObj(dest);
			this.allActions[dest.tostring()] <- destAction;
		}
	}

	function getActionFlag( action, name, defvalue = null )
	{
		if (typeof action == "table")
		{
			return ::getval(action, name, defvalue);
		}
		else if (typeof action == "array")
		{
			return ::getval(action[action.len() - 1], name, defvalue);
		}
	}

	function checkAction( action )
	{
		return action != null;
	}

	function beginAction( target, action, complete = null, nowait = false )
	{
		if (target != null && this.checkAction(action))
		{
			this.getActionInfo(target, true).beginAction(action, complete, nowait, this.actionCompleteQueue);
		}
	}

	function execQueue( queue )
	{
		foreach( func in queue )
		{
			func();
		}

		queue.clear();
	}

	function removeAction( target, all = false )
	{
		if (target)
		{
			local targetName = target.tostring();

			if (targetName in this.allActions)
			{
				delete this.allActions[targetName];
			}
		}
	}

	function stopAction( target, all = false )
	{
		if (target)
		{
			local targetName = target.tostring();

			if (targetName in this.allActions)
			{
				local info = this.allActions[targetName];
				local queue = [];
				info.stopAction(all, queue);
				this.execQueue(queue);
			}
		}
	}

	function stopAllActions( all = false )
	{
		local queue = [];

		foreach( info in this.allActions )
		{
			info.stopAction(all, queue);
		}

		this.execQueue(queue);
	}

	function setProperty( target, name, value, time = 0, accel = 0 )
	{
		if (name == "xpos" || name == "ypos")
		{
			if ("res_align" in target)
			{
				value = target.res_align(value);
			}
		}

		this.delAction(target, name);
		::setProperty(target, name, value, time, accel);
	}

	function waitPropAction( target, propName, canSkip = true, timeout = null )
	{
		if (target == null)
		{
			return 0;
		}

		return this.waitFunction(canSkip, function () : ( target, propName )
		{
			return this.hasAction(target, propName);
		}.bindenv(this), function () : ( target, propName )
		{
			this.delAction(target, propName);
		}.bindenv(this), timeout);
	}

	function waitAction( target, canSkip = true, timeout = null )
	{
		if (target == null)
		{
			return 0;
		}

		return this.waitFunction(canSkip, function () : ( target )
		{
			return this.isWorkingWaitAction(target);
		}.bindenv(this), function () : ( target )
		{
			this.stopAction(target);
		}.bindenv(this), timeout);
	}

	function waitAllAction( canSkip = true, timeout = null )
	{
		return this.waitFunction(canSkip, this.isWorkingWaitAction.bindenv(this), this.stopAllActions.bindenv(this), timeout);
	}

	function updateActions( diff )
	{
		this.actionTick += diff;

		if (this.allActions.len() > 0)
		{
			local names = this.allActions.keys();

			foreach( name in names )
			{
				local info = this.allActions[name];

				if (info.target == null || info.doAction(this.actionTick, this.actionCompleteQueue))
				{
					delete this.allActions[name];
				}
			}

			this.execQueue(this.actionCompleteQueue);
		}
	}

	function updateCamera()
	{
		this.env.updateCamera();
	}

	function updateWind()
	{
		this.env.updateWind();
	}

	afterQueue = null;
	function loadData( name )
	{
		name = name.tolower();
		local rsc = ::Resource();
		rsc.load(name);

		while (rsc.loading)
		{
			this.suspend();
		}

		local result = rsc.find(name);

		if (result == null)
		{
			this.printf("%s:\x00e3\x0083\x0095\x00e3\x0082\x00a1\x00e3\x0082\x00a4\x00e3\x0083\x00ab\x00e3\x0082\x00aa\x00e3\x0083\x00bc\x00e3\x0083\x0097\x00e3\x0083\x00b3\x00e5\x00a4\x00b1\x00e6\x0095\x0097\n", name);
		}

		return result;
	}

	function calcActionSpeed( option = null )
	{
		return 1.0;
	}

	function beginEnvTrans( msgchange )
	{
		this.setupTransition(msgchange);
	}

	function doEnvTrans( elm )
	{
		this.doAfter();

		if (typeof elm == "table" && ("method" in elm) && ::getint(elm, "time", 0) > 0)
		{
			this.startTransition(elm, null, "env");
		}
		else
		{
			this.stopTransition();
		}
	}

	timeOrigin = null;
	function resetWait()
	{
		this.timeOrigin = this.getCurrentTick();
	}

	function waitTime( time, canSkip = true )
	{
		if (time == null)
		{
			time = 0;
		}

		time *= this.actSkipSpeed;

		if (time > 0)
		{
			return this.waitFunction(canSkip, null, null, time);
		}

		return 0;
	}

	function waitNameVoice( name, canSkip = true )
	{
		local v = this.voice.findName(name);

		if (v != null)
		{
			return this.waitFunction(canSkip, v.getPlaying.bindenv(v));
		}

		return 0;
	}

	function waitAllVoice( canSkip = true )
	{
		return this.waitFunction(canSkip, this.voice.getAllPlaying.bindenv(this.voice));
	}

	function waitVoice( elm = null )
	{
		local ret;
		local canskip = ::getval(elm, "canskip", true);

		if ("name" in elm)
		{
			ret = this.waitNameVoice(elm.name, canskip);
		}
		else
		{
			ret = this.waitAllVoice(canskip);
		}

		if (ret == 0)
		{
			this.waitTime(::getval(elm, "wait", 0), canskip);
		}
		else
		{
			this.tag_stopvoice(elm);
		}
	}

	function waitLayerMotion( target, canSkip = true )
	{
		return this.waitFunction(canSkip, target.isPlayingMotion.bindenv(target));
	}

	bgmVolume = 1.0;
	voiceBgmVolume = null;
	seVolume = 1.0;
	voiceSeVolume = null;
	vibration = false;
	function updateConfig()
	{
		this.vibration = this.getConfig("vibration", 0) != 0;
		this.bgmVolume = this.getConfig("bgmVolume", 1.0);
		this.voiceBgmVolume = this.getConfig("bgmDown", false) ? this.getConfig("bgmVolume", 1.0) * this.getConfig("bgmDownLevel", 1.0) : null;
		this.seVolume = this.getConfig("seVolume", 1.0);
		this.voiceSeVolume = this.getConfig("seDown", false) ? this.getConfig("seVolume", 1.0) * this.getConfig("seDownLevel", 1.0) : null;
		this.emote_meshdivisionratio = this.getConfig("EmoteMeshDivisionRatio", 1.0);
		this.emote_bustscale = this.getConfig("EmoteBustScale", 1.0);
		this.emote_hairscale = this.getConfig("EmoteHairScale", 1.0);
		this.emote_partsscale = this.getConfig("EmotePartsScale", 1.0);
	}

	function clearScene()
	{
		this.stopQuake();
		this.setAfterImage();
		this.timeOrigin = null;
	}

	function envInit()
	{
		this.clearScene();
		this.clearCache();
		this.clearCopyValue();
	}

	function clearEnv( fade = 0 )
	{
		this.envInit();
		this.env.envInit();
		this.voice.stop(fade);
	}

	function playVoice( voices, scene = false )
	{
		local len = 0;

		if (voices != null)
		{
			this.voice.stop(this.VOICESTOPFADE);
			local vcount = 0;

			foreach( v in voices )
			{
				if (!(scene && ::getbool(v, "noplay")) && v.voice != null && (this.forcePlayVoice || this.getVoiceOn(v.name)))
				{
					vcount++;
				}
			}

			foreach( v in voices )
			{
				if (!(scene && ::getbool(v, "noplay")) && v.voice != null)
				{
					if (this.forcePlayVoice || this.getVoiceOn(v.name))
					{
						local volume = this.getVoiceVolume(v.name) * 100;
						this.onPlayVoice(v);

						if (scene)
						{
							local target;

							if (this.VOICE_TARGET_SPLIT != null && v.name.find(this.VOICE_TARGET_SPLIT) != null)
							{
								target = v.name.split(this.VOICE_TARGET_SPLIT);
							}
							else
							{
								target = [
									v.name
								];
							}

							this.voice.play(v.voice, volume, null, 0, {
								player = this.weakref(),
								target = target,
								vols = this.getval(v, "vols"),
								labels = this.getval(v, "labels")
							});
						}
						else
						{
							this.voice.play(v.voice, volume);
						}

						if (("time" in v) && v.time > len)
						{
							len = v.time;
						}
					}
					else if (("labels" in v) && v.labels.len() > 0)
					{
						this.entryDelayLabels(v.labels);
					}
				}
			}
		}

		return len;
	}

	function stopVoiceTarget()
	{
		this.voice.clearTarget();
	}

	function stopAllVoice()
	{
		local time = this.isSkip() ? 0 : this.VOICESTOPFADE;
		this.voice.stop(time);
	}

	function stopVoice( name = null, time = null )
	{
		if (time == null)
		{
			time = this.VOICESTOPFADE;
		}

		if (name != null)
		{
			local v = this.voice.findName(name);

			if (v != null)
			{
				v.stop(time);
			}
		}
		else
		{
			this.voice.stop(time);
		}
	}

	bgmvoldown = false;
	sevoldown = false;
	function onVoiceStart()
	{
		if (this.voiceBgmVolume != null)
		{
			::setBgmVolume(this.voiceBgmVolume);
			this.bgmvoldown = true;
		}

		if (this.voiceSeVolume != null)
		{
			::Sound.setGroupVolume("se", this.voiceSeVolume);
			this.sevoldown = true;
		}
	}

	function onVoiceStop()
	{
		if (this.bgmvoldown)
		{
			::setBgmVolume(this.bgmVolume);
			this.bgmvoldown = false;
		}

		if (this.sevoldown)
		{
			::Sound.setGroupVolume("se", this.seVolume);
			this.sevoldown = false;
		}
	}

	voiceLevels = null;
	autoVoiceFlip = false;
	function onVoiceFlip( name = null, level = null, value = 0 )
	{
		if (this.autoVoiceFlip)
		{
			this.env.onVoiceFlip(name, level, value);
		}
		else if (name != null)
		{
			if (level == null)
			{
				if (name in this.voiceLevels)
				{
					delete this.voiceLevels[name];
				}

				this.updateCopyValue("lip" + name, null);
			}
			else
			{
				this.voiceLevels[name] <- level;
				this.updateCopyValue("lip" + name, level);
			}
		}
		else
		{
			foreach( n, v in this.voiceLevels )
			{
				this.updateCopyValue("lip" + n, null);
			}

			this.voiceLevels.clear();
		}
	}

	function copyValue( name, type )
	{
		if (name != "" && type == "lip")
		{
			return this.getval(this.voiceLevels, name, null);
		}
	}

	quakeFunc = null;
	quakeTime = 0;
	qx = 0;
	qy = 0;
	function setQuake( x, y )
	{
		this.qx = x;
		this.qy = y;
		this.updateCamera();
		this.updateMsgOffset();
		this.base.setOffset(-x * this.envscale, -y * this.envscale);

		if (this.transbase != null)
		{
			this.transbase.setOffset(-x * this.envscale, -y * this.envscale);
		}
	}

	function stopQuake()
	{
		if (this.quakeFunc != null)
		{
			this.quakeFunc.exit();
			this.quakeFunc = null;
		}

		this.setQuake(0, 0);
	}

	function startQuake( elm )
	{
		if (!this.quakeEnable)
		{
			return;
		}

		local hmax = this.getint(elm, "hmax", 10);
		local vmax = this.getint(elm, "vmax", 10);
		local time = "time" in elm ? this.getint(elm, "time", 0) * 60 / 1000 * this.effectSpeed : null;
		this.quakeTime = time;
		this.quakeFunc = ::fork(function ( hmax, vmax, time, info )
		{
			local quakePhase = 0;

			while (time == null || time > 0)
			{
				local x;
				local y;

				if (hmax == vmax)
				{
					x = ::random(hmax * 2) - hmax;
					y = ::random(vmax * 2) - vmax;
				}
				else if (hmax < vmax)
				{
					x = ::random(hmax * 2) - hmax;
					y = quakePhase ? ::random(vmax) : -::random(vmax);
				}
				else
				{
					x = quakePhase ? ::random(hmax) : -::random(hmax);
					y = ::random(vmax * 2) - vmax;
				}

				quakePhase = !quakePhase;

				if (info.player != null)
				{
					info.player.setQuake(x, y);
				}

				::wait(3);

				if (time != null)
				{
					time -= 3;
				}
			}

			if (info.player != null)
			{
				info.player.setQuake(0, 0);
			}
		}, hmax, vmax, time, {
			player = this.weakref()
		});

		if (time != null && time > 0)
		{
			this.doVibrate(time);
		}
	}

	function waitQuake( canSkip = true )
	{
		if (this.quakeFunc != null && (canSkip || this.quakeTime != null && this.quakeTime > 0))
		{
			this.printf("quake status:%s\n", this.quakeFunc.status);
			return this.waitFunction(canSkip, function () : ( quakeFunc )
			{
				return quakeFunc.status != 0;
			}, this.stopQuake.bindenv(this));
		}

		return 0;
	}

	function _interrupt()
	{
		this.clearEnv(this.VOICESTOPFADE);
	}

	function interrupt( exception, fadeout = true )
	{
		if (exception)
		{
			local back = ::BackLayer(this.getBaseScreen(), 4278190080, 99999999 + 100);

			if (fadeout)
			{
				for( local i = 0; i <= 30; i++ )
				{
					back.setOpacity(255 * i / 30);
					::suspend();
				}
			}

			this._interrupt();
			throw exception;
		}
	}

	function exitGame( type = "exit", option = null )
	{
		this.interrupt(this.GameStateException(type, option));
	}

	function checkSkipStop()
	{
		return false;
	}

	function checkSkip()
	{
		if (this.checkSkipStop())
		{
			return true;
		}

		return false;
	}

	function checkCommand()
	{
		return false;
	}

	function checkClick( force = false )
	{
		return this.checkKeyPressed(this.selectKey) || this.checkKeyPressed(this.cancelKey);
	}

	mainTick = 0;
	function getCurrentTick()
	{
		return this.mainTick;
	}

	function calcActionTick( diff )
	{
		return diff;
	}

	function isUpdateOnExternalUI()
	{
		return false;
	}

	function sync()
	{
		if (this.isUpdateOnExternalUI())
		{
			this.updateSync();
		}
		else
		{
			::sync();
		}
	}

	function suspend()
	{
		local diff = ::getDiffTick() * 1000 / 60;
		this.mainTick += diff;
		this.updateActions(this.calcActionTick(diff));
		::suspend();
		this.checkSkipStop();
	}

	function updateSync()
	{
		local diff = ::getDiffTick() * 1000 / 60;
		this.mainTick += diff;
		local adiff = this.calcActionTick(diff);
		this.updateActions(adiff);
		this.updateTransition(adiff);
		this.updateAfterImage();
		::sync();
	}

	function sysSync()
	{
		this.updateSync();
		this.checkSkipStop();
	}

	function playSync()
	{
		this.updateSync();
	}

	function waitSync()
	{
		this.playSync();
		return !this.checkSkip() && this.checkClick();
	}

	function workSync( force = false )
	{
		this.playSync();
		return !this.checkSkip() && !this.checkCommand() && this.checkClick(force);
	}

	workStopFunc = null;
	workCommandExecuted = false;
	function onExecuteCommand()
	{
		if (this.workStopFunc != null)
		{
			this.workStopFunc();
			this.workStopFunc = null;
		}

		this.workCommandExecuted = true;
	}

	function waitFunction( canSkip = true, checkfunc = null, stopfunc = null, timeout = null )
	{
		if (timeout != null)
		{
			timeout = this.getCurrentTick() + timeout;
		}

		this.workCommandExecuted = false;
		this.workStopFunc = stopfunc;

		while (checkfunc == null || checkfunc())
		{
			if (timeout != null)
			{
				if (timeout - this.getCurrentTick() <= 0)
				{
					this.onExecuteCommand();
					return 2;
				}
			}

			if (canSkip)
			{
				this.playSync();

				if (!this.checkSkip())
				{
					if (this.checkCommand())
					{
						if (this.workCommandExecuted)
						{
							return 1;
						}
					}
					else if (this.checkClick())
					{
						this.onExecuteCommand();
						return 1;
					}
				}
			}
			else
			{
				this.playSync();
				this.checkSkip();
			}
		}

		return 0;
	}

	function waitClick( canSkip = true )
	{
		return this.waitFunction(canSkip);
	}

	function onPlayVoice( v )
	{
	}

	function onLayerUpdateImage( layer )
	{
	}

	function convImageFile( storage )
	{
		return storage;
	}

	function main( scene )
	{
		return 0;
	}

}

class this.ScenePlayer extends ::EnvPlayer
{
	MSGWIN_TYPES = [
		"MSGWIN",
		"NOVEL",
		"CENTER"
	];
	MSGFADETIME = 500;
	DEFAULT_CANCEL_SKIP_FLAG = 2;
	DEFAULT_CANCEL_AUTO_FLAG = 0;
	CONFIRM_QSAVE = true;
	SELECT_TEXT_FONTSIZE = 16;
	SELECT_TEXT_RUBYSIZE = 8;
	SELECT_TEXT_SHADOW = false;
	SELECT_TEXT_DEFAULT = {
		align = 0,
		valign = 0
	};
	SELECT_TEXT_COLOR = 4294967295;
	SELECT_TEXT_SHADOWCOLOR = 4278190080;
	SELECT_TEXT_READED_COLOR = 4294936712;
	SELECT_TEXT_READED_SHADOWCOLOR = 4278190080;
	SELECT_HISTORY_PREFIX = "\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e8\x0082\x00a2:";
	SELECT_HISTORY_WORKING = "\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e4\x00b8\x00ad";
	DONT_REMOVE_SELECT = false;
	PREV_TO_START = true;
	SWITCH_AUTO_SKIP = false;
	INVOLVE_AUTOSAVE_MODE = true;
	VOICE_TARGET_SPLIT = null;
	PLAY_MOVIE_ON_SKIP = true;
	NOSCREENSAVER_ALWAYS = false;
	cmdpanel = null;
	flags = null;
	tflags = null;
	f = null;
	tf = null;
	sceneMode = 0;
	playScenes = null;
	drawSpeed = 1.0;
	skipSpeed = 0.0;
	actSkipSpeed = 1.0;
	effectSpeed = 1.0;
	effectSpeedMag = 1.0;
	skipToPage = false;
	hideKey = this.KEY_CANCEL;
	autoKey = 4;
	autoFuncKey = null;
	skipKey = 8;
	autoCancelKey = null;
	skipCancelKey = null;
	forceUnreadSkipKey = 256;
	forceSkipKey = null;
	FORCESKIP_DELAY = 0;
	longAutoKey = this.ENTERKEY;
	autoStartTick = null;
	LONGAUTO_DELAY = 30;
	hideCancelCheckSkip = 0;
	playCommands = null;
	selectCommands = null;
	hideCommands = null;
	innerMsgwin = false;
	recordEnable = true;
	function openSave()
	{
		this.dummyDialog("SAVE panel not implement");
	}

	function openHistory()
	{
		this.dummyDialog("HISTORY panel not implement");
	}

	function openSysMenu( arg = null )
	{
		this.dummyDialog("SYSMENU panel not implement");
	}

	function getMsgOwner()
	{
		return this.innerMsgwin ? this.getScreen() : this.getBaseScreen();
	}

	function getMsgPriority()
	{
		return this.innerMsgwin ? 1000000 : 12;
	}

	function getMsgScale()
	{
		return this.innerMsgwin ? 1 / this.envscale : 1.0;
	}

	constructor( app, innerMsgwin = false, envclip = true )
	{
		::EnvPlayer.constructor(app, envclip);
		this.innerMsgwin = innerMsgwin;
		this.initMsg();

		if (this.skipCancelKey == null)
		{
			this.skipCancelKey = this.skipKey | this.cancelKey;
		}

		if (this.autoCancelKey == null)
		{
			this.autoCancelKey = this.autoKey | this.cancelKey;
		}

		this.flags = {};
		this.tflags = {};
		this.f = this.GetSet(this.getFlag.bindenv(this), this.setFlag.bindenv(this));
		this.tf = this.GetSet(this.getTFlag.bindenv(this), this.setTFlag.bindenv(this));
		this.initHistory(app.getHistoryMax());
		this.initDelay();
	}

	function onPrepareTransition( msgchange )
	{
		::EnvPlayer.onPrepareTransition(msgchange);

		if (this.selectPanel != null)
		{
			this.selectPanel.prepareTransition();
		}

		this.msg.onPrepareTransition(msgchange);

		if (this.submsg)
		{
			this.submsg.onPrepareTransition(msgchange);
		}
	}

	function onSetupTransition( msgchange )
	{
		::EnvPlayer.onSetupTransition(msgchange);
		this.msg.onSetupTransition(msgchange);

		if (this.submsg)
		{
			this.submsg.onSetupTransition(msgchange);
		}

		if (msgchange != null)
		{
			this.msgWinState = msgchange;
		}
	}

	function onCompleteTransition( msgchange )
	{
		::EnvPlayer.onCompleteTransition(msgchange);

		if (this.selectPanel)
		{
			this.selectPanel.doneTransition();
		}

		if (this.msg)
		{
			this.msg.doneTransition(msgchange);
		}

		if (this.submsg)
		{
			this.submsg.doneTransition(msgchange);
		}
	}

	function destructor()
	{
		this.clear();
		this.cmdpanel = null;
		this.selectPanel = null;
		this.doneMsg();
		this.doneSubMsg();
		::EnvPlayer.destructor();
	}

	function getDebugInfo()
	{
		return "";
	}

	function isUpdateOnExternalUI()
	{
		return this.selectUpdateFlag;
	}

	function openCommandPanel( storage, chara, context = null )
	{
		if (this.cmdpanel == null)
		{
			this.cmdpanel = this.createMotionPanelLayer(23);
		}

		local e = typeof chara == "string" ? {
			chara = chara,
			focus = 0
		} : chara;
		local ret;

		try
		{
			ret = this.cmdpanel.open(e, storage, context);
		}
		catch( e )
		{
			if (e instanceof this.GameStateException)
			{
				this.onOpenCommandException();
				throw e;
			}

			this.printf("failed to open command:%s:%s\n", storage, chara);
			::printException(e);
		}

		return ret;
	}

	function onOpenCommandException()
	{
	}

	function tag_begincache( elm )
	{
		this.printf("cache image:%s\n", this.getval(elm, "image"));
		this.printf("cache sound:%s\n", this.getval(elm, "sound"));
		this.printf("cache voice:%s\n", this.getval(elm, "voice"));
		local target = [];
		this.addFileCache(target, "image", elm);

		if (target.len() > 0)
		{
			this.addCache(this.dataCache, target);
		}

		target.clear();
		this.addFileCache(target, "sound", elm);
		this.addFileCache(target, "voice", elm);

		if (target.len() > 0)
		{
			this.addCacheRaw(this.dataCache, target);
		}

		this.waitCache();
	}

	function tag_endcache( elm )
	{
		this.clearCache();
	}

	function getFlag( name )
	{
		local value = this.getval(this.flags, name);

		if (value == null)
		{
			value = 0;
		}

		return value;
	}

	function setFlag( name, value )
	{
		if (typeof value == "bool")
		{
			this.flags[name] <- value ? 1 : 0;
		}
		else
		{
			this.flags[name] <- value;
		}
	}

	function getTFlag( name )
	{
		return this.getval(this.tflags, name);
	}

	function setTFlag( name, value )
	{
		this.tflags[name] <- value;
	}

	msgclass = ::EnvMessage;
	msg = null;
	msgWinState = false;
	msgMode = false;
	msgType = 0;
	msgoffx = 0;
	msgoffy = 0;
	msglayoffx = 0;
	msglayoffy = 0;
	submsgclass = ::EnvMessage;
	submsg = null;
	suboffx = 0;
	suboffy = 0;
	languageId = 0;
	subLanguageId = 0;
	function setLanguage( id, wordBreak = true, widthTimeScale = false )
	{
		this.languageId = id;
		this.msg.setOption("word_break", wordBreak);
		this.msg.setOption("width_time_scale", widthTimeScale);
		this.msg.languageId = id;
	}

	function setSubLanguage( id, wordBreak = true, widthTimeScale = false )
	{
		this.subLanguageId = id;

		if (this.submsg)
		{
			this.submsg.setOption("word_break", wordBreak);
			this.submsg.setOption("width_time_scale", widthTimeScale);
			this.submsg.languageId = id;
		}
	}

	function setMsgTimeScale( scale )
	{
		this.msg.setTimeScale(scale);
	}

	function setSubMsgTimeScale( scale )
	{
		if (this.submsg)
		{
			this.submsg.setTimeScale(scale);
		}
	}

	function initMsg()
	{
		this.msg = this.msgclass(this.getMsgOwner(), this.getMsgPriority(), this.getMsgScale());
		this.msg.setDelegate(this);
		this.msg.openMotion("motion/main.psb");
		this.setMsgType();
		this.msg.visible = true;
		this.msg.languageId = this.languageId;
	}

	function initSubMsg( type, offx = 0, offy = 0 )
	{
		this.submsg = this.submsgclass(this.getMsgOwner(), this.getMsgPriority(), this.getMsgScale());
		this.submsg.setDelegate(this);
		this.submsg.openMotion("motion/main.psb");
		this.submsg.visible = true;
		this.submsg.setType(type);
		this.submsg.languageId = this.subLanguageId;
		this.suboffx = offx;
		this.suboffy = offy;
	}

	function updateMsgOffset()
	{
		if (this.msg != null)
		{
			this.msg.setOffset(this.msgoffx + this.qx, this.msgoffy + this.qy);
		}

		if (this.submsg != null)
		{
			this.submsg.setOffset(this.suboffx + this.msgoffx + this.qx, this.suboffy + this.msgoffy + this.qy);
		}
	}

	function doneMsg()
	{
		this.msg = null;
	}

	function doneSubMsg()
	{
		this.submsg = null;
	}

	function setMsgType( type = 0 )
	{
		type = ::toint(type, type);

		if (typeof type == "integer")
		{
			if (type < 0 || type >= this.MSGWIN_TYPES.len())
			{
				type = 0;
			}

			type = this.MSGWIN_TYPES[type];
		}

		this.msgType = type;

		if (this.msg != null)
		{
			this.msg.setType(type);
		}

		this.setMsgVisible(this.msgWinState);
	}

	function setMsgOffset( offx = 0, offy = 0 )
	{
		if (this.msgoffx != offx || this.msgoffy != this.msgoffy)
		{
			this.msgoffx = offx;
			this.msgoffy = offy;
			this.updateMsgOffset();
		}
	}

	function setMsgLayOffset( offx = 0, offy = 0 )
	{
		if (this.msglayoffx != offx || this.msglayoffy != offy)
		{
			this.msglayoffx = offx;
			this.msglayoffy = offy;
			this.updateCamera();
		}
	}

	function setMsgVisible( visible )
	{
		this.env.setMsgVisible(visible);
	}

	function doHideFace( force = false )
	{
		if (force || !this.msgWinState)
		{
			this.setMsgVisible(false);
		}
	}

	function doShowFace()
	{
		if (this.msgWinState)
		{
			this.setMsgVisible(true);
		}
	}

	function updateMsg()
	{
		this.msg.updateMsg();

		if (this.submsg)
		{
			this.submsg.updateMsg();
		}
	}

	function msgon( time = 0 )
	{
		if (this.submsg)
		{
			if (time > 0)
			{
				this.msg.msgon(time, false);
				this.submsg.msgon(time, false);
				::waitMultiMotion([
					this.msg,
					this.submsg
				], this.sync.bindenv(this));
			}
			else
			{
				this.msg.msgon();
				this.submsg.msgon();
			}
		}
		else
		{
			this.msg.msgon(time);
		}
	}

	function msgoff( time )
	{
		if (this.submsg)
		{
			if (time > 0)
			{
				this.msg.msgoff(time, false);
				this.submsg.msgoff(time, false);
				::waitMultiMotion([
					this.msg,
					this.submsg
				], this.sync.bindenv(this));
				this.msg.visible = false;
				this.submsg.visible = false;
			}
			else
			{
				this.msg.msgoff();
				this.submsg.msgoff();
			}
		}
		else
		{
			this.msg.msgoff(time);
		}
	}

	function msgWait( mode )
	{
		this.msg.setWait(mode, this.curReaded);
	}

	function enterMsgMode( hideSelect = true )
	{
		if (!this.msgMode)
		{
			this.msgMode = true;
			this.onMsgMode(this.msgMode);
			this.checkPlayMode();
			this.doHideFace(true);
			this.env.pauseMotion(true);

			if (this.msgWinState)
			{
				this.msgoff(this.MSGFADETIME);
			}

			if (hideSelect && this.canHideSelect())
			{
				this.selectPanel.hide();
			}
		}
	}

	function cancelMsgMode()
	{
		if (this.msgMode)
		{
			if (this.canHideSelect())
			{
				this.selectPanel.show();
			}

			if (this.msgWinState)
			{
				this.msgon(this.MSGFADETIME);
			}

			this.env.pauseMotion(false);
			this.doShowFace();
			this.msgMode = false;
			this.onMsgMode(this.msgMode);
			this.checkPlayMode();
		}
	}

	clickSkipEnabled = true;
	commandEnabled = true;
	playStatus = 0;
	forceSkip = 0;
	autoMode = false;
	skipMode = 0;
	enableLeftBeginSkip = true;
	textSkipMode = 0;
	playMode = 0;
	function cancelPlayMode( cancelFlag, user = false )
	{
		local update = false;

		if (this.playStatus == 2 && this.cancelSkipFlag & cancelFlag)
		{
			this.playStatus = this.autoMode ? 1 : 0;
			update = true;
		}

		if (this.playStatus == 1 && this.cancelAutoFlag & cancelFlag)
		{
			this.autoMode = false;
			this.playStatus = 0;
			update = true;
		}

		if (update)
		{
			this.checkPlayMode(user);
		}
	}

	function isSystemPlayModeDisable()
	{
		return this.msgMode || this.curSceneSelect;
	}

	function checkPlayMode( user = false, force = true )
	{
		local playMode = 0;

		if (!this.isSystemPlayModeDisable())
		{
			if (this.forceSkip == 2 || this.playStatus == 2 && this.allSkip)
			{
				playMode = 3;
			}
			else if (this.forceSkip == 1 || this.playStatus == 2)
			{
				playMode = 2;
			}
			else if (this.playStatus == 1)
			{
				playMode = 1;
			}
		}

		if (this.playMode != playMode || force)
		{
			if (this.playMode == 3 || this.playMode == 2)
			{
				if (this.msg)
				{
					this.msg.doClear();
				}

				if (this.submsg)
				{
					this.submsg.doClear();
				}
			}

			local prevPlayMode = this.playMode;
			this.playMode = playMode;
			this.onPlayMode(playMode, prevPlayMode, user);
			local disableSaver = (this.NOSCREENSAVER_ALWAYS || this.playStatus > 0) && this.screenSaver == 0;
			this.setEnableScreenSaver(!disableSaver);
		}

		this.updateSpeed();
	}

	function canSkip()
	{
		return this.curReaded || this.allSkip;
	}

	function canPrevToStart()
	{
		return this.PREV_TO_START && this.isNormalPlay() && this.sceneStart != null && this.sceneStart != "";
	}

	function canPrevJump()
	{
		for( local i = this.histories.len() - 1; i >= 0; i-- )
		{
			if (this.histories[i][5])
			{
				return true;
			}
		}

		return this.canPrevToStart();
	}

	function canJump()
	{
		return this.canSkip() && !this.curSceneSelect;
	}

	function isSystemSkipDisable()
	{
		return this.msgMode || this.curSceneSelect;
	}

	function isSkip()
	{
		return !this.isSystemSkipDisable() && (this.skipMode == 2 || this.forceSkip == 2 || this.forceSkip == 1 && this.curReaded || this.clickSkipEnabled && this.playStatus == 2 && this.canSkip());
	}

	function isAuto()
	{
		return !this.isSkip() && this.playStatus == 1;
	}

	autoSaveMode = 0;
	chStep = 0;
	autoWait = 0;
	allSkip = false;
	voiceSync = false;
	voiceCut = false;
	voiceWaitMode = 0;
	quakeEnable = true;
	cancelSkipFlag = 0;
	cancelAutoFlag = 0;
	screenSaver = 0;
	readedTextColor = false;
	readedSelectColor = false;
	function updateConfig()
	{
		::EnvPlayer.updateConfig();
		this.chStep = (1.0 - this.getConfig("textSpeed", 1.0)) * 50.0;
		this.autoWait = (1.0 - this.getConfig("autoSpeed", 1.0)) * 2000.0;
		this.voiceSync = this.getConfig("voiceSync", 0) != 0;
		this.voiceCut = this.getConfig("voiceCut", 0) != 0;
		this.voiceWaitMode = this.getConfig("voiceWaitMode", 0);
		this.printf("voiceWaitMode:%s\n", this.voiceWaitMode);
		this.allSkip = this.getConfig("skipMode", 0) != 0;
		this.cancelAutoFlag = this.DEFAULT_CANCEL_AUTO_FLAG;

		if (this.getConfig("autoStopSel"))
		{
			this.cancelAutoFlag = this.cancelAutoFlag | 4;
		}

		this.cancelSkipFlag = this.DEFAULT_CANCEL_SKIP_FLAG;

		if (this.getConfig("skipStopSel"))
		{
			this.cancelSkipFlag = this.cancelSkipFlag | 4;
		}

		if (this.getConfig("skipStopEve"))
		{
			this.cancelSkipFlag = this.cancelSkipFlag | 8;
		}

		if (this.getConfig("skipStopMov"))
		{
			this.cancelSkipFlag = this.cancelSkipFlag | 16;
		}

		if (this.getConfig("skipStopEye"))
		{
			this.cancelSkipFlag = this.cancelSkipFlag | 32;
		}

		if (this.getConfig("skipStopScn"))
		{
			this.cancelSkipFlag = this.cancelSkipFlag | 64;
		}

		this.drawSpeed = this.getConfig("drawSpeed", 1.0);
		this.skipSpeed = this.getConfig("skipSpeed", 0.0);

		if (!this.canAutoSave())
		{
			this.autoSaveMode = 0;
		}
		else if (this.INVOLVE_AUTOSAVE_MODE)
		{
			switch(this.getConfig("autoSaveMode", -1))
			{
			case 0:
				this.autoSaveMode = 0;
				break;

			case 1:
				this.autoSaveMode = 1;
				break;

			case 2:
				this.autoSaveMode = 1 | 2;
				break;

			case 3:
				this.autoSaveMode = 1 | 2 | 4;
				break;

			default:
				this.autoSaveMode = 0;

				if (this.getConfig("autoSaveSelect"))
				{
					this.autoSaveMode = this.autoSaveMode | 1;
				}

				if (this.getConfig("autoSaveScene"))
				{
					this.autoSaveMode = this.autoSaveMode | 2;
				}

				if (this.getConfig("autoSaveEvent"))
				{
					this.autoSaveMode = this.autoSaveMode | 4;
				}
			}
		}
		else
		{
			switch(this.getConfig("autoSaveMode", 0))
			{
			case 1:
				this.autoSaveMode = 1;
				break;

			case 2:
				this.autoSaveMode = 2;
				break;

			case 3:
				this.autoSaveMode = 4;
				break;

			default:
				this.autoSaveMode = 0;
				break;
			}
		}

		this.screenSaver = this.getConfig("screenSaver", 0);
		this.readedTextColor = this.getConfig("readedTextColor");
		this.readedSelectColor = this.getConfig("readedSelectColor");
		this.onUpdateConfig();
		this.actSkipSpeed = -1;
		this.updateSpeed();
		this.checkPlayMode(false, true);
		this.env.updateImage();

		if (this.selectPanel != null)
		{
			this.selectPanel.setDefaultColor();
			this.selectPanel.redraw();
		}

		this.setMsgDefaultColor();
		this.msg.updateTransparency();
		this.msg.redraw();

		if (this.submsg)
		{
			this.submsg.updateTransparency();
			this.submsg.redraw();
		}
	}

	function setMsgDefaultColor()
	{
		local colchange = this.readedTextColor && this.curReaded;
		this.msg.setDefaultColor(colchange);

		if (this.submsg)
		{
			this.submsg.setDefaultColor(colchange);
		}
	}

	function updateSpeed()
	{
		local _actSkipSpeed = this.isSkip() ? this.skipSpeed : 1.0;

		if (this.actSkipSpeed != _actSkipSpeed)
		{
			this.actSkipSpeed = _actSkipSpeed;
			this.effectSpeed = this.drawSpeed * this.actSkipSpeed;
			this.effectSpeedMag = this.effectSpeed < 0.0099999998 ? 100 : 1.0 / this.effectSpeed;
			this.env.updateSpeed();
		}
	}

	function execAutoSave()
	{
		if (this.isNormalPlay())
		{
			this.onAutoSave(true);

			try
			{
				this.doAutoSave(null, this.getSaveData(), this.getSaveScreenCapture(), false);
			}
			catch( e )
			{
				this.printf("execAutoSave failed\n");
				::printException(e);
			}

			this.onAutoSave(false);
		}
	}

	function isReaded( textid )
	{
		return textid != null && this.getReaded(this.curSceneId) >= textid + 2;
	}

	function isAllReaded()
	{
		local count = this.getReaded(this.curSceneId);

		if (this.curSceneInfo != null)
		{
			return count >= this.curSceneInfo.textCount + 1;
		}

		return false;
	}

	function canDispText( text )
	{
		return text != null;
	}

	scnStorage = null;
	scenario = null;
	outlineNo = null;
	firstScene = false;
	storeHistory = true;
	function getStorage( sceneName )
	{
		if (sceneName != null)
		{
			local n = sceneName.find("*");

			if (n != null)
			{
				return sceneName.substr(0, n);
			}
			else
			{
				return sceneName;
			}
		}
	}

	function getLabel( sceneName )
	{
		if (sceneName != null)
		{
			local n = sceneName.find("*");

			if (n != null)
			{
				return sceneName.substr(n);
			}
			else
			{
				return "";
			}
		}
	}

	function getLine( cur )
	{
		if ("lines" in this.scenario)
		{
			if (cur < this.scenario.lines.len())
			{
				return this.scenario.lines[cur];
			}
		}

		return null;
	}

	function getTextCount()
	{
		return "texts" in this.scenario ? this.scenario.texts.len() : 0;
	}

	function getTextInfo( idx )
	{
		if ("texts" in this.scenario)
		{
			idx--;

			if (idx < this.scenario.texts.len())
			{
				return this.convertSceneText(this.scenario.texts[idx]);
			}
		}
	}

	function checkTextVoice( idx )
	{
		if ("texts" in this.scenario)
		{
			idx--;

			if (idx < this.scenario.texts.len())
			{
				return this.scenario.texts[idx][3] != null;
			}
		}

		return true;
	}

	function getLabelPoint( label )
	{
		if ("jumplabels" in this.scenario)
		{
			local labels = this.scenario.jumplabels;

			if (label in labels)
			{
				return labels[label];
			}
		}

		this.printf("not found jump label:%s\n", label);
	}

	function canOutline()
	{
		return this.outlineNo != null;
	}

	function getOutlineLine( cur )
	{
		return this.scnStorage.getOutlineLine(this.outlineNo, cur);
	}

	function getOutlineText( idx )
	{
		return this.scnStorage.getOutlineText(this.outlineNo, idx);
	}

	sceneStart = null;
	sceneCur = null;
	sceneArg = null;
	startPoint = null;
	curSceneName = null;
	curSceneId = null;
	curSceneInfo = null;
	curSceneSelect = false;
	cur = null;
	curPoint = null;
	curLine = null;
	curTextId = 0;
	curReaded = false;
	curEvent = false;
	curSelectIdx = -1;
	saveText = null;
	outlineMode = false;
	outlineCur = 0;
	function setOutlineMode( mode )
	{
		if (this.outlineMode != mode)
		{
			this.outlineMode = mode;
			this.onOutlineMode(mode);
		}
	}

	playTime = 0;
	playStartTime = 0;
	function getCurStorage()
	{
		return this.getStorage(this.curSceneName);
	}

	function getCurLabel()
	{
		return this.getLabel(this.curSceneName);
	}

	function getWorking()
	{
		return this.curSceneName != null;
	}

	function clearInfo()
	{
		this.clearScene();
		this.delaycancel();
		this.scenario = null;
		this.outlineNo = null;
		this.firstScene = false;
		this.startPoint = null;
		this.curSceneName = null;
		this.curSceneId = null;
		this.curSceneInfo = null;
		this.curPoint = null;
		this.curLine = null;
		this.curTextId = 0;
		this.curReaded = false;
		this.curEvent = false;
		this.cur = null;
		this.clickSkipEnabled = true;
		this.keywaitLabelCount = 0;
		this.saveText = null;
	}

	function clearStatus()
	{
		this.autoMode = false;
		this.playStatus = 0;
		this.skipMode = 0;
		this.forceSkip = 0;
		this.checkPlayMode();
	}

	function clear()
	{
		this.clearEnv();
		this.sceneStart = null;
		this.sceneCur = null;
		this.sceneArg = null;
		this.scnStorage = null;
		this.clearHistory();
		this.setMsgType();
		this.playTime = 0;
		this.setOutlineMode(false);
		this.clearStatus();
		this.onClear();
		this.recordEnable = true;
	}

	function clearQuit()
	{
		this.clearInfo();
		this.setOutlineMode(false);
		this.clearStatus();
		this.onClear();
	}

	function initStorage( storage )
	{
		if (this.scnStorage == null || this.scnStorage.storage != storage)
		{
			this.scnStorage = this.StorageData(storage);
		}
	}

	function _loadScene( storage )
	{
		this.outlineNo = this.getval(this.scenario, "outline");
		this.firstScene = this.scenario.label == this.scnStorage.scenes[0].label;
		this.curSceneName = storage + this.scenario.label;
		this.curSceneId = this.getSceneId(this.curSceneName);
		this.curSceneInfo = this.getSceneInfo(this.curSceneId);
		this.curSceneSelect = ("selects" in this.scenario) && this.scenario.selects.len() > 0;
		this.curSelectIdx = -1;
		this.storeHistory = true;
		this.curReaded = this.isReaded(0);
		this.printf("loadScene %s%s:%s\n", this.curStorage, this.curLabel, this.curSceneId);
	}

	function loadSceneLine( storage, line )
	{
		this.clearInfo();
		storage = storage.tolower();
		this.initStorage(storage);
		this.scenario = this.scnStorage.findSceneLine(line);
		this._loadScene(storage);
	}

	function loadScene( sceneName )
	{
		this.clearInfo();
		local storage = this.getStorage(sceneName);
		local label = this.getLabel(sceneName);
		storage = storage.tolower();
		this.initStorage(storage);
		this.scenario = this.scnStorage.findScene(label);
		this._loadScene(storage);
	}

	function restore( obj, cont = false )
	{
		switch(typeof obj)
		{
		case "integer":
			local text = this.getTextInfo(obj);

			if (text != null)
			{
				this.restore(text.state, cont);
			}

			break;

		case "table":
			if (cont)
			{
				this.env.syncObject(obj);
			}
			else
			{
				this.env.onRestore(obj);
				this.setMsgVisible(this.msgWinState);

				if ("quake" in obj)
				{
					this.startQuake(obj.quake);
				}

				if ("afterimage" in obj)
				{
					this.printf("\x00e6\x00ae\x008b\x00e5\x0083\x008f\x00e5\x00be\x00a9\x00e5\x00b8\x00b0\x00e5\x0087\x00a6\x00e7\x0090\x0086:%s\n", obj.afterimage);
					this.setAfterImage(obj.afterimage);
				}

				if ("msgwin" in obj)
				{
					this.setMsgType(obj.msgwin);
				}
				else
				{
					this.msg.clear();

					if (this.submsg)
					{
						this.submsg.clear();
					}
				}

				if ("record" in obj)
				{
					this.recordEnable = obj.record;
				}
				else
				{
					this.recordEnable = true;
				}

				this.onRestore(obj);
			}

			break;
		}
	}

	function redrawText( id )
	{
		this.msg.clear();

		if (this.submsg)
		{
			this.submsg.clear();
		}

		local text;
		local texts = [];

		for( text = this.getTextInfo(id); id > 0 && text != null; id-- )
		{
			texts.insert(0, text);

			if (!(text.flag & 2))
			{
				break;
			}
		}

		local c = texts.len();

		for( local i = 0; i < c; i++ )
		{
			local text = texts[i];

			if (i == c - 1)
			{
				local _disp = ::parseLangTextName(text);
				this.msg.writeName(_disp);
			}

			local t = ::parseLangText(text, "text");
			this.msg.write(t, 0, 0, text.indent);

			if (text.flag & 1)
			{
				this.msg.write("\n");
			}

			if (this.submsg)
			{
				this.submsg.write(t, 0, 0, text.indent);

				if (text.flag & 1)
				{
					this.submsg.write("\n");
				}
			}
		}
	}

	function restoreText( id )
	{
		local text = this.getTextInfo(id);

		if (text != null && text.flag & 2)
		{
			id--;
			this.redrawText(id);
		}
	}

	function goToPoint( point )
	{
		local newcur = 0;
		local obj;
		this.curTextId = 0;

		if (typeof point == "string")
		{
			point = this.getLabelPoint(point);
		}

		if (typeof point == "integer")
		{
			for( obj = this.getLine(newcur); obj != null; newcur++ )
			{
				switch(typeof obj)
				{
				case "integer":
					this.curTextId = obj;
					break;

				case "array":
					if (typeof obj[0] == "integer" && obj[0] >= point)
					{
						this.restore(obj[1]);
						this.restoreText(this.curTextId + 1);
						this.cur = newcur;
						this.curPoint = obj[0];
						this.curLine = obj[4];
						this.curReaded = this.isReaded(this.curTextId);
						return;
					}

					break;
				}
			}
		}
	}

	function goToText( text )
	{
		if (false)
		{
			while (text - 1 > 0 && (this.getTextInfo(text - 1).flag & 1) != 0)
			{
				text--;
			}
		}

		local newcur = 0;
		local obj;

		for( obj = this.getLine(newcur); obj != null; newcur++ )
		{
			switch(typeof obj)
			{
			case "integer":
				this.curTextId = obj;
				break;

			case "array":
				if (typeof obj[0] == "integer" && obj[2] >= text)
				{
					this.restore(obj[1]);
					this.restoreText(this.curTextId + 1);
					this.cur = newcur;
					this.curPoint = obj[0];
					this.curLine = obj[4];
					this.curReaded = this.isReaded(this.curTextId);
					return;
				}

				break;
			}
		}
	}

	function goToLine( line )
	{
		line = this.toint(line);
		local newcur = 0;
		local obj;

		for( obj = this.getLine(newcur); obj != null; newcur++ )
		{
			switch(typeof obj)
			{
			case "integer":
				this.curTextId = obj;
				break;

			case "array":
				if (typeof obj[0] == "integer" && obj[4] >= line)
				{
					this.restore(obj[1]);
					this.restoreText(this.curTextId + 1);
					this.cur = newcur;
					this.curPoint = obj[0];
					this.curLine = obj[4];
					this.curReaded = this.isReaded(this.curTextId);
					return true;
				}

				break;

			case "string":
				this.setSystemFlag(obj, true);
				break;
			}
		}
	}

	storageCache = null;
	function getTextData( sceneName, idx, title = false )
	{
		local storage = this.getStorage(sceneName);
		local label = this.getLabel(sceneName);

		if (this.storageCache == null || this.storageCache.storage != storage)
		{
			this.storageCache = this.StorageData(storage);
		}

		return this.storageCache.getText(label, idx, title);
	}

	histories = null;
	historyFlags = null;
	historyLines = 0;
	historyMax = 0;
	historyRemoveList = [];
	historyRemoveMap = {};
	hcache = null;
	function initHistory( max )
	{
		this.historyMax = max;
		this.printf("historymax:%d\n", this.historyMax);
		this.histories = [];
		this.historyFlags = null;
		this.historyLines = 0;

		foreach( r in this.historyRemoveList )
		{
			if (r != null && r.name != null)
			{
				if (r.name in this.historyRemoveMap)
				{
					this.historyRemoveMap[r.name].append(r);
				}
				else
				{
					this.historyRemoveMap[r.name] <- [
						r
					];
				}
			}
		}

		this.hcache = null;
	}

	function getSceneHistoryCount()
	{
		return this.histories.len() + 1;
	}

	function getSceneHistoryData( no )
	{
		local sinfo;
		local title;
		local idx;

		if (no < this.histories.len())
		{
			local info = this.histories[no];
			idx = info[2] - this.histories[0][2];
			sinfo = this.getSceneInfo(info[0]);
		}
		else
		{
			idx = this.getStoreHistoryLines();
			sinfo = this.curSceneInfo;
		}

		if (sinfo != null)
		{
			if (sinfo.selects != null)
			{
				title = sinfo.title + ": \x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e8\x0082\x00a2";
			}
			else
			{
				title = sinfo.title;
			}
		}
		else
		{
			title = "\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x0088\x00e3\x0083\x00ab\x00e4\x00b8\x008d\x00e6\x0098\x008e";
		}

		return {
			title = title,
			idx = idx
		};
	}

	function filterSceneHistory( func )
	{
		local ret = [];

		foreach( i, info in this.histories )
		{
			if (func(info[3]))
			{
				ret.append(i);
			}
		}

		if (func(this.curSceneName))
		{
			ret.append(this.histories.len());
		}

		return ret;
	}

	function getLastHistory()
	{
		local c = this.histories.count;

		if (c > 0)
		{
			return this.histories[c - 1];
		}
	}

	function clearHistory()
	{
		this.histories.clear();
		this.storageCache = null;
		this.hcache = null;
	}

	function resizeHistory( n, start )
	{
		this.historyLines = start;
		local c = this.histories.len();
		this.histories.resize(n);
		this.hcache = null;
	}

	function setHistoryFlag()
	{
		this.historyFlags = clone this.flags;
	}

	function matchHistory( n, remove )
	{
		local c = remove.len();

		for( local i = 0; i < c; i++ )
		{
			local h = n + i;

			if (h >= this.histories.len() || this.histories[h][3] != remove[i])
			{
				return false;
			}
		}

		return true;
	}

	function addHistory()
	{
		if (this.curSceneId != null)
		{
			if (this.curSceneName in this.historyRemoveMap)
			{
				foreach( info in this.historyRemoveMap[this.curSceneName] )
				{
					local remove = false;
					local s = this.histories.len() - 1 - info.back;

					if (s < 0)
					{
						s = 0;
					}

					local start = this.histories[s][2];
					local c = this.histories.len();

					for( local i = s; i < c; i++ )
					{
						if (this.matchHistory(i, info.remove))
						{
							local removeCount = info.remove.len();

							for( local j = 0; j < removeCount; j++ )
							{
								this.histories.erase(i);
							}

							remove = true;
							break;
						}
					}

					if (remove)
					{
						this.historyLines = start;
						local n = this.histories.len();

						for( local i = s; i < n; i++ )
						{
							this.histories[i][2] = this.historyLines;
							this.historyLines += this.histories[i][4];
						}

						break;
					}
				}
			}

			local textCount = this.getval(this.curSceneInfo, "textCount", 0);
			this.histories.append([
				this.curSceneId,
				this.historyFlags,
				this.historyLines,
				this.curSceneName,
				textCount,
				this.curSceneSelect,
				this.curSelectIdx
			]);
			this.historyLines += textCount;

			if (this.histories.len() > this.historyMax)
			{
				if (this.DONT_REMOVE_SELECT)
				{
					local count = this.histories.len();

					for( local i = 0; i < count; i++ )
					{
						local h = this.histories[i];

						if (!h[5])
						{
							this.histories.erase(i);
							break;
						}
					}
				}

				if (this.histories.len() > this.historyMax)
				{
					this.histories.erase(0);
				}

				this.historyLines = 0;
				local count = this.histories.len();

				for( local i = 0; i < count; i++ )
				{
					local h = this.histories[i];
					h[2] = this.historyLines;
					this.historyLines += h[4];
				}
			}
		}
	}

	function getStoreHistoryLines()
	{
		if (this.histories.len() > 0)
		{
			return this.historyLines - this.histories[0][2];
		}
		else
		{
			return 0;
		}
	}

	function getHistoryLines()
	{
		return this.getStoreHistoryLines() + this.curTextId;
	}

	function findHistoryInfo( pos, begin, end )
	{
		local n = begin + (end - begin) / 2;
		local h = this.histories[n];
		local start = h[2];
		local count = h[4];

		if (pos >= start && pos < start + count)
		{
			return n;
		}

		if (begin >= end)
		{
			return -1;
		}

		if (pos < start)
		{
			return this.findHistoryInfo(pos, begin, n);
		}
		else
		{
			return this.findHistoryInfo(pos, n + 1, end);
		}
	}

	function getHistoryInfo( pos, clear = false )
	{
		local c = this.histories.len();

		if (c > 0)
		{
			pos += this.histories[0][2];
		}

		local i;

		if (this.hcache != null)
		{
			local h = this.histories[this.hcache];

			if (pos >= h[2] && pos < h[2] + h[4])
			{
				i = this.hcache;
			}
		}

		if (i == null)
		{
			i = this.findHistoryInfo(pos, 0, c);
		}

		if (i >= 0)
		{
			this.hcache = i;
			local h = this.histories[i];
			local info = this.getSceneInfo(h[0]);
			local flags = h[1];
			local start = h[2];
			local name = h[3];

			if (h[5])
			{
				local idx;

				if (h[6] >= 0)
				{
					idx = ::parseLangText(info.selects[h[6]], "text");
				}
				else
				{
					local nextSceneId;

					if (i + 1 < c)
					{
						nextSceneId = this.histories[i + 1][0];
					}
					else if (i + 1 == c)
					{
						nextSceneId = this.curSceneId;
					}

					if (nextSceneId != null)
					{
						local selects = info.selects;
						local sn = selects.len();

						for( local s = 0; s < sn; s++ )
						{
							local sel = selects[s];
							local sellabel = this.getval(sel, "storage", info.storage) + this.getval(sel, "target", "");

							if (sellabel != "" && nextSceneId == this.getSceneId(sellabel))
							{
								idx = ::parseLangText(sel, "text");
								break;
							}
						}
					}
				}

				if (clear)
				{
					this.resizeHistory(i, start);
				}

				return {
					scene = info.storage + info.target,
					title = info.title,
					flags = flags,
					idx = idx,
					hidx = i
				};
			}
			else
			{
				if (clear)
				{
					this.resizeHistory(i, start);
				}

				return {
					scene = info.storage + info.target,
					title = info.title,
					flags = flags,
					idx = pos - start + 1,
					hidx = i
				};
			}
		}
	}

	function getHistoryData( pos )
	{
		local lines = this.getStoreHistoryLines();
		local ret;

		if (pos >= lines)
		{
			ret = this.getTextInfo(pos - lines + 1);
			ret.hidx <- this.histories.len();
			ret.scene <- this.curSceneName;
		}
		else
		{
			local info = this.getHistoryInfo(pos);

			if (("idx" in info) && typeof info.idx == "integer")
			{
				ret = this.getTextData(info.scene, info.idx, true);
				ret.hidx <- info.hidx;
				ret.scene <- info.scene;
			}
			else
			{
				if (info.idx == null)
				{
					ret = {
						text = ::catLangText(this.SELECT_HISTORY_PREFIX, this.SELECT_HISTORY_WORKING),
						title = info.title,
						hidx = info.hidx,
						indent = 0
					};
				}
				else
				{
					ret = {
						text = ::catLangText(this.SELECT_HISTORY_PREFIX, info.idx),
						title = info.title,
						hidx = info.hidx,
						indent = 0
					};
				}

				ret.scene <- info.scene;
			}
		}

		return ret;
	}

	function checkHistoryJump( n )
	{
		return n < this.getHistoryLines();
	}

	function goToHistory( pos )
	{
		this.delaycancel();
		this.setOutlineMode(false);
		local lines = this.getStoreHistoryLines();

		if (pos >= lines)
		{
			if (this.curSceneSelect)
			{
				this.goToPoint(0);
			}
			else
			{
				local text = pos - lines + 1;

				if (text == 1)
				{
					this.goToPoint(0);
				}
				else
				{
					this.goToText(text);
				}
			}

			return;
		}

		local info = this.getHistoryInfo(pos, true);
		this.flags = clone info.flags;

		if (typeof info.idx == "integer")
		{
			local prevSceneName = this.curSceneName;
			this.loadScene(info.scene);
			this.onLoadScene(2, this.curSceneName, prevSceneName);

			if (info.idx == 1)
			{
				this.goToPoint(0);
			}
			else
			{
				this.goToText(info.idx);
			}
		}
		else
		{
			local prevSceneName = this.curSceneName;
			this.loadScene(info.scene);
			this.onLoadScene(2, this.curSceneName, prevSceneName);
			this.goToPoint(0);
		}

		this.setHistoryFlag();
	}

	nextJumpFlag = false;
	function goToNext()
	{
		this.delaycancel();
		this.nextJumpFlag = true;

		while (this.scenario != null)
		{
			::sync();

			if (this.outlineMode || this.allSkip || this.isAllReaded())
			{
				this.setAllSFlag();
				local ret = this.doNextScene();

				if (ret != null)
				{
					return ret;
				}

				if (!this.nextJumpFlag || this.curSceneSelect)
				{
					this.goToPoint(0);
					this.nextJumpFlag = false;
					return;
				}
			}
			else
			{
				this.goToText(this.getReaded(this.curSceneId));
				this.nextJumpFlag = false;
				return;
			}
		}
	}

	function doTag( obj )
	{
		local tagname = obj[0];

		if (tagname == "")
		{
			return;
		}

		local elm = {};
		local count = obj.len();

		for( local i = 1; i < count; i += 2 )
		{
			local name = obj[i];
			local value = obj[i + 1];
			elm[name] <- value;
		}

		local fname = "tag_" + tagname;

		if (fname in this)
		{
			local handler = this[fname];
			handler(elm);
			return;
		}

		this.printf("\x00e4\x00b8\x008d\x00e6\x0098\x008e\x00e3\x0082\x00bf\x00e3\x0082\x00b0:%s\n", tagname);
	}

	function onTag( elm )
	{
		if ("tagname" in elm)
		{
			local fname = "tag_" + elm.tagname;

			if (fname in this)
			{
				local handler = this[fname];
				handler(elm);
				return true;
			}

			return false;
		}
	}

	delaystart = null;
	delaylist = null;
	delaytimes = null;
	fasttag = null;
	delaythread = null;
	delaych = null;
	function initDelay()
	{
		this.delaylist = [];
		this.delaytimes = [];
		this.fasttag = [];
		this.delaythread = [];
		this.delaych = [];
	}

	function entryDelayTime( time )
	{
		local c = this.delaytimes.len();

		for( local i = 0; i < c; i++ )
		{
			if (time < this.delaytimes[i])
			{
				this.delaytimes.insert(i, time);
				return time;
			}
		}

		this.delaytimes.append(time);
		return time;
	}

	function entryDelay( label, tag )
	{
		if (typeof label == "integer")
		{
			this.delaylist.append([
				this.entryDelayTime(label),
				tag
			]);
		}
		else
		{
			this.delaylist.append([
				label,
				tag
			]);

			if (label.charAt(0) == "w")
			{
				this.delaych.append(::toint(label.substr(1)));
			}
		}
	}

	function extractDelay( label )
	{
		local i = 0;

		while (i < this.delaylist.len())
		{
			local delay = this.delaylist[i];
			local dlabel = delay[0];

			if (typeof label == "string" && typeof dlabel == "string" && label == dlabel || typeof label == "integer" && typeof dlabel == "integer" && label >= dlabel)
			{
				this.fasttag.append(delay[1]);
				this.delaylist.erase(i);
				continue;
			}

			i++;
		}
	}

	function updateDelay()
	{
		if (this.delaytimes.len() > 0)
		{
			local current = this.getCurrentTick();

			if (this.delaystart == null)
			{
				this.delaystart = current;
			}

			current -= this.delaystart;
			local i = 0;
			local doflag = false;

			while (i < this.delaytimes.len() && current >= this.delaytimes[i])
			{
				this.delaytimes.erase(i);
				doflag = true;
				i++;
			}

			if (doflag)
			{
				this.extractDelay(current);
			}
		}
	}

	function doDelay()
	{
		if (this.fasttag.len() > 0)
		{
			foreach( tag in this.fasttag )
			{
				this.doTag(tag);
			}

			this.fasttag.clear();
		}
	}

	function playDelay( labels )
	{
		local n = 0;
		local ll = labels != null ? labels.len() : 0;

		for( local i = 0; i < ll; n += this.getPassedFrame() )
		{
			while (i < ll && n >= labels[i])
			{
				this.extractDelay(labels[i + 1]);
				i += 2;
			}

			::suspend();
		}
	}

	function entryDelayLabels( labels )
	{
		this.delaythread.append(::fork(this.playDelay.bindenv(this), labels));
	}

	function delayinit()
	{
		this.delaystart = this.getCurrentTick();
	}

	function delaydone()
	{
		if (this.delaythread.len() > 0)
		{
			foreach( th in this.delaythread )
			{
				th.exit();
			}

			this.delaythread.clear();
		}

		if (this.fasttag.len() > 0)
		{
			foreach( tag in this.fasttag )
			{
				this.doTag(tag);
			}

			this.fasttag.clear();
		}

		if (this.delaylist.len() > 0)
		{
			foreach( delay in this.delaylist )
			{
				this.doTag(delay[1]);
			}

			this.delaylist.clear();
		}

		this.delaytimes.clear();
		this.delaych.clear();
		this.delaystart = null;
	}

	function delaycancel()
	{
		if (this.delaythread.len() > 0)
		{
			foreach( th in this.delaythread )
			{
				th.exit();
			}

			this.delaythread.clear();
		}

		if (this.fasttag.len() > 0)
		{
			this.fasttag.clear();
		}

		if (this.delaylist.len() > 0)
		{
			this.delaylist.clear();
		}

		this.delaytimes.clear();
		this.delaych.clear();
		this.delaystart = null;
	}

	function nameFilter( name )
	{
		return this.getAliasName(name);
	}

	function textFilter( text )
	{
		return text;
	}

	function getAliasName( name )
	{
		local alias = this.getVoiceAlias(name);

		if (alias != null)
		{
			return alias.charAt(0) == "&" ? this.eval(alias.substr(1)) : alias;
		}

		return name;
	}

	keywaitLabelCount = 0;
	function waitKey( linemode = null, waitvoice = false )
	{
		if (linemode != null)
		{
			this.msgWait(linemode ? 1 : 2);
		}

		local time = this.autoWait * this.actSkipSpeed;

		if (time <= 0)
		{
			time = 1;
		}

		local endTick = this.getCurrentTick() + time;
		local click = false;

		for( local cancel = false; !cancel;  )
		{
			if (this.isAuto())
			{
				if (waitvoice)
				{
					for( click = false; this.voice.getAllPlaying() && this.isAuto(); click = this.workSync() )
					{
						if (this.isSkip() || click)
						{
							cancel = true;
							break;
						}
					}
				}

				if (!cancel && this.isAuto())
				{
					local time = endTick - this.getCurrentTick();

					if (time > 0)
					{
						local timeout = this.getCurrentTick() + time;

						for( click = false; timeout - this.getCurrentTick() > 0; click = this.workSync() )
						{
							if (this.isSkip() || click || !this.isAuto())
							{
								break;
							}
						}
					}

					cancel = true;
				}
			}
			else
			{
				if (this.isSkip() || click)
				{
					cancel = true;
					break;
				}

				click = this.workSync(true);
			}
		}
	}

	NEXTVOICE_FLAG = false;
	function checkNextVoice( text )
	{
		if (this.NEXTVOICE_FLAG)
		{
			return (this.textflag & 512) != 0;
		}
		else
		{
			return this.checkTextVoice(this.curTextId + 1);
		}
	}

	function doText( text )
	{
		this.delayinit();
		local flag = text.flag;
		local line = (flag & 1) != 0;
		local wvoice = this.voiceWaitMode == 0 || this.voiceWaitMode == 1 && (this.checkNextVoice(text) || this.voiceCut);
		local _disp = ::parseLangTextName(text);
		local _text = ::parseLangText(text, "text");
		local disp = this.nameFilter(::getLanguageText(_disp, this.languageId));
		local txt = this.textFilter(::getLanguageText(_text, this.languageId));
		this.saveText = this.createSaveText(disp, txt);

		if (flag & 8)
		{
			if (!this.curEvent)
			{
				if (this.autoSaveMode & 4)
				{
					this.execAutoSave();
				}

				this.cancelPlayMode(8);
			}

			this.curEvent = true;
		}
		else
		{
			this.curEvent = false;
		}

		local vwait = 0;
		local startTick;
		local subfunc;
		local submaxnum;

		if (flag & 32)
		{
			startTick = this.getCurrentTick();

			if (("voice" in text) && !this.isSkip())
			{
				vwait = this.playVoice(text.voice, true);
			}
		}
		else
		{
			this.tag_msgon();

			if (!(flag & 2))
			{
				this.msg.clear();

				if (this.submsg)
				{
					this.submsg.clear();
				}
			}
			else
			{
				this.msg.doClear();

				if (this.submsg)
				{
					this.submsg.doClear();
				}
			}

			this.setMsgDefaultColor();
			this.msg.writeName(_disp);
			this.onAfterName(text, disp);

			if (("voice" in text) && !this.isSkip())
			{
				vwait = this.playVoice(text.voice, true);
			}

			local diffTime = this.chStep * this.actSkipSpeed;
			local allTime = this.voiceSync ? (vwait > 0 ? vwait : 0) : -1;
			this.msg.write(_text, diffTime, allTime, text.indent);

			if (this.submsg)
			{
				local all = this.msg.getRenderDelay();
				this.submsg.write(_text, diffTime, all, text.indent);
				this.submsg.setShowCount(0);
				submaxnum = this.submsg.getRenderCount();
				subfunc = ::fork(function () : ( submsg, submaxnum )
				{
					local startTick = this.getCurrentTick();
					local dispnum;

					do
					{
						local tick = this.getCurrentTick() - startTick;
						dispnum = this.textSkipMode ? submaxnum : submsg.calcShowCount(tick);

						if (dispnum > submaxnum)
						{
							dispnum = submaxnum;
						}

						submsg.setShowCount(dispnum);
						::sync();
					}
					while (dispnum < submaxnum);
				}.bindenv(this));
			}

			local keyWait = this.msg.getKeyWait();
			local maxnum = this.msg.getRenderCount();
			startTick = this.getCurrentTick();
			local dispnum;

			do
			{
				local tick = this.getCurrentTick() - startTick;
				dispnum = this.textSkipMode ? maxnum : this.msg.calcShowCount(tick);

				while (this.delaych.len() > 0 && this.delaych[0] <= dispnum)
				{
					this.extractDelay("w" + this.delaych[0]);
					this.delaych.erase(0);
				}

				if (keyWait != null && keyWait.len() > 0 && keyWait[0].pos <= dispnum)
				{
					local key = keyWait[0];
					dispnum = key.pos;
					this.msg.setShowCount(dispnum);

					if (!this.isSkip())
					{
						this.waitKey(true, wvoice);
					}

					this.extractDelay("kl" + ++this.keywaitLabelCount);
					startTick = this.getCurrentTick() - key.time;
					keyWait.remove(0);
				}
				else
				{
					if (dispnum > maxnum)
					{
						dispnum = maxnum;
					}

					this.msg.setShowCount(dispnum);

					if (this.textSync())
					{
						this.textSkipMode = this.skipToPage ? 2 : 1;
					}
				}
			}
			while (dispnum < maxnum);
		}

		if (flag & 1)
		{
			if (this.textSkipMode == 1)
			{
				this.textSkipMode = 0;
			}
		}
		else
		{
			this.textSkipMode = 0;
		}

		while (this.delaych.len() > 0)
		{
			this.extractDelay("w" + this.delaych[0]);
			this.delaych.erase(0);
		}

		this.extractDelay("textend");
		this.onAfterMsg(text);

		if (!this.isSkip() && !this.textSkipMode)
		{
			if (flag & 4)
			{
				local timeout;

				if (vwait > 0)
				{
					timeout = startTick + vwait - this.getCurrentTick();
				}
				else
				{
					timeout = text.nowaitTime;
				}

				if (timeout > 0)
				{
					timeout += this.getCurrentTick();

					for( local click = false; timeout - this.getCurrentTick() > 0; click = this.workSync() )
					{
						if (this.isSkip() || click)
						{
							break;
						}
					}
				}
			}
			else
			{
				this.waitKey(flag & 1, wvoice);
			}
		}

		if (subfunc)
		{
			subfunc.exit();
			subfunc = null;

			if (this.submsg)
			{
				this.submsg.setShowCount(submaxnum);
			}
		}

		if (flag & 1)
		{
			this.onAfterLine(text);
			this.msg.write("\n");

			if (this.msgWinState)
			{
				this.msgWait(0);
			}
		}
		else
		{
			this.onAfterPage(text);
			this.stopAllActions();
			this.env.dispSync();

			if (flag & 64)
			{
				if (this.msgWinState)
				{
					if (!this.isSkip())
					{
						this.msg.clear();

						if (this.submsg)
						{
							this.submsg.clear();
						}
					}
					else
					{
						this.msg.setClear();

						if (this.submsg)
						{
							this.submsg.setClear();
						}
					}

					this.msgWait(0);
				}
			}
		}

		if (this.voiceCut || this.isSkip())
		{
			this.stopAllVoice();
		}
		else
		{
			this.stopVoiceTarget();
		}

		this.delaydone();
		this.keywaitLabelCount = 0;
	}

	selectclass = ::EnvSelectDialog;
	selectPanel = null;
	selectCanHide = false;
	selectCanCommand = true;
	selectType = null;
	selectUpdateFlag = false;
	function choiceSelect( list, info )
	{
		local ret = {
			storage = "motion/envselect.psb",
			chara = null
		};

		if ("name" in info || "message" in info || "evalmessage" in info)
		{
			ret.msgoff <- false;

			if ("name" in info)
			{
				ret.name <- info.name;
			}

			if ("evalmessage" in info)
			{
				ret.evalmessage <- info.evalmessage;
			}
			else if ("message" in info)
			{
				ret.message <- info.message;
			}

			if ("priority" in info)
			{
				ret.priority <- info.priority;
			}

			if ("type" in info)
			{
				ret.type <- info.type;
			}
		}

		return ret;
	}

	function canHideSelect()
	{
		return this.selectPanel != null && this.selectPanel.visible && this.selectCanHide;
	}

	function onFirstSelectShow( selinfo )
	{
		this.printf("select autosave:%s:%s\n", this.startPoint, this.curPoint);

		if ((this.startPoint == null || this.curPoint > this.startPoint) && (this.autoSaveMode & 1) != 0)
		{
			this.execAutoSave();
		}
	}

	function doSelect( selects, selinfo, seltype, cur = null )
	{
		local cancel = ::getint(selinfo, "cancel", 0);
		local timeout = ::getint(selinfo, "timeout", 0);
		local sellist = [];
		local selCancel;
		local selTimeout;

		foreach( i, sel in selects )
		{
			local eval = this.getval(sel, "eval");

			if (eval == null || this.eval(eval))
			{
				switch(sel.text)
				{
				case "__\x00e6\x0099\x0082\x00e9\x0096\x0093\x00e5\x0088\x0087\x00e3\x0082\x008c":
				case "__\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x00a0\x00e3\x0082\x00a2\x00e3\x0082\x00a6\x00e3\x0083\x0088":
				case "__timeout":
					selTimeout = sel;
					break;

				case "__\x00e3\x0082\x00ad\x00e3\x0083\x00a3\x00e3\x0083\x00b3\x00e3\x0082\x00bb\x00e3\x0083\x00ab":
				case "__cancel":
					selCancel = sel;
					break;

				default:
					sellist.append(sel);
					break;
				}
			}
		}

		if (this.getval(selinfo, "random"))
		{
			local randsel = [];

			while (sellist.len() > 0)
			{
				local n = this.intrandom(sellist.len() - 1);
				randsel.append(sellist[n]);
				sellist.erase(n);
			}

			sellist = randsel;
		}

		local result;

		if (sellist.len() > 0)
		{
			this.selectUpdateFlag = ::getbool(seltype, "update", false);
			local priority = "priority" in seltype ? seltype.priority : 99999999;
			this.selectPanel = this.selectclass(this.getScreen(), priority, 1.0 / this.envscale);
			this.selectPanel.setDelegate(this);
			this.onSelectStart(selinfo, seltype);

			try
			{
				result = this.selectPanel.select(sellist, selinfo, cur, seltype.chara, seltype.storage, ::getval(seltype, "context"));
			}
			catch( e )
			{
				if (e instanceof this.GameStateException)
				{
					this.onSelectException();
					throw e;
				}

				this.printf("failed to open select:%s\n", seltype.storage, seltype.chara);
				::printException(e);
			}

			this.onSelectEnd(selinfo, result, seltype);
		}

		if (typeof result == "integer")
		{
			result = sellist[result];
		}
		else
		{
			switch(result)
			{
			case "cancel":
				result = selCancel;
				break;

			case "timeout":
				result = selTimeout;
				break;

			default:
				this.printf("warn:unknown select result:%s\n", result);
				result = null;
				break;
			}
		}

		this.selectPanel = null;
		this.selectType = null;
		this.selectUpdateFlag = false;
		return result;
	}

	function doNext( nextList )
	{
		if (nextList != null && nextList.len() > 0)
		{
			this.startPoint = null;

			foreach( next in nextList )
			{
				local type = next.type;
				local eval = this.getval(next, "eval");
				local confirm = this.getval(next, "confirm");

				switch(type)
				{
				case 0:
					if ((eval == null || this.eval(eval)) && (confirm == null || confirm("%C" + confirm)))
					{
						return next;
					}

					break;

				case 1:
					if ((eval == null || this.eval(eval)) && (confirm == null || confirm("%C" + confirm)))
					{
						this.onExit(type);
						return null;
					}

					break;
				}
			}
		}
	}

	function _doSet( name, value )
	{
		local l = name.len();

		if (l > 3 && name.slice(0, 3) == "sf.")
		{
			this.setSystemFlag(name.slice(3), value);
		}
		else if (l > 3 && name.slice(0, 3) == "tf.")
		{
			this.setTFlag(name.slice(3), value);
		}
		else if (l > 2 && name.slice(0, 2) == "f.")
		{
			this.setFlag(name.slice(2), value);
		}
	}

	function _doEval( exp )
	{
		try
		{
			this.exec(exp);
		}
		catch( e )
		{
			this.printf("warn: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");
			this.printf("warn: doEval:invalid expression:%s\n", exp);
			this.printf("warn: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n");
			this.printException(e);
		}
	}

	function doEval( exp )
	{
		if (typeof exp == "string")
		{
			this._doEval(exp);
		}
		else if (typeof exp == "array")
		{
			this._doSet(exp[0], exp[1]);
		}
		else if (typeof exp == "table")
		{
			local eval = this.getval(exp, "eval");

			if (eval == null || this.eval(eval))
			{
				if ("exp" in exp)
				{
					this._doEval(exp.exp);
				}
				else if (("name" in exp) && "value" in exp)
				{
					this._doSet(exp.name, exp.value);
				}
			}
		}
	}

	function getPlayTime()
	{
		return this.playTime + this.getCurrentPlayTime();
	}

	function getCurrentPlayTime()
	{
		return this.getCurrentSecond() - this.playStartTime;
	}

	function resetPlayTime()
	{
		local second = this.getCurrentSecond();
		local current = second - this.playStartTime;
		this.playTime += current;
		this.playStartTime = second;
		return current;
	}

	function restoreFlag( flags, saveFlags )
	{
		flags.clear();

		foreach( n, v in saveFlags )
		{
			if (typeof v == "bool")
			{
				flags[n] <- v ? 1 : 0;
			}
			else
			{
				flags[n] <- v;
			}
		}
	}

	function createSaveText( disp, text )
	{
		if (disp == null || disp == "")
		{
			return text;
		}
		else
		{
			return this.format("\x00e3\x0080\x0090%s\x00e3\x0080\x0091%s", disp, text);
		}
	}

	function createSaveTextForSelect( selects, selinfo )
	{
		if ("caption" in selinfo)
		{
			return ::catLangText(this.SELECT_HISTORY_PREFIX, ::parseLangText(selinfo, "caption"));
		}
		else if ("message" in selinfo)
		{
			return ::parseLangText(selinfo, "message");
		}
	}

	function getSaveData()
	{
		local hdata = [];

		foreach( h in this.histories )
		{
			hdata.append({
				scene = h[0],
				selidx = h[6],
				flags = h[1]
			});
		}

		foreach( n, v in this.flags )
		{
			this.printf("store flag:%s:%s\n", n, v);
		}

		local savedate = this.getLocalDateTime();
		local ret = {
			storage = this.curStorage,
			target = this.curLabel,
			point = this.curPoint,
			flags = clone this.flags,
			history = hdata,
			historyCount = hdata.len(),
			playTime = this.getPlayTime(),
			title = ::getval(this.curSceneInfo, "title", this.curSceneName),
			year = savedate.year,
			mon = savedate.mon,
			mday = savedate.mday,
			hour = savedate.hour,
			min = savedate.min,
			sec = savedate.sec,
			timeOrigin = this.timeOrigin != null ? this.timeOrigin - this.getCurrentTick() : -1,
			start = this.sceneStart != null ? this.sceneStart : "",
			cur = this.sceneCur != null ? this.sceneCur : "",
			arg = this.sceneArg != null ? this.sceneArg : ""
		};

		if (this.saveText != null)
		{
			ret.text <- this.saveText;
		}

		return ret;
	}

	function setSaveData( saveData )
	{
		if ("flags" in saveData)
		{
			this.restoreFlag(this.flags, saveData.flags);
		}

		if ("historyCount" in saveData)
		{
			for( local i = 0; i < saveData.historyCount; i++ )
			{
				local h = saveData.history[i];
				local f = {};
				this.restoreFlag(f, h.flags);
				local sceneInfo = this.getSceneInfo(h.scene);

				if (sceneInfo != null)
				{
					local sceneName = sceneInfo.storage + sceneInfo.target;
					this.histories.append([
						h.scene,
						f,
						this.historyLines,
						sceneName,
						sceneInfo.textCount,
						sceneInfo.selects != null,
						h.selidx
					]);
					this.historyLines += sceneInfo.textCount;
				}
			}
		}

		if ("playTime" in saveData)
		{
			this.playTime = saveData.playTime;
		}

		if ("timeOrigin" in saveData)
		{
			if (saveData.timeOrigin > 0)
			{
				this.timeOrigin = this.getCurrentTick() + this.timeOrigin;
			}
		}

		if ("text" in saveData)
		{
			this.saveText = saveData.text;
		}

		this.sceneStart = ::getval(saveData, "start");
		this.sceneCur = ::getval(saveData, "cur");
		this.sceneArg = ::getval(saveData, "arg");
	}

	function main( scene )
	{
		local storage = ::getval(scene, "storage");
		local target = ::getval(scene, "target");
		local point = ::getval(scene, "point");
		local saveData = scene;
		local sceneMode = ::getval(scene, "mode", 0);
		local outline = ::getval(scene, "outline", false);
		this.forcePlayVoice = ::getbool(saveData, "forcePlayVoice", false);
		this.updateConfig();
		this.sceneMode = sceneMode;

		if (typeof storage == "array")
		{
			this.playScenes = storage;
			local sceenName = this.playScenes[0];
			this.playScenes.remove(0);
			storage = this.getStorage(this.sceneName);
			target = this.getLabel(this.sceneName);
			point = null;
		}
		else
		{
			if (storage.find("*") != null)
			{
				target = this.getLabel(storage);
				storage = this.getStorage(storage);
			}

			this.playScenes = null;
		}

		this.clear();
		this.playStartTime = this.getCurrentSecond();
		this.setupTransition();

		try
		{
			if (saveData != null)
			{
				this.setSaveData(saveData);
			}

			if (storage == "")
			{
				storage = this.curStorage;
			}

			if (target == null)
			{
				target = "";
			}

			if (typeof target == "integer" || target != "" && target.charAt(0) != "*")
			{
				local prevSceneName = this.curSceneName;
				this.loadSceneLine(storage, ::toint(target));
				this.onLoadScene(0, this.curSceneName, prevSceneName);
				this.goToLine(::toint(target));
				this.doPreEvals();
			}
			else
			{
				local prevSceneName = this.curSceneName;
				this.loadScene(storage + target);

				if (point == null && target != "" && target != this.curLabel)
				{
					this.printf("change target to point:%s\n", target);
					point = target;
				}

				this.onLoadScene(0, this.curSceneName, prevSceneName);

				if (point == null)
				{
					this.goToPoint(0);
					this.doPreEvals();
				}
				else
				{
					this.goToPoint(point);
				}
			}

			if (this.sceneStart == null || this.sceneStart == "")
			{
				this.sceneStart = this.curSceneName;
			}

			this.printf("sceneStart:%s\n", this.sceneStart);
			this.startPoint = this.curPoint;
			this.setHistoryFlag();

			if (outline && this.canOutline())
			{
				this.clearEnv();
				this.outlineCur = 0;
				this.setOutlineMode(true);
			}
		}
		catch( e )
		{
			this.printf("\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e8\x00aa\x00ad\x00e3\x0081\x00bf\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", storage);
			::printException(e);
			this.systemTransition();
			return -1;
		}

		local transtime = "transtime" in saveData ? saveData.transtime : 500;
		this.systemTransition({
			time = transtime
		});
		this.onSceneStart(saveData);
		::setRecordEnable(this.recordEnable);
		this.printf("\x00e9\x008c\x00b2\x00e7\x0094\x00bb\x00e7\x008a\x00b6\x00e6\x0085\x008b:%s\n", this.recordEnable);
		local result;

		while (result == null && this.scenario != null)
		{
			try
			{
				if (this.outlineMode)
				{
					result = this.sceneOutline();
				}
				else
				{
					result = this.sceneMain();
				}
			}
			catch( e )
			{
				if (e instanceof this.PlayerControlException)
				{
					this.autoMode = false;
					this.skipMode = 0;
					this.playStatus = 0;
					this.checkPlayMode();
					this.setupTransition();

					if (e instanceof this.HistoryJumpException)
					{
						this.onHistoryJump(true);
						this.goToHistory(e.pos);
						this.onHistoryJump(false);
						this.startPoint = this.curPoint;
					}
					else if (e instanceof this.NextJumpException)
					{
						this.onJump(true);
						result = this.goToNext();
						this.onJump(false);
					}
					else if (e instanceof this.OutlineChangeException)
					{
						if (this.outlineMode)
						{
							this.goToPoint(this.curPoint);
							this.startPoint = this.curPoint;
							this.setOutlineMode(false);
						}
						else
						{
							this.clearEnv();
							this.outlineCur = 0;
							this.setOutlineMode(true);
						}
					}
					else if (e instanceof this.RedrawException)
					{
						if (!this.outlineMode)
						{
							this.goToPoint(this.curPoint);
							this.startPoint = this.curPoint;
						}
					}
					else
					{
						this.printf("unknown player control exception\n");
					}

					this.systemTransition({
						time = 1000
					});
				}
				else
				{
					throw e;
				}

				::setRecordEnable(this.recordEnable);
				this.printf("\x00e9\x008c\x00b2\x00e7\x0094\x00bb\x00e7\x008a\x00b6\x00e6\x0085\x008b:%s\n", this.recordEnable);
			}
		}

		return result;
	}

	function doPreEvals()
	{
		if ("preevals" in this.scenario)
		{
			foreach( value in this.scenario.preevals )
			{
				this.doEval(value);
			}
		}
	}

	function doPostEvals()
	{
		if ("postevals" in this.scenario)
		{
			foreach( value in this.scenario.postevals )
			{
				this.doEval(value);
			}
		}
	}

	function loadNextScene( nextScene )
	{
		local ret;

		try
		{
			if (this.storeHistory)
			{
				this.addHistory();
			}

			local prevStorage = this.curStorage;
			local prevOutlineMode = this.outlineMode;
			local prevOutlineNo = this.outlineNo;
			local prevSceneName = this.curSceneName;
			this.loadScene(nextScene);
			this.onLoadScene(1, this.curSceneName, prevSceneName);

			if (!this.canOutline())
			{
				this.setOutlineMode(false);
			}

			if (this.outlineMode)
			{
				if (prevStorage != this.curStorage || !prevOutlineMode || prevOutlineNo != this.outlineNo)
				{
					this.outlineCur = null;
				}

				this.curPoint = 0;
				this.curLine = 0;
			}
			else
			{
				this.cur = 0;
				this.curPoint = 0;
				this.curLine = 0;
				local obj = this.getLine(0);

				if (obj != null)
				{
					this.restore(obj[1], true);
				}
			}

			this.doPreEvals();
			this.setHistoryFlag();
		}
		catch( e )
		{
			this.printf("\x00e6\x00ac\x00a1\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e8\x00aa\x00ad\x00e3\x0081\x00bf\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", nextScene);
			::printException(e);
			ret = -1;
		}

		this.checkPlayMode();
		return ret;
	}

	function doNextScene()
	{
		this.doPostEvals();

		if ("texts" in this.scenario)
		{
			this.setReaded(this.curSceneId, this.scenario.texts.len() + 3);
		}
		else
		{
			this.setReaded(this.curSceneId, 2);
		}

		this.onSceneNext();
		local next;

		if (this.playScenes != null && this.playScenes.len() > 0)
		{
			local scene = this.playScenes[0];
			this.playScenes.remove(0);

			if (typeof scene == "table")
			{
				next = scene;
			}
			else
			{
				next = {
					storage = this.getStorage(scene),
					target = this.getLabel(scene)
				};
			}
		}
		else
		{
			if (this.curSceneSelect)
			{
				this.cancelPlayMode(4);
				local selects = this.scenario.selects;
				local selinfo = ::getval(this.scenario, "selectInfo");
				local seltype = this.choiceSelect(selects, selinfo);

				if (typeof seltype == "table")
				{
					this.selectCanHide = !("canHide" in seltype) || seltype.canHide;
					this.selectCanCommand = !("canCommand" in seltype) || seltype.canCommand;
					this.selectType = ::getval(seltype, "type");

					if (!("msgoff" in seltype) || seltype.msgoff)
					{
						this.tag_msgoff();
					}
					else if ("message" in seltype || "evalmessage" in seltype)
					{
						this.tag_msgon();
						this.msg.clear();

						if ("name" in seltype)
						{
							this.msg.writeName(seltype.name);
						}

						if ("evalmessage" in seltype)
						{
							this.msg.write(this.eval(seltype.evalmessage));
						}
						else if ("message" in seltype)
						{
							this.msg.write(seltype.message);
						}
					}

					local stext = this.createSaveTextForSelect(selects, selinfo);

					if (stext != null)
					{
						this.saveText = stext;
					}

					next = this.doSelect(selects, selinfo, seltype);

					if (next != null)
					{
						if ("selidx" in next)
						{
							this.curSelectIdx = next.selidx;
							this.setSelectReaded(this.curSceneId, this.curSelectIdx);
						}

						local exp = this.getval(next, "exp");

						if (exp != null && exp != "")
						{
							try
							{
								this.exec(exp);
							}
							catch( e )
							{
								this.printf("WARNING:\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e8\x0082\x00a2\x00e7\x0094\x00a8\x00e3\x0082\x00b3\x00e3\x0083\x009e\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e5\x00ae\x009f\x00e8\x00a1\x008c\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", exp);
								::printException(e);
							}
						}

						if (!("storage" in next || "target" in next))
						{
							next = null;
						}
					}
				}
			}

			if (next == null)
			{
				next = this.doNext(::getval(this.scenario, "nexts"));

				if (next != null)
				{
					local exp = this.getval(next, "exp");

					if (exp != null && exp != "")
					{
						this.exec(exp);
					}
				}
			}
		}

		local nextStorage;
		local nextTarget;

		if (next != null)
		{
			if ("evalstorage" in next)
			{
				local storage = this.getval(next, "evalstorage");

				try
				{
					nextStorage = this.eval(storage);
				}
				catch( e )
				{
					this.printf("\x00e9\x0081\x00b7\x00e7\x00a7\x00bb\x00e5\x0085\x0088\x00e8\x00a9\x0095\x00e4\x00be\x00a1\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s\n", storage, e);
				}

				nextTarget = "";
			}
			else
			{
				nextStorage = this.getval(next, "storage");

				if (nextStorage == null)
				{
					nextStorage = this.curStorage;
				}

				nextTarget = this.getval(next, "target");

				if (nextTarget == null)
				{
					nextTarget = "";
				}
			}
		}

		if (nextStorage != null)
		{
			nextStorage = nextStorage.tolower();
		}

		if (this.sceneMode == 1 && nextStorage != this.curStorage || this.sceneMode == 2 && nextStorage + nextTarget != this.curSceneName)
		{
			this.exitGame();
		}

		if (nextStorage != this.curStorage)
		{
			this.cancelPlayMode(64);
		}

		if (nextStorage != null)
		{
			return this.loadNextScene(nextStorage + nextTarget);
		}

		this.printf("no next scene and exit\n");
		this.clearQuit();
		return 0;
	}

	function setAllSFlag()
	{
		local newcur = 0;
		local obj;

		for( obj = this.getLine(newcur); obj != null; newcur++ )
		{
			if (typeof obj == "string")
			{
				this.setSystemFlag(obj, true);
			}
		}
	}

	function sceneMain()
	{
		if (this.cur == null)
		{
			this.setupTransition();
			this.goToPoint(0);
			this.systemTransition();
		}

		local obj = this.getLine(this.cur++);

		if (obj == null)
		{
			return this.doNextScene();
		}

		switch(typeof obj)
		{
		case "integer":
			if (obj == 1)
			{
				if (this.firstScene && (this.startPoint == null || this.curPoint > this.startPoint) && (this.autoSaveMode & 2) != 0)
				{
					this.execAutoSave();
				}
			}

			this.curTextId = obj;
			this.setReaded(this.curSceneId, this.curTextId);
			local text = this.getTextInfo(this.curTextId);

			if (this.canDispText(text))
			{
				this.doText(text);
			}

			this.setReaded(this.curSceneId, this.curTextId + 1);
			this.curReaded = this.isReaded(this.curTextId);

			if (!this.canSkip())
			{
				this.cancelPlayMode(2);
			}

			break;

		case "string":
			this.setSystemFlag(obj, true);
			break;

		case "array":
			if (typeof obj[0] == "integer")
			{
				this.curPoint = obj[0];
				this.curLine = obj[4];
			}
			else if (obj[0] == "delayrun")
			{
				local tag = [];
				local c = obj.len();

				for( local i = 2; i < c; i++ )
				{
					tag.append(obj[i]);
				}

				this.entryDelay(obj[1], tag);
			}
			else
			{
				this.doTag(obj);
			}

			break;
		}
	}

	function sceneOutline()
	{
		if (this.outlineCur == null)
		{
			this.setupTransition();
			this.clearEnv();
			this.outlineCur = 0;
			this.systemTransition();
		}

		local obj = this.getOutlineLine(this.outlineCur);

		if (obj == null)
		{
			this.setAllSFlag();
			return this.doNextScene();
		}

		this.outlineCur++;

		switch(typeof obj)
		{
		case "integer":
			local text = this.getOutlineText(obj);

			if (text != null)
			{
				this.doText(text);
			}

			this.curReaded = false;
			break;

		case "string":
			this.setSystemFlag(obj, true);
			break;

		case "array":
			if (typeof obj[0] == "integer")
			{
			}
			else if (obj[0] == "delayrun")
			{
				local tag = [];
				local c = obj.len();

				for( local i = 2; i < c; i++ )
				{
					tag.append(obj[i]);
				}

				this.entryDelay(obj[1], tag);
			}
			else
			{
				this.doTag(obj);
			}

			break;
		}
	}

	function tag_exit( elm )
	{
		if (!("eval" in elm) || this.eval(elm.eval))
		{
			this.onExit(2);
			this.exitGame();
		}
	}

	function tag_endrecollection( elm )
	{
		local type = "type" in elm ? ::toint(elm.type) : 0;

		if (type == 0 && this.sceneMode >= 1 && this.sceneMode <= 3 || this.sceneMode == 3 + type)
		{
			this.onExit(type + 3);
			this.exitGame();
		}
	}

	function tag_clickskip( elm )
	{
		if (!("eval" in elm) || this.eval(elm.eval))
		{
			if ("enabled" in elm)
			{
				this.clickSkipEnabled = ::toint(elm.enabled) ? true : false;
			}
			else if ("enable" in elm)
			{
				this.clickSkipEnabled = ::toint(elm.enable) ? true : false;
			}
		}
	}

	function tag_beginskip( elm )
	{
		if (this.skipMode != 0)
		{
			this.printf("beginskip\x00e3\x0081\x00af\x00e5\x0085\x00a5\x00e3\x0082\x008c\x00e5\x00ad\x0090\x00e3\x0081\x00a7\x00e3\x0081\x008d\x00e3\x0081\x00be\x00e3\x0081\x009b\x00e3\x0082\x0093\n");
		}
		else
		{
			this.enableLeftBeginSkip = !("eval" in elm) || this.eval(elm.eval);

			if (!this.enableLeftBeginSkip)
			{
				if (this.playStatus == 2)
				{
					this.playStatus = this.autoMode ? 1 : 0;
					this.checkPlayMode();
				}
			}

			this.skipMode = this.isSkip() ? 2 : 1;
		}
	}

	function tag_endskip( elm )
	{
		this.skipMode = 0;
	}

	function tag_cancelskip( elm )
	{
		if (this.playStatus == 2)
		{
			this.playStatus = this.autoMode ? 1 : 0;
			this.checkPlayMode();
		}
	}

	function tag_cancelautomode( elm )
	{
		if (this.playStatus == 1)
		{
			this.autoMode = false;
			this.playStatus = 0;
			this.checkPlayMode();
		}
	}

	function tag_waitclick( elm )
	{
		this.delayinit();

		if (this.isSkip())
		{
			return;
		}

		local syncFunc = ("nocommand" in elm) && elm.nocommand ? this.waitSync.bindenv(this) : this.workSync.bindenv(this);

		if (this.isAuto())
		{
			local time = this.autoWait;

			if (time > 0)
			{
				local timeout = this.getCurrentTick() + time;

				for( local click = false; timeout - this.getCurrentTick() > 0; click = syncFunc() )
				{
					if (this.isSkip() || click || !this.isAuto())
					{
						break;
					}
				}
			}
		}

		if (!this.isAuto())
		{
			for( local click = false; true; click = syncFunc() )
			{
				if (this.isSkip() || click || this.isAuto())
				{
					break;
				}
			}
		}
	}

	function tag_wact( elm )
	{
		this.delayinit();
		this.waitAllAction();
	}

	function tag_stopaction( elm )
	{
		this.stopAllActions(!("all" in elm) || ::toint(elm.all) != 0);
	}

	function tag_playvoice( elm )
	{
		if (("name" in elm) && "voice" in elm)
		{
			this.stopVoice(elm.name, 0);
			local name = elm.name;

			if (this.forcePlayVoice || this.getVoiceOn(name))
			{
				local volume = this.getVoiceVolume(name) * 100;
				this.voice.play(elm.voice, volume, null, 0, {
					name = name
				});
			}

			if ("wait" in elm)
			{
				this.waitVoice(elm);
			}
		}
	}

	function tag_stopvoice( elm )
	{
		local time = this.isSkip() ? 0 : ::getint(elm, "time", this.VOICESTOPFADE);
		this.stopVoice(::getval(elm, "name"), time);
	}

	function tag_waitvoice( elm )
	{
		this.delayinit();
		this.waitVoice(elm);
	}

	function tag_quake( elm )
	{
		this.stopQuake();
		this.startQuake(elm);
	}

	function tag_stopquake( elm )
	{
		this.stopQuake();
	}

	function tag_wq( elm )
	{
		this.delayinit();
		this.waitQuake();
	}

	function tag_afterimage( elm )
	{
		if ("level" in elm)
		{
			this.setAfterImage(::toint(elm.level));
		}
	}

	function tag_msgwin( elm )
	{
		if (this.msgWinState)
		{
			this.msgoff(this.MSGFADETIME);
		}

		this.msgWinState = false;
		this.doHideFace();

		if ("type" in elm)
		{
			this.setMsgType(elm.type);
		}
		else
		{
			this.msg.clear();

			if (this.submsg)
			{
				this.submsg.clear();
			}
		}
	}

	function tag_msgon( elm = null )
	{
		if (!this.msgWinState)
		{
			this.msgWinState = true;
			local time = this.isSkip() ? 0 : ::getint(elm, "time", this.MSGFADETIME);
			this.msgon(time);
			this.doShowFace();
			this.sysSync();
		}
	}

	function tag_msgoff( elm = null )
	{
		if (this.msgWinState)
		{
			this.msgWinState = false;
			this.doHideFace();
			local time = this.isSkip() ? 0 : ::getint(elm, "time", this.MSGFADETIME);
			this.msgoff(time);
			this.sysSync();
		}
	}

	function tag_er( elm = null )
	{
		if (this.msg)
		{
			this.msg.clear();
		}

		if (this.submsg)
		{
			this.submsg.clear();
		}
	}

	function tag_resetwait( elm )
	{
		this.resetWait();
	}

	function tag_wait( elm )
	{
		this.delayinit();
		local waittime;

		if (("mode" in elm) && elm.mode == "until")
		{
			if (this.timeOrigin == null)
			{
				return;
			}

			waittime = this.timeOrigin + ::getint(elm, "time") - this.getCurrentTick();

			if (waittime < 6)
			{
				return;
			}
		}
		else
		{
			waittime = ::getint(elm, "time");
		}

		this.waitTime(waittime, true);
	}

	function tag_waituntil( elm )
	{
		this.delayinit();

		if (this.timeOrigin != null)
		{
			local waittime = this.timeOrigin + ::getint(elm, "time") - this.getCurrentTick();

			if (waittime < 6)
			{
				return;
			}

			if (this.waitTime(waittime, true) == 1)
			{
				this.timeOrigin = null;
			}
		}
	}

	function tag_envupdate( elm )
	{
		this.env.envUpdate(elm);
	}

	function tag_delaydone( elm )
	{
		this.delaydone();
	}

	function tag_delaycancel( elm )
	{
		this.delaycancel();
	}

	function tag_td( elm )
	{
		local labels = [];

		foreach( name, value in elm )
		{
			labels.append([
				::toint(::tonumber(value) * 60 / 1000),
				name
			]);
		}

		labels.sort(function ( a, b )
		{
			return a[0] - b[0];
		});
		local l = [];

		foreach( v in labels )
		{
			l.append(v[0]);
			l.append(v[1]);
		}

		this.entryDelayLabels(l);
	}

	function tag_sysmovie( elm )
	{
		if (!("eval" in elm) || this.eval(elm.eval))
		{
			this.cancelPlayMode(16);
			this.voice.stop();
			this.sync();
			local filename = ::getval(elm, "file", ::getval(elm, "storage"));

			if (filename != null)
			{
				if (this.PLAY_MOVIE_ON_SKIP || !this.isSkip())
				{
					this.env.pauseMus(true);
					this.playMovie(filename, this.input);
					::setRecordEnable(this.recordEnable);
					this.printf("\x00e9\x008c\x00b2\x00e7\x0094\x00bb\x00e7\x008a\x00b6\x00e6\x0085\x008b:%s\n", this.recordEnable);
					this.env.restartMus();
				}

				local fname = "movie_" + filename.tolower();

				if (this.isExistSystemFlag(fname))
				{
					this.setSystemFlag(fname, true);
				}
			}
		}
	}

	function tag_eyecatch( elm = null )
	{
		this.cancelPlayMode(32);
	}

	function tag_l( elm )
	{
		this.delayinit();

		if (!this.isSkip())
		{
			this.waitKey();
		}
	}

	function tag_recordset( elm )
	{
		this.printf("setrecord\x00e5\x0091\x00bc\x00e3\x0081\x00b3\x00e5\x0087\x00ba\x00e3\x0081\x0097\n");

		if ("mode" in elm)
		{
			this.recordEnable = ::toint(elm.mode);
			::setRecordEnable(this.recordEnable);
			this.printf("\x00e9\x008c\x00b2\x00e7\x0094\x00bb\x00e7\x008a\x00b6\x00e6\x0085\x008b:%s:%s\n", elm.mode, this.recordEnable);
		}
	}

	function _interrupt()
	{
		::EnvPlayer._interrupt();
		this.tag_msgoff();
		this.selectPanel = null;
		this.selectType = null;
		this.selectUpdateFlag = false;
		this.setMsgType();
		this.onClear();
		this.cancelMsgMode();
	}

	function interruptHistoryJump( pos )
	{
		if (pos != null)
		{
			this.interrupt(this.HistoryJumpException(pos));
		}
	}

	function interruptPrevJump()
	{
		local l = this.histories.len();
		this.printf("prev:%d\n", l);

		if (l > 0)
		{
			for( local i = l - 1; i >= 0; i-- )
			{
				local h = this.histories[i];

				if (h[5])
				{
					this.interruptHistoryJump(h[2] - this.histories[0][2]);
				}
			}
		}

		if (this.canPrevToStart())
		{
			local scene = {
				storage = this.getStorage(this.sceneStart),
				target = this.getLabel(this.sceneStart),
				mode = this.sceneMode
			};

			if (this.sceneCur != null && this.sceneCur != "")
			{
				scene.cur <- this.sceneCur;
			}

			if (this.sceneArg != null && this.sceneArg != "")
			{
				scene.arg <- this.sceneArg;
			}

			this.exitGame("restart", scene);
		}
	}

	function interruptNextJump()
	{
		this.interrupt(this.NextJumpException());
	}

	function interruptOutlineChange()
	{
		if (this.canOutline())
		{
			this.interrupt(this.OutlineChangeException());
		}
	}

	function interruptRedraw()
	{
		if (!this.outlineMode)
		{
			this.interrupt(this.RedrawException());
		}
	}

	function canHideMsg()
	{
		return this.msgWinState || this.canHideSelect();
	}

	function checkHideMsg( hideKey = 0 )
	{
		if (this.checkKeyPressed(this.selectKey | hideKey))
		{
			return true;
		}
	}

	function doHideMsg( hideKey = 0 )
	{
		this.sysSync();

		while (true)
		{
			local ret;

			if (!this.checkDebug(this.input) && this.checkHideMsg(hideKey))
			{
				return false;
			}

			if (this.checkKeyPressed(this.hideCancelCheckSkip))
			{
				return true;
			}

			if (this.hideCommands != null)
			{
				foreach( info in this.hideCommands )
				{
					local key;
					key = info.key;
					key = info.ckey;
					key = info.fkey;
					key = info.gesture;

					if (("key" in info) && this.checkKeyPressed(key) || ("ckey" in info) && this.checkComboKeyPressed(key) || ("fkey" in info) && ::funcKeyPressed(key) || ("gesture" in info) && this.checkGesture(key))
					{
						local eval = this.getval(info, "eval");

						if (eval == null || this.eval(eval))
						{
							local func = this.getval(info, "func");

							if (typeof func == "string")
							{
								if (func in this)
								{
									func = this[func];
								}
							}

							if (typeof func == "function")
							{
								local hideMsg = ::getbool(info, "hide", true);

								if (hideMsg)
								{
									this.stopAllVoice();
									this.env.pauseMus();
								}

								local br = ::getbool(info, "breakHide", false);

								if (!hideMsg || br)
								{
									this.cancelMsgMode();
								}

								local ret = func(key);

								if (ret != null)
								{
									this.exitGame(ret);
								}

								if (hideMsg)
								{
									this.env.restartMus();
								}

								if (!hideMsg && !br)
								{
									this.enterMsgMode();
								}

								if (br)
								{
									return;
								}
							}
							else
							{
								this.printf("warn: not function:%s\n", func);
							}
						}
					}
				}
			}

			this.sysSync();
		}
	}

	skipStartTick = null;
	skipStartTick2 = null;
	function cancelForceSkip( user = false )
	{
		this.forceSkip = 0;
		this.checkPlayMode(false);
	}

	function startAuto()
	{
		::EnvPlayer.sync();
		this.autoMode = true;

		if (this.SWITCH_AUTO_SKIP || this.playStatus == 0)
		{
			this.playStatus = 1;
			this.checkPlayMode(true);
		}
	}

	function stopAuto()
	{
		this.autoMode = false;

		if (this.playStatus == 1)
		{
			this.playStatus = 0;
			this.checkPlayMode(true);
		}
	}

	function startSkip()
	{
		this.sync();
		this.playStatus = 2;

		if (this.SWITCH_AUTO_SKIP)
		{
			this.autoMode = false;
		}

		this.checkPlayMode(true);

		if (this.skipMode == 1)
		{
			this.skipMode = 2;
		}
	}

	function stopSkip()
	{
		if (this.playStatus == 2)
		{
			this.playStatus = this.autoMode ? 1 : 0;
			this.checkPlayMode(true);
		}
	}

	function checkSkipStop()
	{
		if (this.longAutoKey != null && this.autoStartTick != null)
		{
			if (!this.checkKey(this.longAutoKey))
			{
				this.autoStartTick = null;
			}
		}

		switch(this.forceSkip)
		{
		case 2:
			if (!this.checkKey(this.forceUnreadSkipKey))
			{
				this.forceSkip = 0;
				this.checkPlayMode(true);
				this.skipStartTick2 = null;
				return true;
			}

			break;

		case 1:
			if (!this.checkKey(this.forceSkipKey))
			{
				this.forceSkip = 0;
				this.checkPlayMode(true);
				this.skipStartTick = null;
				return true;
			}

			break;
		}

		switch(this.playStatus)
		{
		case 2:
			if (this.checkKeyPressed(this.skipCancelKey) || this.cancelSkipFlag & 1 && this.checkKeyPressed(this.selectKey))
			{
				this.stopSkip();
				return true;
			}

			break;

		case 1:
			if (this.checkKeyPressed(this.autoCancelKey) || this.autoFuncKey != null && ::funcKeyPressed(this.autoFuncKey) || this.cancelAutoFlag & 1 && this.checkKeyPressed(this.selectKey))
			{
				this.stopAuto();
				return true;
			}

			break;
		}

		return false;
	}

	function checkSkip()
	{
		if (this.checkSkipStop())
		{
			return true;
		}

		if (!this.commandEnabled)
		{
			return false;
		}

		if (this.forceSkip == 0)
		{
			if (this.forceUnreadSkipKey != null)
			{
				if (this.checkKey(this.forceUnreadSkipKey))
				{
					if (this.skipStartTick2 == null)
					{
						this.skipStartTick2 = ::getCurrentTick();
					}

					if (::getCurrentTick() - this.skipStartTick2 >= this.FORCESKIP_DELAY)
					{
						this.forceSkip = 2;
						this.checkPlayMode(true);

						if (this.skipMode == 1)
						{
							this.skipMode = 2;
						}

						return true;
					}
				}
				else
				{
					this.skipStartTick2 = null;
				}
			}

			if (this.forceSkipKey != null)
			{
				if (this.checkKey(this.forceSkipKey))
				{
					if (this.skipStartTick == null)
					{
						this.skipStartTick = ::getCurrentTick();
					}

					if (::getCurrentTick() - this.skipStartTick >= this.FORCESKIP_DELAY)
					{
						if (this.curReaded)
						{
							this.forceSkip = 1;
							this.checkPlayMode(true);

							if (this.skipMode == 1)
							{
								this.skipMode = 2;
							}

							return true;
						}
						else
						{
							this.printf("can\'t start skip(unread)\n");
							this.skipStartTick = null;
						}
					}
				}
				else
				{
					this.skipStartTick = null;
				}
			}
		}

		switch(this.playStatus)
		{
		case 2:
			if (this.SWITCH_AUTO_SKIP && (this.checkKeyPressed(this.autoKey) || this.autoFuncKey != null && ::funcKeyPressed(this.autoFuncKey)))
			{
				this.startAuto();
				return true;
			}

			break;

		case 1:
			if (this.checkKeyPressed(this.skipKey))
			{
				this.startSkip();
				return true;
			}

			break;

		case 0:
			if (this.clickSkipEnabled && this.checkKeyPressed(this.skipKey))
			{
				this.startSkip();
				return true;
			}

			if (this.checkKeyPressed(this.autoKey) || this.autoFuncKey != null && ::funcKeyPressed(this.autoFuncKey))
			{
				this.startAuto();
				return true;
			}

			if (this.longAutoKey != null)
			{
				if (this.checkKey(this.longAutoKey))
				{
					if (this.autoStartTick == null)
					{
						this.autoStartTick = ::getCurrentTick();
					}

					if (::getCurrentTick() - this.autoStartTick >= this.LONGAUTO_DELAY)
					{
						this.startAuto();
						return true;
					}
				}
			}

			break;
		}

		if (this.skipMode == 1)
		{
			if (this.checkKeyPressed(this.cancelKey) || this.checkKeyPressed(this.selectKey) && this.enableLeftBeginSkip)
			{
				this.skipMode = 2;
				return true;
			}
		}

		return false;
	}

	function prepareCommand()
	{
		this.delaydone();
		this.stopTransition();
	}

	function hideMessage( hideKey = 0 )
	{
		this.enterMsgMode();

		if (this.doHideMsg(hideKey))
		{
			this.checkSkip();
		}

		this.cancelMsgMode();
	}

	function _checkCommand( commands )
	{
		if (this.hideKey != null && this.checkKeyPressed(this.hideKey))
		{
			if (this.canHideMsg())
			{
				this.onExecuteCommand();
				this.prepareCommand();
				this.hideMessage(this.hideKey);
				return this.hideKey;
			}
		}
		else if (commands != null)
		{
			foreach( info in commands )
			{
				local key;
				key = info.key;
				key = info.ckey;
				key = info.fkey;
				key = info.gesture;

				if (("key" in info) && this.checkKeyPressed(key) || ("ckey" in info) && this.checkComboKeyPressed(key) || ("fkey" in info) && ::funcKeyPressed(key) || ("gesture" in info) && this.checkGesture(key))
				{
					local eval = this.getval(info, "eval");

					if (eval == null || this.eval(eval))
					{
						local func = this.getval(info, "func");

						if (typeof func == "string")
						{
							if (func in this)
							{
								func = this[func];
							}
						}

						if (typeof func == "function")
						{
							this.onExecuteCommand();
							this.prepareCommand();
							local hideMsg = ::getbool(info, "hide", true);
							local hideSelect = ::getbool(info, "hideSelect", true);
							this.stopAllVoice();

							if (hideMsg)
							{
								this.env.pauseMus();
								this.enterMsgMode(hideSelect);
							}

							local ret = func(key);

							if (ret != null)
							{
								this.exitGame(ret);
							}

							if (hideMsg)
							{
								this.cancelMsgMode();
							}

							this.env.restartMus();
							return key;
						}
						else
						{
							this.printf("warn: not function:%s\n", func);
						}
					}
				}
			}
		}

		return false;
	}

	function checkMsgCommand()
	{
		if (this.msg.visible && this.msg._work())
		{
			this.sync();
			return true;
		}
	}

	function checkCommand()
	{
		return this.selectPanel == null && this.commandEnabled && (this.checkDebug(this.input) || this.checkMsgCommand() || this._checkCommand(this.playCommands));
	}

	function checkSelectCommand()
	{
		return this.selectCanCommand && this._checkCommand(this.selectCommands);
	}

	function checkClick( force = false )
	{
		return (force || this.clickSkipEnabled) && (this.checkKeyPressed(this.selectKey) || this.checkKeyPressed(this.cancelKey) || this.isSkip() && this.skipSpeed == 0);
	}

	function calcActionTick( diff )
	{
		return diff * this.effectSpeedMag;
	}

	function sync()
	{
		::EnvPlayer.sync();

		if (this.isSystemPlayModeDisable())
		{
			this.checkSkipStop();
		}
		else
		{
			this.checkSkip();
		}
	}

	function updateSync()
	{
		::EnvPlayer.updateSync();

		if ((this.NOSCREENSAVER_ALWAYS || this.playStatus > 0) && this.screenSaver == 0)
		{
			::automaticTick();
		}
	}

	function playSync()
	{
		this.updateDelay();
		this.doDelay();
		this.updateSync();
	}

	function textSync()
	{
		this.workCommandExecuted = false;
		this.playSync();

		if (!this.checkSkip())
		{
			if (this.checkCommand())
			{
				return this.workCommandExecuted;
			}
			else
			{
				return this.checkClick();
			}
		}

		return false;
	}

	function beginEnvTrans( msgchange )
	{
		if (this.skipMode == 2)
		{
			this.stopTransition();
			this.transMode = 1;

			if (msgchange != null)
			{
				if (msgchange)
				{
					this.tag_msgon();
				}
				else
				{
					this.tag_msgoff();
				}
			}
		}
		else
		{
			this.setupTransition(msgchange);
		}
	}

	function isNormalPlay()
	{
		return this.sceneMode == 0;
	}

	function cmdToTitle( ... )
	{
		if (this.confirm(this.isNormalPlay() ? "YESNO_TITLE" : "YESNO_TITLE_NOSAVE", "no"))
		{
			if (this instanceof ::MotionPanelLayer)
			{
				this.playWait("hide");
			}

			this.exitGame("totitle");
		}
	}

	function cmdToTitle2( ... )
	{
		if (this.confirm(this.isNormalPlay() ? "YESNO_TITLE" : "YESNO_TITLE_NOSAVE", "no"))
		{
			if (this instanceof ::MotionPanelLayer)
			{
				this.playWait("hide");
			}

			this.exitGame("totitle2");
		}
	}

	function cmdQuit( ... )
	{
		if (this.confirm("YESNO_QUIT", "no"))
		{
			if (this instanceof ::MotionPanelLayer)
			{
				this.playWait("hide");
			}

			this.exitGame("quit");
		}
	}

	function cmdQuickSave( ... )
	{
		if (!this.CONFIRM_QSAVE || this.confirm("YESNO_QSAVE", "no"))
		{
			this.doQuickSave(this.getSaveData(), this.getSaveScreenCapture(), false);
		}
	}

	function cmdQuickLoad( ... )
	{
		local scene = this.doQuickLoad();

		if (scene != null)
		{
			if (this.confirm("YESNO_QLOAD", "no"))
			{
				if (this instanceof ::MotionPanelLayer)
				{
					this.playWait("hide");
				}

				this.exitGame("restart", scene);
			}
		}
	}

	function cmdAutoLoad( ... )
	{
		local scene = this.doAutoLoad();

		if (scene != null)
		{
			if (this.confirm("YESNO_ALOAD"))
			{
				if (this instanceof ::MotionPanelLayer)
				{
					this.playWait("hide");
				}

				this.exitGame("restart", scene);
			}
		}
	}

	function cmdAutoSave( ... )
	{
		this.execAutoSave();
	}

	function cmdPrev( ... )
	{
		if (this.canPrevJump())
		{
			if (this.confirm("YESNO_PREV", "no"))
			{
				if (this instanceof ::MotionPanelLayer)
				{
					this.playWait("hide");
				}

				this.interruptPrevJump();
			}
		}
	}

	function cmdNext( ... )
	{
		if (this.canJump())
		{
			if (this.confirm("YESNO_NEXT", "no"))
			{
				if (this instanceof ::MotionPanelLayer)
				{
					this.playWait("hide");
				}

				this.interruptNextJump();
			}
		}
	}

	function cmdAuto( ... )
	{
		if (this.autoMode)
		{
			this.stopAuto();
			return true;
		}
		else if (this.playStatus == 0 || this.playStatus == 2 && this.SWITCH_AUTO_SKIP)
		{
			this.startAuto();
			return true;
		}

		return false;
	}

	function cmdSkip( ... )
	{
		if (this.playStatus == 2)
		{
			this.stopSkip();
			return true;
		}
		else if (this.playStatus == 1 || this.playStatus == 0 && this.clickSkipEnabled)
		{
			this.startSkip();
			return true;
		}

		return false;
	}

	function cmdVoice( ... )
	{
	}

	function cmdConfig( ... )
	{
		this.openConfig();
	}

	function cmdSave( ... )
	{
		this.openSave();
	}

	function cmdLoad( ... )
	{
		local scene = this.openLoad();

		if (scene != null)
		{
			this.exitGame("restart", scene);
		}
	}

	function cmdHistory( ... )
	{
		if (this.getHistoryLines() > 0)
		{
			local pos = this.openHistory();
			this.stopVoice();

			if (typeof pos == "integer")
			{
				this.interruptHistoryJump(pos);
			}
		}
	}

	function cmdSysMenu( key )
	{
		local arg;

		do
		{
			arg = this.openSysMenu(arg);

			switch(arg)
			{
			case "save":
				this.cmdSave(key);
				break;

			case "load":
				this.cmdLoad(key);
				break;

			case "config":
				this.cmdConfig(key);
				break;

			case "history":
			case "backlog":
				this.cmdHistory(key);
				break;
			}
		}
		while (arg != null && arg != "close");
	}

	function openDebugMenu()
	{
		local sel;
		sel = ::select([
			"\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e6\x0093\x008d\x00e4\x00bd\x009c",
			"\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e9\x0081\x00b8\x00e6\x008a\x009e",
			"\x00e6\x0083\x0085\x00e5\x00a0\x00b1\x00e8\x00a1\x00a8\x00e7\x00a4\x00ba",
			"\x00e5\x0089\x008d\x00e3\x0081\x00ae\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e8\x0082\x00a2",
			"\x00e6\x00ac\x00a1\x00e3\x0081\x00ae\x00e9\x0081\x00b8\x00e6\x008a\x009e\x00e8\x0082\x00a2",
			"\x00e3\x0082\x00bf\x00e3\x0082\x00a4\x00e3\x0083\x0088\x00e3\x0083\x00ab\x00e3\x0081\x00ab\x00e6\x0088\x00bb\x00e3\x0082\x008b"
		], null, 32);

		while (sel != null)
		{
			switch(sel)
			{
			case 3:
				this.cmdPrev();
				break;

			case 4:
				this.cmdNext();
				break;

			default:
				this.debugMenu(this, sel);
			}
		}
	}

	function checkMsgOver( storage )
	{
		local cur = 0;
		local obj;
		local curLine = 0;
		local sub = this.submsg && this.languageId != this.subLanguageId ? this.submsg : null;

		try
		{
			this.loadScene(storage);
		}
		catch( e )
		{
			this.printf("failed to open %s:%s\n", storage, e.message);
		}

		local sumDelay = 0;
		obj = this.getLine(cur++);

		while (obj != null)
		{
			if (typeof obj == "array")
			{
				if (typeof obj[0] == "integer")
				{
					curLine = obj[4];
				}
			}
			else if (typeof obj == "integer")
			{
				local text = this.getTextInfo(obj);
				local txt = ::parseLangText(text, "text");
				this.msg.clear();
				this.msg.write(txt, 1, 0, text.indent);

				if (this.msg.getRenderOver())
				{
					this.printf("%s:%d msg area over:%d\n%s\n", storage, curLine, obj, txt[this.languageId]);
				}

				sumDelay += this.msg.getRenderDelay();

				if (sub)
				{
					sub.clear();
					sub.write(txt, 0, 0, text.indent);

					if (sub.getRenderOver())
					{
						this.printf("%s:%d msg area over:%d\n%s\n", storage, curLine, obj, txt[this.subLanguageId]);
					}
				}
			}
		}

		return sumDelay;
	}

	function checkMsgOverAll()
	{
		this.clear();
		local dialog = ::ConfirmDialog();
		this.msgon();
		dialog.show("");
		local sumDelay = 0;

		foreach( scene in this.getSceneList() )
		{
			local storage = scene.storage + scene.target;
			dialog.setMessage(storage);
			dialog.work();
			sumDelay += this.checkMsgOver(storage);
		}

		this.printf("sumDelay: %f\n", sumDelay);
		dialog.inform("check done");
	}

	function onMsgMode( msgMode )
	{
	}

	function onPlayMode( playMode, prevPlayMode, user = false )
	{
	}

	function onUpdateConfig()
	{
	}

	function onOutlineMode( mode )
	{
	}

	function onClear()
	{
	}

	function onLoadScene( type, curSceneName, prevSceneName )
	{
	}

	function onRestore( obj )
	{
	}

	function onChangeMusic( filename )
	{
	}

	function onSceneStart( saveData )
	{
	}

	function onSceneNext()
	{
	}

	function onAfterName( text, disp )
	{
	}

	function onAfterMsg( text )
	{
	}

	function onAfterPage( text )
	{
	}

	function onAfterLine( text )
	{
	}

	function onJump( start )
	{
	}

	function onHistoryJump( start )
	{
	}

	function onExit( start )
	{
	}

	function onSelectStart( selinfo, seltype )
	{
	}

	function onSelectEnd( selinfo, result, seltype )
	{
	}

	function onSelectException()
	{
	}

	function onAutoSave( start )
	{
	}

}

function createGamePlayer( owner, scene )
{
	return ::ScenePlayer(owner);
}

