class this.EnvGraphicLayer extends ::BasicAffineLayer
{
	DEFAULT_AFX = "center";
	DEFAULT_AFY = "center";
	IMAGE_RESOLUTION = this.SCWIDTH.tofloat() / 1920;
	owner = null;
	player = null;
	camerainfo = null;
	_cameraMode = 65;
	_leveloffset = null;
	function setLeveloffset( v )
	{
		if (v == "" || v == 0 || v == null)
		{
			this._leveloffset = null;
		}
		else
		{
			this._leveloffset = v.split(",");
			local n = this._leveloffset.len();

			for( local i = 0; i < n; i++ )
			{
				this._leveloffset[i] = ::toint(this._leveloffset[i]);
			}
		}
	}

	function getLeveloffset()
	{
		if (this._leveloffset != null)
		{
			return this._leveloffset.join(",");
		}
	}

	function getImageResolution()
	{
		return this.IMAGE_RESOLUTION;
	}

	function calcParam( name )
	{
		return this.player != null ? this.player["emote_" + name] : 1.0;
	}

	function eval( eval, error = null )
	{
		if (this.player != null)
		{
			return this.player.eval(eval, error);
		}

		return null;
	}

	function suspend()
	{
		if (this.player != null)
		{
			this.player.suspend();
		}
		else
		{
			::suspend();
		}
	}

	function loadData( name )
	{
		return this.player != null ? this.player.loadData(name) : ::loadData(name);
	}

	imageFile = null;
	_CX = 0;
	_CY = 0;
	qx = 0;
	qy = 0;
	constructor( owner, name )
	{
		local player = owner.player;
		local camerainfo = owner.camera;
		::BasicAffineLayer.constructor(player != null ? player.base : null, name);
		this.owner = owner.weakref();
		this.player = player != null ? player.weakref() : null;
		this.camerainfo = camerainfo != null ? camerainfo.weakref() : null;
		this.reset();
		this._cameraMode = 65;
		this._CX = 1920 / 2;
		this._CY = 1080 / 2;
	}

	actstart = false;
	function onActionCompleteAfter( propName )
	{
		if (this.actstart && propName == "visvalue")
		{
			this.owner.doneTransition(this);
		}
	}

	function destructor()
	{
		if (this.player != null)
		{
			this.player.removeAction(this);
			this.player.delCopyValue(this);
		}

		::BasicAffineLayer.destructor();
	}

	function setBaseClip( x, y, w, h )
	{
		::BasicAffineLayer.setBaseClip(x - this.qx, y - this.qy, w, h);
	}

	_actionCount = 0;
	function onMotionChange()
	{
		this._actionCount = 0;
	}

	function onMotionAction( label, action )
	{
		if (this.player != null)
		{
			this._actionCount++;
			this.player.extractDelay(action);
			local name = "ml" + this._actionCount;

			if (name != action)
			{
				this.player.extractDelay(name);
			}
		}
	}

	function updateSpeed()
	{
	}

	function setClip( x, y, w, h )
	{
		::BasicAffineLayer.setClip(x - this._CX, y - this._CY, w, h);
	}

	function loadImage( imageFile )
	{
		if (!::equals(imageFile, this.imageFile) || ("options" in imageFile) && "variables" in imageFile.options)
		{
			this.imageFile = imageFile;
			::BasicAffineLayer.loadImage(imageFile);
		}
	}

	function assign( src )
	{
		::BasicAffineLayer.assign(src);
		this._cameraMode = src._cameraMode;
		this._leveloffset = src._leveloffset != null ? clone src._leveloffset : null;

		if (this.player)
		{
			this.player.assignAction(src, this);
			this.player.copyCopyValue(this, null, src);
		}
	}

	function copyImage( src )
	{
		::BasicAffineLayer.copyImage(src);
		this.imageFile = src.imageFile;
	}

	function reset()
	{
		if (this.player)
		{
			this.player.stopAction(this, true);
		}

		::BasicAffineLayer.reset();
	}

	function copyValue( name, type )
	{
		if (this.player)
		{
			return this.player.copyValue(name, type);
		}
	}

	function getImagey()
	{
		if (this.cameraMode & 64)
		{
			return -::BasicAffineLayer.getImagey();
		}
		else
		{
			return ::BasicAffineLayer.getImagey();
		}
	}

	function setImagey( v )
	{
		if (this.cameraMode & 64)
		{
			::BasicAffineLayer.setImagey(-v);
		}
		else
		{
			::BasicAffineLayer.setImagey(v);
		}
	}

	function getCameraMode()
	{
		return this._cameraMode;
	}

	function setCameraMode( v )
	{
		if (v == null)
		{
			v = 65;
		}

		if (this._cameraMode != v)
		{
			this._cameraMode = v;
			this.updateAffine();
			this._calcOpacity();
		}
	}

	function getZorder()
	{
		return this.camerainfo.cameraoffsetz.tofloat() / (this.camerainfo.cameraoffsetz + this.camerainfo.cameraz - (this.calczpos + this.offsetz)) * 100;
	}

