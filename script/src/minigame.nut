this.BASESCALE = 6;
class this.CharaObject extends this.Object
{
	owner = null;
	name = "";
	pic = null;
	bx = 0;
	by = 0;
	x = 0;
	y = 0;
	done = false;
	constructor( owner, name, info, level = 0 )
	{
		::Object.constructor();
		this.owner = owner.weakref();
		this.name = name;
		this.pic = owner.createSprite(info, level);
		this.pic.visible = true;
		this.done = false;
	}

	function destructor()
	{
		this.pic.visible = false;
		::Object.destructor();
	}

	function initPos( x, y )
	{
		this.bx = x * 8;
		this.by = y * 8;
		this.updatePos();
	}

	function updatePos()
	{
		this.pic.setOffset(-(this.bx + this.x), -(this.by - this.y));
	}

	function setPos( x, y )
	{
		this.x = x;
		this.y = y;
		this.updatePos();
	}

	function setPattern( n )
	{
		this.pic.setPattern(n);
	}

	function work( tick )
	{
		if (!this.done)
		{
			try
			{
				this._work(tick);
			}
			catch( e )
			{
				::printException(e);
				::printCallStack();
				this.done = true;
			}
		}

		return !this.done;
	}

	function end()
	{
		this.done = true;
	}

	workState = 0;
	function _work( tick )
	{
	}

}

class this.KazumaObject extends this.CharaObject
{
	pattern = [
		[
			1,
			1,
			4,
			4,
			0,
			0
		],
		[
			1,
			1,
			4,
			4,
			0,
			0
		],
		[
			8,
			1,
			4,
			4,
			0,
			0
		],
		[
			13,
			1,
			4,
			4,
			0,
			0
		],
		[
			20,
			1,
			4,
			4,
			0,
			0
		],
		[
			25,
			1,
			4,
			4,
			0,
			0
		]
	];
	blink = false;
	blinkend = null;
	state = 0;
	force = 0;
	y_prev = 0;
	constructor( owner )
	{
		this.CharaObject.constructor(owner, "kazuma", this.pattern, 1);
	}

	function checkInput( input )
	{
		if (this.state == 0)
		{
			if (input.keyPressed(32))
			{
				this.owner.speed = 1;
			}
			else if (input.keyPressed(16))
			{
				this.owner.speed = 2;
			}
			else if (input.keyPressed(this.KEY_OK))
			{
				this.state = 1;
				this.force = 10;
				this.sysse.play("mgse01");
			}
		}
	}

	function setBlink( tick )
	{
		this.blink = true;
		this.blinkend = tick + 60;
	}

	function _work( tick )
	{
		if (this.state == 1)
		{
			local y_temp = this.y;
			this.y += this.y - this.y_prev + this.force;
			this.y_prev = y_temp;
			this.force = -1;

			if (this.y <= 0)
			{
				this.state = 0;
				this.y = 0;
				this.y_prev = 0;
			}
		}

		local pat = tick / 30 % 2;

		if (this.state == 0)
		{
			this.setPattern((this.owner.speed - 1) * 2 + pat);
		}
		else
		{
			this.setPattern(4 + pat);
		}

		if (this.blink)
		{
			this.pic.visible = tick / 5 % 2 == 0;

			if (tick > this.blinkend)
			{
				this.blink = false;
				this.pic.visible = true;
			}
		}

		this.updatePos();
	}

}

class this.TextObject extends this.CharaObject
{
	TEXT_SIZE = 14;
	TEXT_COLOR = 4294967295;
	pattern = [
		[
			1,
			34,
			3,
			4,
			0,
			0
		],
		[
			5,
			34,
			3,
			4,
			0,
			0
		],
		[
			12,
			35,
			4,
			4,
			-0.5,
			0
		],
		[
			17,
			35,
			4,
			5,
			-0.5,
			0
		],
		[
			22,
			35,
			4,
			5,
			-0.5,
			0
		],
		[
			27,
			35,
			4,
			5,
			-0.5,
			0
		]
	];
	text = null;
	textObj = null;
	tx = 0;
	ty = 0;
	state = 0;
	endtick = null;
	constructor( owner, no, text )
	{
		this.CharaObject.constructor(owner, "txt" + no, this.pattern);
		this.text = text;
		local fsize = 14.0;
		local data = ::BasePicture.findFont(fsize * this.BASESCALE);
		local size = ::getFontSize(data);

		if (data == null || size == 0)
		{
			throw this.Exception("faild to load font");
		}

		this.textObj = ::Indicator(owner.txlay2, data);
		this.textObj.setFontColor(this.ARGB2RGBA(this.TEXT_COLOR));
		this.textObj.print(text);
		this.textObj.visible = true;
		this.textObj.fontScale = fsize / size;
		this.tx = (8 * 3 - this.textObj.width) / 2 + 1;
		this.ty = (8 * 3 - this.textObj.height) / 2 - 2;
	}

	function updatePos()
	{
		this.CharaObject.updatePos();

		if (this.textObj != null)
		{
			this.textObj.setCoord(this.tx + this.bx + this.x, this.ty + this.by - this.y);
		}
	}

	function setEnd( tick )
	{
		this.state = 2;
		this.endtick = tick + 60;
	}

	function _work( tick )
	{
		if (this.state == 0 || this.state == 1)
		{
			this.x -= this.owner.speed;

			if (this.bx + this.x < -20)
			{
				this.state = 3;
			}
		}
		else if (this.state == 2)
		{
			this.textObj.visible = this.pic.visible = tick / 5 % 2 == 0;

			if (tick > this.endtick)
			{
				this.state = 3;
			}
		}
		else if (this.state == 3)
		{
			this.end();
		}

		local pat = tick / 30 % 2;
		this.setPattern(pat);
		this.updatePos();
	}

	function checkPos()
	{
		if (this.state == 0)
		{
			local kazuma = this.owner.kazuma;
			local sx = this.bx + this.x;
			local sy = this.by - this.y;
			local x = kazuma.bx + kazuma.x;
			local y = kazuma.by - kazuma.y;

			if (x >= sx - 2 * 8 && x <= sx + 2 * 8 && y >= sy - 2 * 8 && y <= sy + 2 * 8)
			{
				this.state = 1;
				return true;
			}
		}

		return false;
	}

}