	function getZorder2()
	{
		return this.camerainfo.cameraoffsetz.tofloat() / (this.camerainfo.cameraoffsetz + this.camerainfo.cameraz) * 100;
	}

	function recalcWind()
	{
		this.updateEnvironment({
			wind = {
				start = this.camerainfo.windstart,
				goal = this.camerainfo.windgoal,
				speed = this.camerainfo.windspeed,
				min = this.camerainfo.windmin,
				max = this.camerainfo.windmax
			}
		});
	}

	function cutoffcamera()
	{
		if (typeof this.camerainfo == "table" || this.camerainfo == null)
		{
			return;
		}

		this.camerainfo = {
			camerax = this.camerainfo.camerax,
			cameray = this.camerainfo.cameray,
			cameraz = this.camerainfo.cameraz,
			cameraoffsetx = this.camerainfo.cameraoffsetx,
			cameraoffsety = this.camerainfo.cameraoffsety,
			cameraoffsetz = this.camerainfo.cameraoffsetz,
			cameraoffsetzmax = this.camerainfo.cameraoffsetzmax,
			camerazoom = this.camerainfo.camerazoom,
			camerarotate = this.camerainfo.camerarotate,
			cameraox = this.camerainfo.cameraox,
			cameraoy = this.camerainfo.cameraox,
			camerarh = this.camerainfo.camerarh,
			shiftx = this.camerainfo.shiftx,
			shifty = this.camerainfo.shifty,
			zoomx = this.camerainfo.zoomx,
			zoomy = this.camerainfo.zoomy,
			zcenterx = this.camerainfo.zcenterx,
			zcentery = this.camerainfo.zcentery,
			scalex = this.camerainfo.scalex,
			scaley = this.camerainfo.scaley,
			windstart = this.camerainfo.windstart,
			windgoal = this.camerainfo.windgoal,
			windspeed = this.camerainfo.windspeed,
			windmin = this.camerainfo.windmin,
			windmax = this.camerainfo.windmax
		};
	}

	function calcMatrix( mtx )
	{
		if (this.camerainfo.scalex != 1.0 || this.camerainfo.scaley != 1.0)
		{
			mtx.scale(this.camerainfo.scalex, this.camerainfo.scaley);
		}

		local cox;
		local coy;

		if (this.cameraMode & 2)
		{
			cox = this.camerainfo.cameraox;
			coy = this.camerainfo.cameraoy;
		}
		else
		{
			cox = 0;
			coy = 0;
		}

		local csx;
		local csy;

		if (this.cameraMode & 1)
		{
			csx = this.camerainfo.shiftx;
			csy = this.camerainfo.shifty;
		}
		else
		{
			csx = 0;
			csy = 0;
		}

		if (this._cameraMode & 16)
		{
			csx += this.player.msglayoffx;
			csy += this.player.msglayoffy;
		}

		local qmode = this._cameraMode & (16 | 32);
		this.qx = qmode && this.player != null ? this.player.qx : 0;
		this.qy = qmode && this.player != null ? this.player.qy : 0;
		mtx.translate(cox + csx - this.qx, coy + csy - this.qy, 0);

		if (this.cameraMode & 1)
		{
			if (this.camerainfo.zoomx != 100 || this.camerainfo.zoomy != 100)
			{
				local _zcenterx = this.camerainfo.zcenterx;
				local _zcentery = this.camerainfo.zcentery;
				mtx.translate(_zcenterx, _zcentery);
				mtx.scale(this.camerainfo.zoomx / 100.0, this.camerainfo.zoomy / 100.0);
				mtx.translate(-_zcenterx, -_zcentery);
			}
		}

		local czmin = this.camerainfo.cameraoffsetz + this.camerainfo.cameraz;
		local czmax = this.camerainfo.cameraoffsetzmax + this.camerainfo.cameraz;
		local d = this.calczpos + this.offsetz;
		local cameraok = !(this.cameraMode & 4) || d > czmin && d < czmax && this.camerainfo.camerazoom != 0;

		if (this.cameraMode & 2)
		{
			if (!cameraok)
			{
				mtx.scale(0, 0, 1);
			}
			else if (this.cameraMode & 4)
			{
				local vmtx = this.AffineMatrix();
				vmtx.initPerspective();
				mtx.multiply(vmtx);
				local z = (this.camerainfo.cameraoffsetz + this.camerainfo.cameraz - d).tofloat() / this.camerainfo.cameraoffsetz;
				local cmtx = this.AffineMatrix();

				if (this.camerainfo.camerarh)
				{
					cmtx.flipy();
				}

				if (this.camerainfo.camerarotate)
				{
					cmtx.rotate(-this.camerainfo.camerarotate);
				}

				if (this.camerainfo.camerazoom != 100)
				{
					z *= 100.0 / this.camerainfo.camerazoom;
				}

				local cx = -(this.camerainfo.cameraoffsetx + this.camerainfo.camerax);
				local cy = -(this.camerainfo.cameraoffsety + this.camerainfo.cameray);
				cmtx.translate(cx, cy);

				if (this.camerainfo.camerarh)
				{
					cmtx.flipy();
				}

				mtx.multiply(cmtx);
				mtx.translate(-cox, -coy, z);
			}
			else
			{
				local crot = this.camerainfo.camerarh ? 1 : -1;

				if (this.camerainfo.camerarotate)
				{
					mtx.rotate(crot * this.camerainfo.camerarotate);
				}

				if (this.camerainfo.camerazoom != 100)
				{
					local z = this.camerainfo.camerazoom / 100.0;
					mtx.scale(z, z);
				}

				local cx = -(this.camerainfo.cameraoffsetx + this.camerainfo.camerax);
				local cy = crot * (this.camerainfo.cameraoffsety + this.camerainfo.cameray);
				mtx.translate(cx, cy);
			}
		}

		if (this.cameraMode & 64)
		{
			mtx.flipy();
		}

		local smtx = this.AffineMatrix();
		::AffineLayer.calcMatrix(smtx);
		mtx.multiply(smtx);
		local zorder = this.getZorder();

		if (this._leveloffset != null)
		{
			local n = this.player.calcLevel(zorder) * 2;

			if (n + 1 < this._leveloffset.len())
			{
				local xoff = this._leveloffset[n] * 100.0 / zorder;
				local yoff = this._leveloffset[n + 1] * 100.0 / zorder;
				mtx.translate(xoff, yoff);
			}
		}

		if (this.cameraMode & 64)
		{
			mtx.flipy();
		}

		if (this.cameraMode & 4)
		{
			if (!(this.cameraMode & 8))
			{
				if (zorder != 0)
				{
					local z = this.zorder2 / zorder;
					mtx.scale(z, z, 1);
				}
			}
		}
		else if (this.cameraMode & 8)
		{
			local z = zorder / 100.0;
			mtx.scale(z, z, 1);
		}
	}

	_msgvisible = false;
	function setMsgVisible( v )
	{
		if (this._msgvisible != v)
		{
			this._msgvisible = v;
			this._calcOpacity();
		}
	}

	function _setInnerVisible( visible )
	{
		::AffineLayer.setVisible(visible && (this._msgvisible || !(this.cameraMode & 16)));
	}

	krkrTypes = [
		0,
		0,
		0,
		1,
		2,
		3,
		0,
		0,
		0,
		0,
		0,
		4,
		0,
		0,
		1,
		5,
		3,
		4,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		6,
		6,
		6
	];
	_krkrtype = 2;
	function setType( type )
	{
		if (type == null)
		{
			type = 2;
		}

		if (type != this._krkrtype)
		{
			this._krkrtype = type;
			type = type < this.krkrTypes.len() ? this.krkrTypes[type] : 0;
			this._picture.setType(type);
		}
	}

	function getType()
	{
		return this._krkrtype;
	}

}

class this.EnvObject extends this.Object
{
	player = null;
	name = null;
	cname = null;
	constructor( player, name, cname )
	{
		::Object.constructor();
		this.player = player.weakref();
		this.name = name;
		this.cname = cname;
	}

	function getUpdateTarget()
	{
		return this;
	}

	function getWaitTarget()
	{
		return this;
	}