class this.CrowdObject extends this.CharaObject
{
	pattern = [
		[
			7,
			8,
			4,
			4,
			0,
			0
		],
		[
			15,
			8,
			4,
			4,
			0,
			0
		],
		[
			23,
			8,
			4,
			4,
			0,
			0
		]
	];
	XMAX = 20;
	speed = 1;
	constructor( owner, no )
	{
		this.CharaObject.constructor(owner, "crowd" + no, this.pattern);
		this.initPos(true);
	}

	function initPos( init = false )
	{
		this.speed = 0.5;
		this.y = 3;

		if (init)
		{
			this.x = 10;
		}
		else
		{
			this.x = -4;
		}

		this.updatePos();
	}

	function _work( tick )
	{
		this.x += this.speed;

		if (this.x >= this.XMAX)
		{
			this.initPos();
		}
	}

}

class this.AnimPicture extends ::LayerPicture
{
	constructor( lay, image )
	{
		::LayerPicture.constructor(lay, image);
		this.clearImageRange();
		this.patterns = [];
	}

	patterns = null;
	lastpat = null;
	function assignImage( info )
	{
		local l = info[0];
		local t = info[1];
		local r = l + info[2];
		local b = t + info[3];
		local x = info[4];
		local y = info[5];
		this.assignImageRange(l * 8, t * 8, r * 8, b * 8, x * 8, y * 8);
	}

	function addPattern( info )
	{
		this.patterns.append(info);
	}

	function setPattern( n )
	{
		if (n != this.lastpat && n < this.patterns.len())
		{
			this.clearImageRange();

			foreach( i in this.patterns[n] )
			{
				this.assignImage(i);
			}

			this.lastpat = n;
		}
	}

}

class this.MiniGameFunction extends this.Object
{
	HP_SUB_FAIL = 10;
	HP_SUB_FRAME = 120;
	ADD_PACE = 60;
	BASEW = 28;
	BASEH = 17;
	BASEWIDTH = 28 * 8;
	BASEHEIGHT = 17 * 8;
	BASEOFFX = 14 * 8;
	BASEOFFY = 8.5 * 8;
	input = null;
	rand = null;
	backbase = null;
	partsImage = null;
	baseImage = null;
	baselay = null;
	bglay = null;
	splay = null;
	txlay = null;
	txlay2 = null;
	splay2 = null;
	iflay = null;
	bgbase = null;
	bar = null;
	hpBar = null;
	textBar = null;
	textBarText = null;
	entryText = null;
	resultOK = null;
	resultOKlen = 0;
	function splitText( text )
	{
		local ret = [];
		local s = 0;
		local l = text.len();

		while (s < l)
		{
			local n = text.mbnext(s);
			local ch = text.substr(s, n);
			ret.append(ch);
			s += n;
		}

		return ret;
	}

	constructor( selinfo, input )
	{
		::Object.constructor();
		this.input = input;
		this.rand = ::Random();
		this.textBarText = [];
		local entry = "entry" in selinfo ? selinfo.entry : "\x00e3\x0081\x0082\x00e3\x0081\x0084\x00e3\x0081\x0086\x00e3\x0081\x0088\x00e3\x0081\x008a\x00e3\x0081\x008b\x00e3\x0081\x008d\x00e3\x0081\x008f\x00e3\x0081\x0091\x00e3\x0081\x0093";
		this.entryText = this.splitText(entry);
		local r = "result" in selinfo ? selinfo.result : "\x00e3\x0081\x0082\x00e3\x0081\x0084\x00e3\x0081\x0086";
		this.resultOK = this.splitText(r);
		this.resultOKlen = this.resultOK.len();
		this.printf("entry:%s result:%s\n", entry, r);
	}

	function gameOpen()
	{
		this.backbase = ::BackLayer(this.getScreen(), 4278190080, 99999999 + 100);
		this.backbase.visible = true;
	}

	function gameClose()
	{
		this.clear();
		this.backbase = null;
	}

	kazuma = null;
	textlist = null;
	textno = 0;
	speed = 1;
	function clear()
	{
		if (this.kazuma)
		{
			this.kazuma.end();
			this.kazuma = null;
		}

		foreach( text in this.textlist )
		{
			if (text)
			{
				text.end();
			}
		}

		this.textlist.clear();

		if (this.gameTelop)
		{
			this.gameTelop.visible = false;
			this.gameTelop = null;
		}

		this.hpBar = null;
		this.textBar = null;

		if (this.textBarText)
		{
			this.textBarText.clear();
		}

		this.textBarText = null;
		this.bar = null;
		this.bgbase = null;
		this.bglay = null;
		this.splay = null;
		this.splay2 = null;
		this.txlay = null;
		this.txlay2 = null;
		this.iflay = null;
		this.partsImage = null;
		this.baselay = null;
		this.baseImage = null;
	}

	function createLayer( priority = 0 )
	{
		local lay = ::Layer(this.getScreen());
		lay.setPriority(priority);
		lay.setScale(this.BASESCALE, this.BASESCALE);
		lay.setOffset(this.BASEOFFX * this.BASESCALE, this.BASEOFFY * this.BASESCALE);
		lay.setClip(0, 0, this.BASEWIDTH, this.BASEHEIGHT);
		return lay;
	}

	function createParts( lay, info )
	{
		local pic = ::AnimPicture(lay, this.partsImage);
		pic.addPattern(info);
		pic.setPattern(0);
		pic.visible = true;
		return pic;
	}

	function createAnim( lay, info )
	{
		local pic = ::AnimPicture(lay, this.partsImage);

		foreach( i in info )
		{
			pic.addPattern([
				i
			]);
		}

		pic.setPattern(0);
		pic.visible = true;
		return pic;
	}

	function createSprite( info, level = 0 )
	{
		return this.createAnim(level ? this.splay2 : this.splay, info);
	}

	function showParts()
	{
		local baseData = this.loadImageData(this.BGFILE);
		this.baseImage = ::Image(baseData);
		this.baselay = ::Layer(this.getScreen());
		this.bgbase = ::LayerPicture(this.baselay, this.baseImage);
		this.bgbase.setOffset(this.baseImage.width / 2, this.baseImage.height / 2);
		this.bgbase.visible = true;
		local imageData = this.loadImageData("gameparts");
		this.partsImage = ::Image(imageData);
		this.bglay = this.createLayer(1);
		this.splay = this.createLayer(2);
		this.txlay2 = this.createLayer(3);
		this.splay2 = this.createLayer(4);
		this.iflay = this.createLayer(5);
		this.txlay = this.createLayer(6);
		this.bar = this.createParts(this.iflay, [
			[
				19,
				27,
				23,
				4,
				2,
				0
			]
		]);
		this.hpBar = ::LayerPicture(this.iflay, this.partsImage);
		this.hpBar.clearImageRange();
		this.hpBar.visible = true;
		local hpl = 22 * 8;
		local hpt = 25 * 8;
		local hpr = hpl + 8;
		local hpb = hpt + 6;
		this.hpBar.assignImageRange(hpl, hpt, hpr, hpb, 0, 0);
		this.hpBar.setOffset(-(5 * 8), -5);
		this.setHP(this.hp);
		this.textBar = ::LayerPicture(this.iflay, this.partsImage);
		this.textBar.clearImageRange();
		this.textBar.visible = true;
		this.textlist = [];
		this.textno = 0;
	}