	function eval( eval, error = null )
	{
		if (this.player != null)
		{
			return this.player.eval(eval, error);
		}

		return null;
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

	function updateProperty( target, actionList )
	{
		if (target == null || actionList == null || this.player == null)
		{
			return;
		}

		local doprops = {};

		foreach( actinfo in actionList )
		{
			if (actinfo == null)
			{
				this.player.stopAction(target, true);
				this.player.delCopyValue(target);
			}
			else if (typeof actinfo == "integer")
			{
				this.player.stopAction(target, actinfo != 0);
			}
			else
			{
				local name = actinfo[0];
				local value = actinfo[1];

				if (!(name in doprops) || value == null)
				{
					this.player.delAction(target, name);
					this.player.delCopyValue(target, name);
					doprops[name] <- true;
				}

				if (typeof value == "array")
				{
					this.player.addAction(target, name, value);
				}
				else if (value != null)
				{
					if (typeof value != "string")
					{
						local time = actinfo.len() > 2 ? actinfo[2] : 0;
						local accel = actinfo.len() > 3 ? actinfo[3] : 0;

						try
						{
							this.player.setProperty(target, name, value, time, accel);
						}
						catch( e )
						{
							this.printf("\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x0091\x00e3\x0083\x0086\x00e3\x0082\x00a3\x00e8\x00a8\x00ad\x00e5\x00ae\x009a\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s:%s:%s:%s\n", name, value, time, accel, e);
						}
					}
					else if (value.len() > 0 && value.charAt(0) == "#")
					{
						try
						{
							this.player.setProperty(target, name, value.substr(1));
						}
						catch( e )
						{
							this.printf("\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x0091\x00e3\x0083\x0086\x00e3\x0082\x00a3\x00e8\x00a8\x00ad\x00e5\x00ae\x009a\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s\n", name, value);
						}
					}
				}
			}
		}
	}

	function updatePropertyAfter( target, actionList )
	{
		if (target == null || actionList == null || this.player == null)
		{
			return;
		}

		foreach( actinfo in actionList )
		{
			if (typeof actinfo == "array")
			{
				local name = actinfo[0];
				local value = actinfo[1];

				if (typeof value == "string" && value != "" && value.charAt(0) != "#")
				{
					try
					{
						if (value.charAt(0) == "$")
						{
							this.player.addCopyValue(target, name, value.substr(1), ::getProperty(target, name));
						}
						else if (value in this.player.env.objects)
						{
							local src = this.player.env.objects[value].getUpdateTarget();

							if (src != null)
							{
								this.player.setProperty(target, name, ::getProperty(src, name));
								this.player.copyCopyValue(target, name, src);

								if (this.player.hasAction(src, name))
								{
									this.player.copyAction(target, name, src);
								}
							}
						}
					}
					catch( e )
					{
						this.printf("\x00e3\x0083\x0097\x00e3\x0083\x00ad\x00e3\x0083\x0091\x00e3\x0083\x0086\x00e3\x0082\x00a3\x00e8\x00a8\x00ad\x00e5\x00ae\x009a\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s:%s\n", name, value, e);
					}
				}
			}
		}
	}

	function update( elm )
	{
		if ("action" in elm)
		{
			this.updateProperty(this.getUpdateTarget(), elm.action);
		}
	}

	function updateAfter( elm )
	{
		if ("action" in elm)
		{
			this.updatePropertyAfter(this.getUpdateTarget(), elm.action);
		}
	}

	function canWaitAction()
	{
		return this && this.player.isWorkingWaitAction(this.getWaitTarget());
	}

	function stopAction()
	{
		if (this)
		{
			this.player.stopAction(this.getWaitTarget());
		}
	}

	function createWait( mode = 0 )
	{
		if (this.canWaitAction())
		{
			return {
				checkfunc = this.canWaitAction.bindenv(this),
				stopfunc = this.stopAction.bindenv(this)
			};
		}
	}

	function objUpdate( elm )
	{
		this.update(elm);
	}

	function objUpdateAfter( elm )
	{
		this.updateAfter(elm);
	}

	function objUpdateAll( elm )
	{
		this.objUpdate(elm);
		this.objUpdateAfter(elm);
	}

}

class this.EnvCameraObject extends this.EnvObject
{
	scalex = 1.0;
	scaley = 1.0;
	cameraoffsetx = 0;
	cameraoffsety = 0;
	cameraoffsetz = -100;
	cameraoffsetzmax = 1000;
	camerarh = false;
	constructor( player, name )
	{
		::EnvObject.constructor(player, name, "camera");
		this.scalex = player.scalex;
		this.scaley = player.scaley;
		this.cameraoffsetx = player.cameraoffsetx;
		this.cameraoffsety = player.cameraoffsety;
		this.cameraoffsetz = player.cameraoffsetz;
		this.cameraoffsetzmax = player.cameraoffsetzmax;
		this.camerarh = player.camerarh;
	}

	function init()
	{
		this.player.stopAction(this, true);
		this._cameraox = 0;
		this._cameraoy = 0;
		this._shiftx = 0;
		this._shifty = 0;
		this._camerax = 0;
		this._cameray = 0;
		this._cameraz = 0;
		this._camerazoom = 100;
		this._camerarotate = 0;
		this._zoomx = 100;
		this._zoomy = 100;
		this._zcenterx = 100;
		this._zcentery = 100;
		this._windstart = 0;
		this._windgoal = 0;
		this._windspeed = 0;
		this._windmin = 0;
		this._windmax = 0;
		this._msgoffx = 0;
		this._msgoffy = 0;
	}

	function updateCamera()
	{
		if (this.player)
		{
			this.player.updateCamera();
		}
	}

	_cameraox = 0;
	function setCameraox( v )
	{
		this._cameraox = v;
		this.updateCamera();
	}

	function getCameraox()
	{
		return this._cameraox;
	}

	_cameraoy = 0;
	function setCameraoy( v )
	{
		this._cameraoy = v;
		this.updateCamera();
	}

	function getCameraoy()
	{
		return this._cameraoy;
	}

	_shiftx = 0;
	function setShiftx( v )
	{
		this._shiftx = v;
		this.updateCamera();
	}

	function getShiftx()
	{
		return this._shiftx;
	}

	_shifty = 0;
	function setShifty( v )
	{
		this._shifty = v;
		this.updateCamera();
	}

	function getShifty()
	{
		return this._shifty;
	}

	_camerax = 0;
	function setCamerax( v )
	{
		if (this._camerax != v)
		{
			this._camerax = v;
			this.updateCamera();
		}
	}

	function getCamerax()
	{
		return this._camerax;
	}

	_cameray = 0;
	function setCameray( v )
	{
		if (this._cameray != v)
		{
			this._cameray = v;
			this.updateCamera();
		}
	}

	function getCameray()
	{
		return this._cameray;
	}

	_cameraz = 0;
	function setCameraz( v )
	{
		if (this._cameraz != v)
		{
			this._cameraz = v;
			this.updateCamera();
		}
	}

	function getCameraz()
	{
		return this._cameraz;
	}