	function createText( text )
	{
		local t = this.TextObject(this, this.textno++, text);
		t.initPos(28, 5);
		return t;
	}

	function addText()
	{
		local n = this.rand.intrandom(this.entryText.len() - 1);
		this.textlist.append(this.createText(this.entryText[n]));
	}

	function addResult( text )
	{
		local baseL = 20 * 8;
		local baseT = 25 * 8;
		local baseS = 8 * 1.5;
		local baseR = baseL + baseS;
		local baseB = baseT + baseS;
		local baseX = 5 * 8;
		local baseY = 2 * 8;
		local baseW = baseS + 2;
		this.textBar.assignImageRange(baseL, baseT, baseR, baseB, baseX + this.resultnum * baseW, baseY);
		local fsize = 8.0;
		local data = ::BasePicture.findFont(fsize * this.BASESCALE);
		local size = ::getFontSize(data);
		local t = ::Indicator(this.txlay, data);
		t.setFontColor(this.ARGB2RGBA(4294967295));
		t.print(text);
		t.fontScale = fsize / size;
		t.setCoord(baseX + this.resultnum * baseW + 2, baseY + 2);
		t.visible = true;
		this.textBarText.append(t);
		this.resultnum++;
	}

	function setHP( hp )
	{
		if (this.hpBar)
		{
			if (hp < 0)
			{
				hp = 0;
			}

			this.hpBar.setScale(hp * 19 / 100.0, 1.0);
		}
	}

	STARTSE = "miniME01";
	GAMEBGM = "BGM_MINI01";
	BGFILE = "ACH_BG";
	CLEAR_MEDAL = "md34";
	gameState = -1;
	gameTick = 0;
	gameResult = 0;
	resultnum = 0;
	hp = 0;
	addTick = 0;
	hpTick = 0;
	startTick = 60 * 3;
	gameTelop = null;
	function createTelop( no )
	{
		local telopInfo = [
			[
				33,
				35,
				10,
				2,
				(this.BASEW - 10) / 2,
				(this.BASEH - 2) / 2
			],
			[
				33,
				32,
				10,
				2,
				(this.BASEW - 10) / 2,
				(this.BASEH - 2) / 2
			],
			[
				25,
				24,
				18,
				2,
				(this.BASEW - 18) / 2,
				(this.BASEH - 2) / 2
			],
			[
				33,
				38,
				10,
				2,
				(this.BASEW - 10) / 2,
				(this.BASEH - 2) / 2
			]
		];
		return this.createParts(this.iflay, [
			telopInfo[no]
		]);
	}

	function gameStart()
	{
		this.hp = 100;
		this.speed = 1.0;
		this.gameResult = 0;
		this.setupTransition();
		this.showParts();
		this.systemTransition({
			time = 500
		});

		if (this.backbase)
		{
			this.backbase.visible = false;
			this.backbase = null;
		}

		this.gameState = -1;
		this.gameTick = 0;
		this.resultnum = 0;
		this.addTick = 0;
		this.hpTick = this.HP_SUB_FRAME;
		this.gameTelop = this.createTelop(0);
		this.playSound(this.STARTSE);
	}

	function _otherWork( gameTick )
	{
	}

	function checkEnd()
	{
		return this.kazuma.state == 0;
	}

	function gameCheck( text, tick )
	{
		if (text.checkPos())
		{
			local t = text.text;
			this.sysse.play("mgse02");

			if (this.resultOK[this.resultnum] == t)
			{
				text.setEnd(tick);
				this.sysse.play("mgse05");
				this.addResult(text.text);
			}
			else
			{
				this.kazuma.setBlink(tick);
				this.sysse.play("mgse06");
				this.hp -= this.HP_SUB_FAIL;
			}
		}
	}

	function gameMain()
	{
		if (this.gameState < 0)
		{
			if (this.gameTick > this.startTick)
			{
				if (this.gameTelop)
				{
					this.gameTelop.visible = false;
					this.gameTelop = null;
				}

				this.playBGM(this.GAMEBGM);
				this.sysvPlay(27);
				this.gameState = 0;
			}

			this.setBG();
			this.gameTick++;
		}
		else if (this.gameState == 0)
		{
			this.kazuma.checkInput(this.input);
			this.kazuma.work(this.gameTick);
			this._otherWork(this.gameTick);
			local newtext = [];

			foreach( text in this.textlist )
			{
				if (!text.done)
				{
					text.work(this.gameTick);

					if (this.resultnum < this.resultOKlen)
					{
						this.gameCheck(text, this.gameTick);
					}

					if (!text.done)
					{
						newtext.append(text);
					}
				}
			}

			this.textlist.clear();
			this.textlist = newtext;

			if (this.gameTick >= this.addTick)
			{
				this.addText();
				this.addTick = this.gameTick + this.ADD_PACE / this.speed;
			}

			if (this.gameTick >= this.hpTick)
			{
				this.hp--;
				this.hpTick = this.gameTick + this.HP_SUB_FRAME;
			}

			this.setHP(this.hp);

			if (this.resultnum >= this.resultOKlen && this.checkEnd())
			{
				this.gameEnd(0);
			}
			else if (this.hp <= 0)
			{
				this.gameEnd(1);
			}

			this.setBG();
			this.gameTick++;
		}
		else if (this.gameState == 3)
		{
			if (this.gameTick > this.startTick)
			{
				this._gameEnd(this.gameResult);
			}
			else
			{
				this.setBG();
				this.gameTick++;
			}
		}
	}

	function gameEnd( mode = 0 )
	{
		this.stopBGM(500);
		this.gameState = 3;
		this.startTick = this.gameTick + 3 * 60;

		if (mode == 0)
		{
			this.gameTelop = this.createTelop(1);
			this.playSound("miniME03");
			this.sysvPlay(28);
		}
		else if (mode == 1)
		{
			this.gameTelop = this.createTelop(2);
			this.playSound("miniME04");
			this.sysvPlay(29);
		}

		this.gameResult = mode;
	}

	function _gameEnd( mode )
	{
		this.setupTransition();
		this.gameOpen();
		this.setMotion("hide");
		this.systemTransition({
			time = 500
		});
		this.clear();
		this.backbase.visible = false;
		this.backbase = null;

		if (mode == 0)
		{
			this.giveMedal(this.CLEAR_MEDAL);
		}

		this.onProcess(mode == 0 ? 0 : 1);
	}

	function gameFocus( focus )
	{
		return;

		if (focus != null)
		{
			local target = this._motionParts[focus];
			local name = target.name;

			if (name.substr(0, 4) == "desk" || name.substr(0, 3) == "cup")
			{
				local pos = target.getHotSpot();

				if (pos != null)
				{
					this.setVariable("curx", pos.left / 480.0);
					this.setVariable("cury", pos.top / 272.0);
				}

				return;
			}
		}
	}

	function cacheStartVoice( target )
	{
		local base = [
			"cczca%03d",
			"cnzca%03d",
			"rzzca%03d"
		];
		local list = [];

		for( local i = 1; i <= 4; i++ )
		{
			list.append("sound/" + this.format(base[target], i) + ".psb");
		}

		this.addCacheRaw(this.dataCache, list);
		this.waitCache();
	}

	function playRandVoice( no, target = null )
	{
		if (target == null)
		{
			target = this.rand.intrandom(2);
		}

		local names = [
			"kazuma"
		];
		local base = [
			"CCZCA%03d"
		];
		this.appPlayVoice(names[target], this.format(base[target], no));
	}

	function onPause()
	{
		if (this.gameState == 0)
		{
			this.sysse.play("s_pause");
			this.gameState = 1;
			this.gameTelop = this.createTelop(3);
		}
		else if (this.gameState == 1)
		{
			this.sysse.play("s_pause");

			if (this.gameTelop)
			{
				this.gameTelop.visible = false;
				this.gameTelop = null;
			}

			this.gameState = 0;
		}
	}

	function openMotionTelop( type )
	{
		local dialog = this.createMotionPanelLayer(14 + 2);
		dialog.setDelegate(this);

		if (typeof type == "array")
		{
			foreach( chara in type )
			{
				dialog.open({
					chara = chara
				}, "motion/game_telop.psb");
			}
		}
		else
		{
			dialog.open({
				chara = type
			}, "motion/game_telop.psb");
		}
	}

	function forceEnd()
	{
		if (0 || ::System.getDebugBuild())
		{
			if (::confirm("\x00e3\x0083\x0087\x00e3\x0083\x0090\x00e3\x0083\x0083\x00e3\x0082\x00b0\x00e6\x00a9\x009f\x00e8\x0083\x00bd:\x00e5\x00bc\x00b7\x00e5\x0088\x00b6\x00e4\x00b8\x00ad\x00e6\x0096\x00ad"))
			{
				this._gameEnd(0);
				return;
			}
		}

		local msg = "\x00e5\x00bc\x00b7\x00e5\x0088\x00b6\x00e7\x00b5\x0082\x00e4\x00ba\x0086\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0099\x00e3\x0081\x008b\x00ef\x00bc\x009f";

		if (::confirm(msg, "no"))
		{
			this.gameEnd(2);
		}
	}

}

class this.MiniGameFunction1 extends this.MiniGameFunction
{
	constructor( selinfo, input )
	{
		::MiniGameFunction.constructor(selinfo, input);
	}

	bg = null;
	bginfo = [
		[
			39,
			1,
			4,
			17,
			0,
			0
		],
		[
			34,
			1,
			4,
			17,
			4,
			0
		],
		[
			34,
			1,
			4,
			17,
			8,
			0
		],
		[
			34,
			1,
			4,
			17,
			12,
			0
		],
		[
			34,
			1,
			4,
			17,
			16,
			0
		],
		[
			34,
			1,
			4,
			17,
			20,
			0
		],
		[
			39,
			1,
			4,
			17,
			24,
			0
		],
		[
			39,
			1,
			4,
			17,
			28,
			0
		],
		[
			34,
			1,
			4,
			17,
			32,
			0
		],
		[
			34,
			1,
			4,
			17,
			36,
			0
		],
		[
			34,
			1,
			4,
			17,
			40,
			0
		],
		[
			34,
			1,
			4,
			17,
			44,
			0
		],
		[
			34,
			1,
			4,
			17,
			48,
			0
		],
		[
			39,
			1,
			4,
			17,
			52,
			0
		]
	];
	function showParts()
	{
		::MiniGameFunction.showParts();
		this.kazuma = this.KazumaObject(this);
		this.kazuma.initPos(2, 11);
		this.bg = this.createParts(this.bglay, this.bginfo);
	}

	function clear()
	{
		::MiniGameFunction.clear();
		this.bg = null;
	}

	bgpos = 0;
	function setBG()
	{
		if (this.bg != null)
		{
			this.bgpos += this.speed * 0.80000001;
			this.bg.setOffset(this.BASEWIDTH * this.bgpos / 60 % this.BASEWIDTH, 0);
		}
	}

}

class this.MissileObject extends this.CharaObject
{
	pattern = [
		[
			15,
			23,
			2,
			3,
			0,
			0
		]
	];
	constructor( owner )
	{
		this.CharaObject.constructor(owner, "missile", this.pattern, 1);
		this.bx = owner.kazuma.bx + owner.kazuma.x + 8;
		this.by = owner.kazuma.by;
		this.updatePos();
	}

	function _work( tick )
	{
		this.y += 4;

		if (this.y > 10 * 8)
		{
			this.end();
		}

		this.updatePos();
	}

}

class this.KazumaObject2 extends this.CharaObject
{
	pattern = [
		[
			1,
			15,
			4,
			5,
			0,
			0
		],
		[
			6,
			15,
			4,
			5,
			0,
			0
		],
		[
			13,
			15,
			4,
			5,
			0,
			0
		],
		[
			18,
			15,
			4,
			5,
			0,
			0
		],
		[
			23,
			15,
			4,
			5,
			0,
			0
		],
		[
			28,
			15,
			4,
			5,
			0,
			0
		]
	];
	fire = [
		[
			1,
			23,
			2,
			2,
			1,
			3
		],
		[
			4,
			23,
			2,
			2,
			1,
			3
		]
	];
	blink = false;
	blinkend = null;
	KAZUMA_SPEED = 2;
	state = 0;
	constructor( owner )
	{
		this.CharaObject.constructor(owner, "kazuma", this.pattern, 1);
	}