	_camerazoom = 100;
	function setCamerazoom( v )
	{
		if (this._camerazoom != v)
		{
			this._camerazoom = v;
			this.updateCamera();
		}
	}

	function getCamerazoom()
	{
		return this._camerazoom;
	}

	_camerarotate = 0;
	function setCamerarotate( v )
	{
		if (this._camerarotate != v)
		{
			this._camerarotate = v;
			this.updateCamera();
		}
	}

	function getCamerarotate()
	{
		return this._camerarotate;
	}

	_zoomx = 100;
	function setZoomx( v )
	{
		if (this._zoomx != v)
		{
			this._zoomx = v;
			this.updateCamera();
		}
	}

	function getZoomx()
	{
		return this._zoomx;
	}

	_zoomy = 100;
	function setZoomy( v )
	{
		if (this._zoomy != v)
		{
			this._zoomy = v;
			this.updateCamera();
		}
	}

	function getZoomy()
	{
		return this._zoomy;
	}

	_zcenterx = 100;
	function setZcenterx( v )
	{
		if (this._zcenterx != v)
		{
			this._zcenterx = v;
			this.updateCamera();
		}
	}

	function getZcenterx()
	{
		return this._zcenterx;
	}

	_zcentery = 100;
	function setZcentery( v )
	{
		if (this._zcentery != v)
		{
			this._zcentery = v;
			this.updateCamera();
		}
	}

	function getZcentery()
	{
		return this._zcentery;
	}

	function updateWind()
	{
		this.player.updateWind();
	}

	_windstart = 0;
	function setWindstart( v )
	{
		if (this._windstart != v)
		{
			this._windstart = v;
			this.updateWind();
		}
	}

	function getWindstart()
	{
		return this._windstart;
	}

	_windgoal = 0;
	function setWindgoal( v )
	{
		if (this._windgoal != v)
		{
			this._windgoal = v;
			this.updateWind();
		}
	}

	function getWindgoal()
	{
		return this._windgoal;
	}

	_windspeed = 0;
	function setWindspeed( v )
	{
		if (this._windspeed != v)
		{
			this._windspeed = v;
			this.updateWind();
		}
	}

	function getWindspeed()
	{
		return this._windspeed;
	}

	_windmin = 0;
	function setWindmin( v )
	{
		if (this._windmin != v)
		{
			this._windmin = v;
			this.updateWind();
		}
	}

	function getWindmin()
	{
		return this._windmin;
	}

	_windmax = 0;
	function setWindmax( v )
	{
		if (this._windmax != v)
		{
			this._windmax = v;
			this.updateWind();
		}
	}

	function getWindmax()
	{
		return this._windmax;
	}

	function updateMessage()
	{
		if (this.player != null)
		{
			this.player.setMsgOffset(this._msgoffx, this._msgoffy);
		}
	}

	_msgoffx = 0;
	function setMsgoffx( v )
	{
		if (this._msgoffx != v)
		{
			this._msgoffx = v;
			this.updateMessage();
		}
	}

	function getMsgoffx()
	{
		return this._msgoffx;
	}

	_msgoffy = 0;
	function setMsgoffy( v )
	{
		if (this._msgoffy != v)
		{
			this._msgoffy = v;
			this.updateMessage();
		}
	}

	function getMsgoffy()
	{
		return this._msgoffy;
	}

}

class this.EnvLayerObject extends this.EnvObject
{
	camera = null;
	cameraMode = 0;
	visible = 0;
	constructor( player, name, cname, classInfo, camera )
	{
		::EnvObject.constructor(player, name, cname);
		this.camera = camera.weakref();
	}

	function getUpdateTarget()
	{
		return this.targetLayer;
	}

	function pauseMotion( state )
	{
		if (this.targetLayer != null)
		{
			this.targetLayer.pauseMotion(state);
		}
	}

	function onVoiceFlip( level, value )
	{
		if (this.targetLayer != null)
		{
			if (this.targetLayer.isEmote())
			{
				this.targetLayer.setVariable("face_talk", value);
			}
			else if (this.targetLayer.isImage() || this.targetLayer.isMotion())
			{
				this.targetLayer.setVariable("lip", value);
			}
		}
	}

	targetLayer = null;
	hideLayer = null;
	function getLinkTarget()
	{
		if (this.targetLayer != null)
		{
			return this.targetLayer;
		}
		else if (this.hideLayer != null)
		{
			return this.hideLayer;
		}
	}

	transTargetLayer = null;
	linkTarget = null;
	function createLayer( src = null )
	{
		local layer = this.EnvGraphicLayer(this, this.name);

		if (src != null)
		{
			layer.assign(src);
		}

		layer.setMsgVisible(this._msgvisible);
		return layer;
	}

	function updateSpeed()
	{
		if (this.targetLayer != null)
		{
			this.targetLayer.updateSpeed();
		}

		if (this.hideLayer != null)
		{
			this.hideLayer.updateSpeed();
		}
	}