	nx = 0;
	function checkInput( input )
	{
		if (input.key(32))
		{
			this.state = 1;
			this.x -= this.KAZUMA_SPEED;

			if (this.x < -104)
			{
				this.x = -104;
			}
		}
		else if (input.key(16))
		{
			this.state = 2;
			this.x += this.KAZUMA_SPEED;

			if (this.x > 104)
			{
				this.x = 104;
			}
		}
		else
		{
			this.state = 0;
		}

		if (input.keyPressed(this.KEY_OK))
		{
			this.sysse.play("mgse03");
			this.owner.missile.append(this.MissileObject(this.owner));
		}
	}

	function setBlink( tick )
	{
		this.blink = true;
		this.blinkend = tick + 60;
	}

	function _work( tick )
	{
		local pat = tick / 30 % 2;
		this.setPattern(this.state * 2 + pat);
		this.pic.assignImage(this.fire[pat]);

		if (this.blink)
		{
			this.pic.visible = tick / 5 % 2 == 0;

			if (tick > this.blinkend)
			{
				this.blink = false;
				this.pic.visible = true;
			}
		}

		this.updatePos();
	}

}

this.sintable <- [
	0,
	0.0175,
	0.034899998,
	0.052299999,
	0.069799997,
	0.087200001,
	0.1045,
	0.1219,
	0.1392,
	0.1564,
	0.1736,
	0.1908,
	0.2079,
	0.22499999,
	0.2419,
	0.2588,
	0.27559999,
	0.2924,
	0.30899999,
	0.3256,
	0.34200001,
	0.35839999,
	0.37459999,
	0.39070001,
	0.40669999,
	0.4226,
	0.4384,
	0.454,
	0.46950001,
	0.48480001,
	0.5,
	0.51499999,
	0.52990001,
	0.54460001,
	0.55919999,
	0.57359999,
	0.58780003,
	0.60180002,
	0.61570001,
	0.6293,
	0.64279997,
	0.65609998,
	0.66909999,
	0.68199998,
	0.6947,
	0.70709997,
	0.71929997,
	0.73140001,
	0.74309999,
	0.75470001,
	0.76599997,
	0.77710003,
	0.78799999,
	0.79860002,
	0.80900002,
	0.81919998,
	0.829,
	0.82870001,
	0.84799999,
	0.85720003,
	0.88599998,
	0.87459999,
	0.8829,
	0.89099997,
	0.89880002,
	0.90630001,
	0.91350001,
	0.92049998,
	0.92720002,
	0.93360001,
	0.93970001,
	0.94550002,
	0.95109999,
	0.95630002,
	0.96130002,
	0.9659,
	0.97030002,
	0.97439998,
	0.9781,
	0.98159999,
	0.98479998,
	0.98769999,
	0.9903,
	0.99250001,
	0.99449998,
	0.99620003,
	0.99760002,
	0.99860001,
	0.99940002,
	0.99980003,
	1,
	0.99980003,
	0.99940002,
	0.99860001,
	0.99760002,
	0.99620003,
	0.99449998,
	0.99250001,
	0.9903,
	0.98769999,
	0.98479998,
	0.98159999,
	0.9781,
	0.97439998,
	0.97030002,
	0.9659,
	0.96130002,
	0.95630002,
	0.95109999,
	0.94550002,
	0.93970001,
	0.93360001,
	0.92720002,
	0.92049998,
	0.91350001,
	0.90630001,
	0.89880002,
	0.89099997,
	0.88599998,
	0.8829,
	0.87459999,
	0.85720003,
	0.84799999,
	0.829,
	0.82870001,
	0.81919998,
	0.80900002,
	0.79860002,
	0.78799999,
	0.77710003,
	0.76599997,
	0.75470001,
	0.74309999,
	0.73140001,
	0.71929997,
	0.70709997,
	0.6947,
	0.68199998,
	0.66909999,
	0.65609998,
	0.64279997,
	0.6293,
	0.61570001,
	0.60180002,
	0.58780003,
	0.57359999,
	0.55919999,
	0.54460001,
	0.52990001,
	0.51499999,
	0.5,
	0.48480001,
	0.46950001,
	0.454,
	0.4384,
	0.4226,
	0.40669999,
	0.39070001,
	0.37459999,
	0.35839999,
	0.34200001,
	0.3256,
	0.30899999,
	0.2924,
	0.27559999,
	0.2588,
	0.2419,
	0.22499999,
	0.2079,
	0.1908,
	0.1736,
	0.1564,
	0.1392,
	0.1219,
	0.1045,
	0.087200001,
	0.069799997,
	0.052299999,
	0.034899998,
	0.0175,
	0,
	-0.0175,
	-0.034899998,
	-0.052299999,
	-0.069799997,
	-0.087200001,
	-0.1045,
	-0.1219,
	-0.1392,
	-0.1564,
	-0.1736,
	-0.1908,
	-0.2079,
	-0.22499999,
	-0.2419,
	-0.2588,
	-0.27559999,
	-0.2924,
	-0.30899999,
	-0.3256,
	-0.34200001,
	-0.35839999,
	-0.37459999,
	-0.39070001,
	-0.40669999,
	-0.4226,
	-0.4384,
	-0.454,
	-0.46950001,
	-0.48480001,
	-0.5,
	-0.51499999,
	-0.52990001,
	-0.54460001,
	-0.55919999,
	-0.57359999,
	-0.58780003,
	-0.60180002,
	-0.61570001,
	-0.6293,
	-0.64279997,
	-0.65609998,
	-0.66909999,
	-0.68199998,
	-0.6947,
	-0.70709997,
	-0.71929997,
	-0.73140001,
	-0.74309999,
	-0.75470001,
	-0.76599997,
	-0.77710003,
	-0.78799999,
	-0.79860002,
	-0.80900002,
	-0.81919998,
	-0.829,
	-0.82870001,
	-0.84799999,
	-0.85720003,
	-0.88599998,
	-0.87459999,
	-0.8829,
	-0.89099997,
	-0.89880002,
	-0.90630001,
	-0.91350001,
	-0.92049998,
	-0.92720002,
	-0.93360001,
	-0.93970001,
	-0.94550002,
	-0.95109999,
	-0.95630002,
	-0.96130002,
	-0.9659,
	-0.97030002,
	-0.97439998,
	-0.9781,
	-0.98159999,
	-0.98479998,
	-0.98769999,
	-0.9903,
	-0.99250001,
	-0.99449998,
	-0.99620003,
	-0.99760002,
	-0.99860001,
	-0.99940002,
	-0.99980003,
	-1,
	-0.99980003,
	-0.99940002,
	-0.99860001,
	-0.99760002,
	-0.99620003,
	-0.99449998,
	-0.99250001,
	-0.9903,
	-0.98769999,
	-0.98479998,
	-0.98159999,
	-0.9781,
	-0.97439998,
	-0.97030002,
	-0.9659,
	-0.96130002,
	-0.95630002,
	-0.95109999,
	-0.94550002,
	-0.93970001,
	-0.93360001,
	-0.92720002,
	-0.92049998,
	-0.91350001,
	-0.90630001,
	-0.89880002,
	-0.89099997,
	-0.88599998,
	-0.8829,
	-0.87459999,
	-0.85720003,
	-0.84799999,
	-0.829,
	-0.82870001,
	-0.81919998,
	-0.80900002,
	-0.79860002,
	-0.78799999,
	-0.77710003,
	-0.76599997,
	-0.75470001,
	-0.74309999,
	-0.73140001,
	-0.71929997,
	-0.70709997,
	-0.6947,
	-0.68199998,
	-0.66909999,
	-0.65609998,
	-0.64279997,
	-0.6293,
	-0.61570001,
	-0.60180002,
	-0.58780003,
	-0.57359999,
	-0.55919999,
	-0.54460001,
	-0.52990001,
	-0.51499999,
	-0.5,
	-0.48480001,
	-0.46950001,
	-0.454,
	-0.4384,
	-0.4226,
	-0.40669999,
	-0.39070001,
	-0.37459999,
	-0.35839999,
	-0.34200001,
	-0.3256,
	-0.30899999,
	-0.2924,
	-0.27559999,
	-0.2588,
	-0.2419,
	-0.22499999,
	-0.2079,
	-0.1908,
	-0.1736,
	-0.1564,
	-0.1392,
	-0.1219,
	-0.1045,
	-0.087200001,
	-0.069799997,
	-0.052299999,
	-0.034899998,
	-0.0175
];
this.costable <- [
	1,
	0.99980003,
	0.99940002,
	0.99860001,
	0.99760002,
	0.99620003,
	0.99449998,
	0.99250001,
	0.9903,
	0.98769999,
	0.98479998,
	0.98159999,
	0.9781,
	0.97439998,
	0.97030002,
	0.9659,
	0.96130002,
	0.95630002,
	0.95109999,
	0.94550002,
	0.93970001,
	0.93360001,
	0.92720002,
	0.92049998,
	0.91350001,
	0.90630001,
	0.89880002,
	0.89099997,
	0.8829,
	0.87459999,
	0.866,
	0.85720003,
	0.84799999,
	0.8387,
	0.829,
	0.81919998,
	0.80900002,
	0.79860002,
	0.78799999,
	0.77710003,
	0.76599997,
	0.75470001,
	0.74309999,
	0.73140001,
	0.71929997,
	0.70709997,
	0.6947,
	0.68199998,
	0.66909999,
	0.65609998,
	0.64279997,
	0.6293,
	0.61570001,
	0.60180002,
	0.58780003,
	0.57359999,
	0.55919999,
	0.54460001,
	0.52990001,
	0.51499999,
	0.5,
	0.48480001,
	0.46950001,
	0.454,
	0.4384,
	0.4226,
	0.40669999,
	0.39070001,
	0.37459999,
	0.35839999,
	0.34200001,
	0.3256,
	0.30899999,
	0.2924,
	0.27559999,
	0.2588,
	0.2419,
	0.22499999,
	0.2079,
	0.1908,
	0.1736,
	0.1564,
	0.1392,
	0.1219,
	0.1045,
	0.087200001,
	0.069799997,
	0.052299999,
	0.034899998,
	0.0175,
	0,
	-0.0175,
	-0.034899998,
	-0.052299999,
	-0.069799997,
	-0.087200001,
	-0.1045,
	-0.1219,
	-0.1392,
	-0.1564,
	-0.1736,
	-0.1908,
	-0.2079,
	-0.22499999,
	-0.2419,
	-0.2588,
	-0.27559999,
	-0.2924,
	-0.30899999,
	-0.3256,
	-0.34200001,
	-0.35839999,
	-0.37459999,
	-0.39070001,
	-0.40669999,
	-0.4226,
	-0.4384,
	-0.454,
	-0.46950001,
	-0.48480001,
	-0.5,
	-0.51499999,
	-0.52990001,
	-0.54460001,
	-0.55919999,
	-0.57359999,
	-0.58780003,
	-0.60180002,
	-0.61570001,
	-0.6293,
	-0.64279997,
	-0.65609998,
	-0.66909999,
	-0.68199998,
	-0.6947,
	-0.70709997,
	-0.71929997,
	-0.73140001,
	-0.74309999,
	-0.75470001,
	-0.76599997,
	-0.77710003,
	-0.78799999,
	-0.79860002,
	-0.80900002,
	-0.81919998,
	-0.829,
	-0.8387,
	-0.84799999,
	-0.85720003,
	-0.866,
	-0.87459999,
	-0.8829,
	-0.89099997,
	-0.89880002,
	-0.90630001,
	-0.91350001,
	-0.92049998,
	-0.92720002,
	-0.93360001,
	-0.93970001,
	-0.94550002,
	-0.95109999,
	-0.95630002,
	-0.96130002,
	-0.9659,
	-0.97030002,
	-0.97439998,
	-0.9781,
	-0.98159999,
	-0.98479998,
	-0.98769999,
	-0.9903,
	-0.99250001,
	-0.99449998,
	-0.99620003,
	-0.99760002,
	-0.99860001,
	-0.99940002,
	-0.99980003,
	-1,
	-0.99980003,
	-0.99940002,
	-0.99860001,
	-0.99760002,
	-0.99620003,
	-0.99449998,
	-0.99250001,
	-0.9903,
	-0.98769999,
	-0.98479998,
	-0.98159999,
	-0.9781,
	-0.97439998,
	-0.97030002,
	-0.9659,
	-0.96130002,
	-0.95630002,
	-0.95109999,
	-0.94550002,
	-0.93970001,
	-0.93360001,
	-0.92720002,
	-0.92049998,
	-0.91350001,
	-0.90630001,
	-0.89880002,
	-0.89099997,
	-0.8829,
	-0.87459999,
	-0.866,
	-0.85720003,
	-0.84799999,
	-0.8387,
	-0.829,
	-0.81919998,
	-0.80900002,
	-0.79860002,
	-0.78799999,
	-0.77710003,
	-0.76599997,
	-0.75470001,
	-0.74309999,
	-0.73140001,
	-0.71929997,
	-0.70709997,
	-0.6947,
	-0.68199998,
	-0.66909999,
	-0.65609998,
	-0.64279997,
	-0.6293,
	-0.61570001,
	-0.60180002,
	-0.58780003,
	-0.57359999,
	-0.55919999,
	-0.54460001,
	-0.52990001,
	-0.51499999,
	-0.5,
	-0.48480001,
	-0.46950001,
	-0.454,
	-0.4384,
	-0.4226,
	-0.40669999,
	-0.39070001,
	-0.37459999,
	-0.35839999,
	-0.34200001,
	-0.3256,
	-0.30899999,
	-0.2924,
	-0.27559999,
	-0.2588,
	-0.2419,
	-0.22499999,
	-0.2079,
	-0.1908,
	-0.1736,
	-0.1564,
	-0.1392,
	-0.1219,
	-0.1045,
	-0.087200001,
	-0.069799997,
	-0.052299999,
	-0.034899998,
	-0.0175,
	0,
	0.0175,
	0.034899998,
	0.052299999,
	0.069799997,
	0.087200001,
	0.1045,
	0.1219,
	0.1392,
	0.1564,
	0.1736,
	0.1908,
	0.2079,
	0.22499999,
	0.2419,
	0.2588,
	0.27559999,
	0.2924,
	0.30899999,
	0.3256,
	0.34200001,
	0.35839999,
	0.37459999,
	0.39070001,
	0.40669999,
	0.4226,
	0.4384,
	0.454,
	0.46950001,
	0.48480001,
	0.5,
	0.51499999,
	0.52990001,
	0.54460001,
	0.55919999,
	0.57359999,
	0.58780003,
	0.60180002,
	0.61570001,
	0.6293,
	0.64279997,
	0.65609998,
	0.66909999,
	0.68199998,
	0.6947,
	0.70709997,
	0.71929997,
	0.73140001,
	0.74309999,
	0.75470001,
	0.76599997,
	0.77710003,
	0.78799999,
	0.79860002,
	0.80900002,
	0.81919998,
	0.829,
	0.8387,
	0.84799999,
	0.85720003,
	0.866,
	0.87459999,
	0.8829,
	0.89099997,
	0.89880002,
	0.90630001,
	0.91350001,
	0.92049998,
	0.92720002,
	0.93360001,
	0.93970001,
	0.94550002,
	0.95109999,
	0.95630002,
	0.96130002,
	0.9659,
	0.97030002,
	0.97439998,
	0.9781,
	0.98159999,
	0.98479998,
	0.98769999,
	0.9903,
	0.99250001,
	0.99449998,
	0.99620003,
	0.99760002,
	0.99860001,
	0.99940002,
	0.99980003
];
class this.TextObject2 extends this.TextObject
{
	XWIDE = 8;
	TYPE1_WIDE = 1;
	TYPE1_WIDEBASE = 1;
	TYPE1_FORCE = 0.1;
	TYPE2_WIDE = 1;
	TYPE2_WIDEBASE = 3;
	TYPE2_FORCE = 0.1;
	TYPE2_XWIDE = 1.5;
	TYPE2_XWIDEBASE = 0.5;
	TYPE3_WIDE = 10;
	TYPE3_WIDEBASE = 15;
	moveType = 0;
	force = 0;
	x_prev = 0;
	y_prev = 0;
	xstate = 0;
	XMAX = 0;
	xdir = 1;
	bpat = 0;
	radius = 0;
	x_base = 0;
	y_base = 0;
	degree = 0;
	y_diff = 0;
	rotate = 0;
	constructor( owner, no, text )
	{
		::TextObject.constructor(owner, no, text);
		this.x = 0;
		this.y = 0;
		this.moveType = ::intrandom(2);
		local xpos = 12 + owner.rand.intrandom(this.XWIDE * 2) - this.XWIDE;
		this.initPos(xpos, 0);

		if (this.moveType == 1)
		{
			this.XMAX = this.TYPE1_WIDEBASE + owner.rand.random(this.TYPE1_WIDE);
			this.force = this.XMAX;
		}
		else if (this.moveType == 2)
		{
			this.x_base = xpos;
			this.y_base = 10;
			this.radius = this.TYPE3_WIDEBASE + owner.rand.intrandom(this.TYPE3_WIDE);
			this.rotate = owner.rand.intrandom(1);
			this.degree = -90;
			this.x = this.x_base + this.radius * this.costable[270];
			this.y = this.y_base + this.radius * this.sintable[270];
			this.updatePos();
		}
		else if (this.moveType == 3)
		{
			this.force = -(this.TYPE2_WIDEBASE + owner.rand.random(this.TYPE2_WIDE));
			this.xdir = (this.TYPE2_XWIDEBASE + owner.rand.random(this.TYPE2_XWIDE)) * (owner.kazuma.x < xpos ? -1.0 : 1.0);
		}
	}