	function prepareTransition()
	{
		this.transTargetLayer = null;

		if (this.targetLayer != null)
		{
			this.transTargetLayer = this.targetLayer;
			this.targetLayer = this.createLayer(this.targetLayer);
			this.transTargetLayer.cutoffcamera();
			this.transTargetLayer.actstart = false;
			this.player.addTransLayer(this.transTargetLayer);
		}

		if (this.hideLayer != null)
		{
			local transHideLayer = this.hideLayer;
			this.hideLayer = this.createLayer(this.hideLayer);
			transHideLayer.cutoffcamera();
			transHideLayer.actstart = false;
			this.player.addTransLayer(transHideLayer);
		}
	}

	function doneTransition( from = null )
	{
		if (from == null)
		{
			this.transTargetLayer = null;
		}
		else if (from == this.hideLayer)
		{
			this.hideLayer = null;
		}
	}

	function initTarget()
	{
		if (this.targetLayer == null)
		{
			this.targetLayer = this.createLayer();
			this.targetLayer.visible = true;
		}
	}

	function copyActionInfo( act, time, delay )
	{
		if (typeof act == "array")
		{
			local arrayAction = [];

			foreach( i in act )
			{
				if (i != null && typeof i == "table")
				{
					arrayAction.append(this.copyActionInfo(i, this.getval(i, "time"), delay));
				}
			}

			return arrayAction;
		}
		else if (typeof act == "table")
		{
			local action = {};

			foreach( name, value in act )
			{
				if (typeof value == "table")
				{
					action[name] <- clone value;
				}
				else
				{
					action[name] <- value;
				}
			}

			if (time != null)
			{
				action.time <- time;
			}

			if (delay != null)
			{
				action.delay <- delay;
			}

			return action;
		}

		return {};
	}

	function checkTrans()
	{
		return this && (this.player.inTransition() || this.targetLayer != null && (this.player.hasAction(this.targetLayer, "visvalue") || this.targetLayer.canDispSync()) || this.hideLayer != null && this.player.hasAction(this.hideLayer, "visvalue"));
	}

	function stopTrans()
	{
		if (this)
		{
			this.player.stopTransition();

			if (this.targetLayer != null)
			{
				this.player.delAction(this.targetLayer, "visvalue");
				this.targetLayer.dispSync();
			}

			if (this.hideLayer != null)
			{
				this.player.delAction(this.hideLayer, "visvalue");
			}
		}
	}

	function getWaitTarget()
	{
		if (this.targetLayer != null && this.targetLayer.visible)
		{
			return this.targetLayer;
		}
		else if (this.hideLayer != null && this.hideLayer.visible)
		{
			return this.hideLayer;
		}
	}

	function canWaitMovie()
	{
		local target = this.getWaitTarget();
		return this && target != null && target.canWaitMovie();
	}

	function stopMovie()
	{
		if (this)
		{
			local target = this.getWaitTarget();

			if (target != null)
			{
				target.stopMovie();
			}
		}
	}

	function createWait( mode = 0 )
	{
		switch(mode)
		{
		case 1:
			if (this.checkTrans())
			{
				return {
					checkfunc = this.checkTrans.bindenv(this),
					stopfunc = this.stopTrans.bindenv(this)
				};
			}

			break;

		case 2:
			if (this.canWaitMovie())
			{
				return {
					checkfunc = this.canWaitMovie.bindenv(this),
					stopfunc = this.stopMovie.bindenv(this)
				};
			}

			break;

		default:
			return ::EnvObject.createWait(mode);
		}
	}

	function recalcPosition()
	{
		if (this.targetLayer != null)
		{
			this.targetLayer.updateAffine();
		}

		if (this.hideLayer != null)
		{
			this.hideLayer.updateAffine();
		}
	}

	function recalcWind()
	{
		if (this.targetLayer != null)
		{
			this.targetLayer.recalcWind();
		}

		if (this.hideLayer != null)
		{
			this.hideLayer.recalcWind();
		}
	}

	function setVariable( name, value, time = 0, accel = 0 )
	{
		if (this.targetLayer != null && this.targetLayer.getVisible())
		{
			this.targetLayer.setVariable(name, value, time, accel);
		}
	}

	_msgvisible = false;
	function setMsgVisible( v )
	{
		if (this._msgvisible != v)
		{
			this._msgvisible = v;

			if (this.targetLayer != null)
			{
				this.targetLayer.setMsgVisible(v);
			}

			if (this.hideLayer != null)
			{
				this.hideLayer.setMsgVisible(v);
			}
		}
	}

	function dispSync()
	{
		if (this.targetLayer != null)
		{
			this.targetLayer.dispSync();
		}
	}