	function _work( tick )
	{
		if (this.state == 0 || this.state == 1)
		{
			if (this.moveType == 0 || this.moveType == 1)
			{
				this.y -= this.owner.speed * 0.5;

				if (this.y < -18 * 8)
				{
					this.state = 3;
				}

				if (this.moveType == 1)
				{
					local x_temp = this.x;
					this.x += this.x - this.x_prev + this.force;
					this.x_prev = x_temp;

					if (this.xstate)
					{
						if (this.x >= 0)
						{
							this.xstate = 0;
							this.x = 0;
							this.x_prev = 0;
							this.force = this.XMAX;
						}
						else
						{
							this.force = this.TYPE1_FORCE;
						}
					}
					else if (this.x <= 0)
					{
						this.xstate = 1;
						this.x = 0;
						this.x_prev = 0;
						this.force = -this.XMAX;
					}
					else
					{
						this.force = -this.TYPE1_FORCE;
					}
				}
			}
			else if (this.moveType == 2)
			{
				this.y_diff -= this.owner.speed * 0.5;

				if (this.rotate == 0)
				{
					this.degree = this.degree - 3;

					if (this.degree <= -180)
					{
						this.rotate = 1;
					}
				}
				else
				{
					this.degree = this.degree + 3;

					if (this.degree >= 0)
					{
						this.rotate = 0;
					}
				}

				local deg = this.degree < 0 ? this.degree + 360 : 0;
				local x_temp = this.radius * this.costable[deg];
				local y_temp = this.radius * this.sintable[deg];
				this.x = this.x_base + x_temp;
				this.y = this.y_base + y_temp + this.y_diff;

				if (this.y < -18 * 8)
				{
					this.state = 3;
				}
			}
			else if (this.moveType == 3)
			{
				this.x += this.xdir * this.owner.speed;
				local y_temp = this.y;
				this.y += this.y - this.y_prev + this.force;
				this.y_prev = y_temp;

				if (this.y >= 0)
				{
					this.y = 0;
					this.y_prev = 0;
					this.state = 3;
				}
				else
				{
					this.force = this.TYPE2_FORCE;
				}
			}

			local pat = tick / 30 % 2;
			this.setPattern(pat);
		}
		else if (this.state == 2)
		{
			this.textObj.visible = this.pic.visible = tick / 5 % 2 == 0;

			if (tick > this.endtick)
			{
				this.state = 3;
			}

			if (this.bpat < 4)
			{
				this.bpat += 1 / 15.0;
			}

			this.setPattern(::toint(2 + this.bpat));
		}
		else if (this.state == 3)
		{
			this.end();
		}

		this.updatePos();
	}

	function checkPos()
	{
		if (this.state == 0)
		{
			local kazuma = this.owner.kazuma;
			local sx = this.bx + this.x;
			local sy = this.by - this.y;
			local x = kazuma.bx + kazuma.x;
			local y = kazuma.by - kazuma.y;

			if (x >= sx - 2.5 * 8 && x <= sx + 1.5 * 8 && y >= sy - 2 * 8 && y <= sy + 3.5 * 8)
			{
				this.state = 1;
				return true;
			}
		}

		return false;
	}

	function checkPos2()
	{
		if (this.state == 0 || this.state == 1)
		{
			foreach( m in this.owner.missile )
			{
				local sx = this.bx + this.x;
				local sy = this.by - this.y;
				local x = m.bx + m.x;
				local y = m.by - m.y;

				if (x >= sx - 8 && x <= sx + 8 && y >= sy - 8 && y <= sy + 8)
				{
					m.end();
					return true;
				}
			}
		}

		return false;
	}

}

class this.MiniGameFunction2 extends this.MiniGameFunction
{
	HP_SUB_FAIL = 10;
	HP_SUB_FRAME = 120;
	HP_SUB_CRASH = 10;
	ADD_PACE = 180;
	STARTSE = "miniME02";
	GAMEBGM = "BGM_MINI02";
	BGFILE = "SHT_BG";
	CLEAR_MEDAL = "md35";
	blackbg = null;
	bg = null;
	bgpos = null;
	bginfo = [
		[
			19,
			22,
			2,
			2,
			0,
			0
		],
		[
			22,
			22,
			1,
			1,
			0,
			0
		],
		[
			24,
			22,
			1,
			1,
			0,
			0
		]
	];
	bgnum = [
		5,
		10,
		20
	];
	bgspeed = [
		0.80000001,
		0.60000002,
		0.40000001
	];
	missile = null;
	constructor( selinfo, input )
	{
		::MiniGameFunction.constructor(selinfo, input);
	}