	function updateImage( elm )
	{
		if (this.targetLayer != null)
		{
			if ("redraw" in elm)
			{
				local redraw = elm.redraw;
				local clip = ::getval(redraw, "clip");
				this.targetLayer.resetClip();

				if (clip != null && "left" in clip)
				{
					this.targetLayer.setClip(this.getint(clip, "left", 0), this.getint(clip, "top", 0), this.getint(clip, "width", 0), this.getint(clip, "height", 0));
				}

				local imageFile = ::getval(redraw, "imageFile");
				this.targetLayer.loadImage(imageFile);
				this.targetLayer.recalcWind();
			}

			if ("class" in elm)
			{
				local classInfo = this.player.getClassInfo(elm["class"]);
				this.targetLayer.cameraMode = this.cameraMode = classInfo.cameraMode;
				this.targetLayer.absoluteBase = ::getint(classInfo, "absoluteBase", 0);
			}

			if ("type" in elm)
			{
				this.targetLayer.setType(elm.type);
			}

			::EnvObject.update(elm);
			this.targetLayer.actstart = true;

			if (this.player instanceof this.ScenePlayer)
			{
				this.player.onLayerUpdateImage(this);
			}
		}
	}

	function update( elm )
	{
		this.visible = (elm.showmode & 1) != 0;

		if (this.visible)
		{
			this.initTarget();
			this.updateImage(elm);
		}
		else
		{
			if (this.targetLayer != null)
			{
				this.targetLayer.visible = false;
				this.targetLayer = null;
			}

			if (this.transTargetLayer != null && "hideact" in elm)
			{
				this.updateProperty(this.transTargetLayer, elm.hideact);
			}
		}
	}

	function updateAfter( elm )
	{
		if (this.targetLayer != null && "action" in elm)
		{
			this.updatePropertyAfter(this.targetLayer, elm.action);
		}

		if ("link" in elm)
		{
			this.linkTarget = elm.link;
		}
	}

	function updateSource( source, redraw )
	{
		if (this.targetLayer != null)
		{
			if (source == null || source == this.name || source == this.linkTarget)
			{
				local lt;

				if (this.linkTarget != "" && this.linkTarget in this.player.env.objects)
				{
					local obj = this.player.env.objects[this.linkTarget];

					if (obj != null && (obj instanceof this.EnvLayerObject))
					{
						lt = obj.getLinkTarget();
					}
				}

				this.targetLayer.setLink(lt);
			}
		}
	}

	function objUpdate( elm )
	{
		if (this.player.transMode || !("trans" in elm))
		{
			this.update(elm);
		}
		else
		{
			if (this.hideLayer != null)
			{
				this.hideLayer = null;
			}

			this.visible = (elm.showmode & 1) != 0;

			switch(elm.showmode)
			{
			case 1:
				this.initTarget();
				this.updateImage(elm);
				break;

			case 2:
				this.updateImage(elm);
				break;

			case 3:
				this.hideLayer = this.targetLayer;
				this.targetLayer = null;

				if (this.hideLayer != null)
				{
					this.targetLayer = this.createLayer(this.hideLayer);
					this.targetLayer.assignLink(this.hideLayer);
					this.targetLayer.visible = false;
					this.hideLayer.order--;
				}
				else
				{
					this.initTarget();
				}

				this.updateImage(elm);
				break;
			}
		}
	}

	function objUpdateAfter( elm )
	{
		if (this.player.transMode)
		{
			this.player.entryAfter(this, elm);
			return;
		}

		if (!("trans" in elm))
		{
			this.updateAfter(elm);
		}
		else
		{
			switch(elm.showmode)
			{
			case 1:
				this.updateAfter(elm);
				break;

			case 2:
				this.updateAfter(elm);
				this.hideLayer = this.targetLayer;
				this.targetLayer = null;
				break;

			case 3:
				this.updateAfter(elm);
				break;
			}

			if (this.hideLayer != null && "hideact" in elm)
			{
				this.hideLayer.actstart = false;
				this.updateProperty(this.hideLayer, elm.hideact);
				this.hideLayer.actstart = true;
			}
		}

		this.player.updateSource(this.name, "redraw" in elm);
	}

	function checkMsgwinLayer()
	{
		return this.cameraMode & 16 && this.visible;
	}

}

class this.EnvMusicObject extends this.EnvObject
{
	music = null;
	defaultLoop = false;
	constructor( player, name, cname, classInfo )
	{
		::EnvObject.constructor(player, name, cname);
		this.music = this.Music(name == "bgm" ? "bgm" : "se");
		this.initVolume();
		this.defaultLoop = classInfo.loop;
	}

	function destructor()
	{
		this.music.stop();
		::EnvObject.destructor();
	}

	function isPlayingLoop()
	{
		return this.music.playing && this._loop;
	}

	function getPlaying()
	{
		return this.music.playing;
	}

	_filename = null;
	_volume = null;
	_loop = null;
	function play( filename, loop, volume = 100, start = null, time = 0 )
	{
		filename = this.evalStorage(filename);
		local change = this._filename != filename || this._loop != loop || this._volume != volume;

		if (this._filename != filename)
		{
			if (this.player != null)
			{
				this.player.onChangeMusic(filename);
			}
		}

		this._filename = filename;
		this._loop = loop;

		if (change || !this.music.playing)
		{
			this.music.play(filename, loop ? -1 : 0, volume, start, {
				pan = this._pan,
				fade = this._fade,
				pitch = this._pitch
			}, time);
		}
	}

	function stop( time = 0 )
	{
		this.music.stop(time);
	}

	function pause( time = 0 )
	{
		this.music.pause(time);
	}