	function showParts()
	{
		::MiniGameFunction.showParts();
		this.kazuma = this.KazumaObject2(this);
		this.kazuma.initPos(12, 12);
		this.blackbg = ::FillRect(this.bglay);
		this.blackbg.setSize(this.BASEWIDTH, this.BASEHEIGHT);
		this.blackbg.setColor(this.ARGB2RGBA(4278190080));
		this.blackbg.visible = true;
		this.bg = [];
		this.bgpos = [];
		local n = 0;

		foreach( info in this.bginfo )
		{
			local list = [];

			for( local i = 0; i < this.bgnum[n]; i++ )
			{
				local a = clone info;
				a[4] = this.rand.intrandom(this.BASEW);
				a[5] = this.rand.intrandom(this.BASEH * 2);
				list.append(a);
				local b = clone a;
				b[5] += this.BASEH * 2;
				list.append(b);
			}

			local b = this.createParts(this.bglay, list);
			this.bg.append(b);
			this.bgpos.append(0);
			n++;
		}

		this.missile = [];
	}

	function clear()
	{
		::MiniGameFunction.clear();

		if (this.bg)
		{
			this.bg.clear();
			this.bg = null;
		}

		if (this.missile)
		{
			this.missile.clear();
			this.missile = null;
		}

		if (this.blackbg)
		{
			this.blackbg = null;
		}
	}

	function createText( text )
	{
		local t = this.TextObject2(this, this.textno++, text);
		return t;
	}

	bgpos = 0;
	function setBG()
	{
		if (this.bg != null)
		{
			for( local i = 0; i < this.bg.len(); i++ )
			{
				this.bgpos[i] += this.speed * this.bgspeed[i];
				this.bg[i].setOffset(0, this.BASEHEIGHT * 3 - this.BASEHEIGHT * 2 * this.bgpos[i] / 120 % this.BASEHEIGHT * 2);
			}
		}
	}

	function _otherWork( gameTick )
	{
		local newmissile = [];

		foreach( m in this.missile )
		{
			if (!m.done)
			{
				m.work(gameTick);

				if (!m.done)
				{
					newmissile.append(m);
				}
			}
		}

		this.missile.clear();
		this.missile = newmissile;
	}

	function checkEnd()
	{
		return true;
	}

	function gameCheck( text, tick )
	{
		if (text.checkPos())
		{
			text.setEnd(tick);
			this.sysse.play("mgse07");
			this.hp -= this.HP_SUB_CRASH;
			this.kazuma.setBlink(tick);
		}
		else if (text.checkPos2())
		{
			local t = text.text;
			this.sysse.play("mgse04");
			text.setEnd(tick);

			if (this.resultOK[this.resultnum] == t)
			{
				text.setEnd(tick);
				this.sysse.play("mgse05");
				this.addResult(text.text);
			}
			else
			{
				this.sysse.play("mgse06");
				this.hp -= this.HP_SUB_FAIL;
			}
		}
	}

}