	function restart( time = 0 )
	{
		this.music.restart(time);
	}

	function update( elm )
	{
		local trans = "trans" in elm ? elm.trans : null;
		local time = ::tonumber(this.getval(trans, "time", 0)) * this.player.actSkipSpeed;

		if (("replay" in elm) && "state" in elm.replay)
		{
			local replay = elm.replay;
			local loop = "loop" in replay ? replay.loop : this.defaultLoop;

			switch(replay.state)
			{
			case 0:
				this.stop(time);
				break;

			case 1:
				this.play(this.getval(replay, "filename"), loop, this.getval(replay, "volume"), null, time);
				break;
			}
		}

		if ("update" in elm)
		{
			local update = elm.update;

			if (this.getPlaying())
			{
				switch(update.state)
				{
				case 1:
					this.restart(time);
					break;

				case 2:
					this.pause(time);
					break;
				}
			}
		}

		::EnvObject.update(elm);
	}

	function createWait( mode )
	{
		if (mode == 1)
		{
			if (this.music.fading)
			{
				return {
					function checkfunc() : ( music )
					{
						return music && music.fading;
					}

					function stopfunc() : ( music )
					{
						music.fadeStop();
					}

				};
			}
		}
		else
		{
			return ::EnvObject.createWait(mode);
		}
	}

	function initVolume()
	{
	}

	_fade = 100;
	function getFade()
	{
		return this._fade;
	}

	function setFade( v )
	{
		if (this._fade != v)
		{
			this._fade = v;
			this.music.fade = this._fade;
		}
	}

	_pitch = 100;
	function getPitch()
	{
		return this._pitch;
	}

	function setPitch( v )
	{
		if (this._pitch != v)
		{
			this._pitch = v;
			this.music.pitch = this._pitch;
		}
	}

	_pan = 0;
	function getPan()
	{
		return this._pan;
	}

	function setPan( v )
	{
		if (this._pan != v)
		{
			this._pan = v;
			this.music.pan = this._pan;
		}
	}

	systemPauseFlag = false;
	function sysPause( all = false )
	{
		if ((all || this.name != "bgm") && this.music.getPlaying())
		{
			this.systemPauseFlag = true;
			this.pause();
		}
		else
		{
			this.systemPauseFlag = false;
		}
	}

	function sysRestart()
	{
		if (this.systemPauseFlag)
		{
			this.restart();
		}

		this.systemPauseFlag = false;
	}

}

class this.EnvSoundObject extends this.EnvObject
{
	sound = null;
	skipFlag = false;
	constructor( player, name, cname, classInfo )
	{
		::EnvObject.constructor(player, name, cname);
		this.sound = this.MultiSound(classInfo.track);
		this.skipFlag = classInfo.skipFlag;
		this.initVolume();
	}

	function destructor()
	{
		this.sound.stop();
		this.sound = null;
		::EnvObject.destructor();
	}

	function getPlaying()
	{
		return this.sound.getPlaying();
	}

	function play( filename, volume = 100, time = 0 )
	{
		if (!this.player.isSkip() || !this.skipFlag)
		{
			filename = this.evalStorage(filename);
			this.sound.play(filename, volume, {
				pan = this._pan,
				pitch = this._pitch,
				fade = this._fade
			}, time);
		}
	}

	function stop( time = 0 )
	{
		this.sound.stop(time);
	}

	function update( elm )
	{
		if ("stop" in elm)
		{
			this.stop(::tonumber(this.getval(elm, "stop", 0)) * this.player.actSkipSpeed);
		}

		if ("replay" in elm)
		{
			local replay = elm.replay;
			this.play(elm.replay.filename, elm.replay.volume);
		}

		::EnvObject.update(elm);
	}

	function createWait( mode )
	{
		switch(mode)
		{
		case 1:
			if (this.sound.playing)
			{
				return {
					function checkfunc() : ( sound )
					{
						return sound && sound.playing;
					}

					function stopfunc() : ( sound )
					{
						if (sound)
						{
							sound.stop();
						}
					}

				};
			}

			break;

		case 2:
			if (this.sound.allPlaying)
			{
				return {
					function checkfunc() : ( sound )
					{
						return sound && sound.allplaying;
					}

					function stopfunc() : ( sound )
					{
						if (sound)
						{
							sound.stop();
						}
					}

				};
			}

			break;

		default:
			return ::EnvObject.createWait(mode);
		}
	}

	function initVolume()
	{
	}

	_fade = 100;
	function getFade()
	{
		return this._fade;
	}

	function setFade( v )
	{
		if (this._fade != v)
		{
			this._fade = v;
			this.sound.fade = this._fade;
		}
	}

	_pitch = 100;
	function getPitch()
	{
		return this._pitch;
	}

	function setPitch( v )
	{
		if (this._pitch != v)
		{
			this._pitch = v;
			this.sound.pitch = this._pitch;
		}
	}

	_pan = 0;
	function getPan()
	{
		return this._pan;
	}

	function setPan( v )
	{
		if (this._pan != v)
		{
			this._pan = v;
			this.sound.pan = this._pan;
		}
	}

}

