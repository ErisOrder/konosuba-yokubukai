class this.BackLayer extends ::Layer
{
	base = null;
	constructor( screen = null, color = 4278190080, priority = 0 )
	{
		::Layer.constructor(screen);
		local bounds = ::getScreenBounds(screen);
		this.base = ::FillRect(this);
		this.base.setCoord(bounds.left, bounds.top);
		this.base.setSize(bounds.width, bounds.height);
		this.base.setColor(this.ARGB2RGBA(color));
		this.base.visible = true;
		this.priority = priority;
		this.visible = true;
	}

	function setOpacity( v )
	{
		this.base.setOpacity(v);
	}

}

class this.EnvLayerFolder extends ::LayerFolder
{
	width = this.tofloat(1920);
	height = this.tofloat(1080);
	clip = true;
	sw = 0;
	sh = 0;
	constructor( screen, scale, clip = true )
	{
		::LayerFolder.constructor(screen);
		this.setScale(scale, scale);
		this.clip = clip;
		this.sw = this.width * scale;
		this.sh = this.height * scale;
		this.setOffset(0, 0);
		this.smoothing = true;
		this.visible = true;
	}

	function setOffset( x, y )
	{
		::LayerFolder.setOffset(x, y);

		if (this.clip)
		{
			this.setBaseClip(-x - this.sw / 2, -y - this.sh / 2, this.sw, this.sh);
		}
	}

	function getBounds()
	{
		return {
			left = -this.width / 2,
			top = -this.height / 2,
			width = this.width,
			height = this.height
		};
	}

}

class this.EnvPlayerBase extends ::Object
{
	screen = null;
	screenpr = null;
	envscale = 1.0;
	envclip = true;
	back = null;
	base = null;
	constructor( baseScreen, envclip = true )
	{
		::Object.constructor();

		if (0 || baseScreen == null || (baseScreen instanceof ::Screen))
		{
			this.screen = baseScreen != null ? baseScreen.weakref() : null;
		}
		else
		{
			this.screen = ::Screen(::SCWIDTH, ::SCHEIGHT);
			this.screenpr = ::ScreenProjection(baseScreen, this.screen);
			local bounds = ::getScreenBounds(baseScreen);
			local width = this.screenpr.width;
			local height = this.screenpr.height;
			this.screenpr.setZoom(this.min(bounds.width / width, bounds.height / height));
			this.screenpr.setCenter(width / 2, height / 2);
			this.screenpr.setOffset(width / 2, height / 2);
			this.screenpr.smoothing = true;
			this.screenpr.visible = true;
		}

		this.envclip = envclip;
		local bounds = ::getScreenBounds(this.screen);
		this.envscale = ::min(bounds.width / 1920, bounds.height / 1080);
		this.back = ::BackLayer(this.screen);
		this.back.setPriority(4);
		this.base = ::EnvLayerFolder(this.screen, this.envscale, envclip);
		this.base.setPriority(6);
		this.translayers = [];
	}

	function destructor()
	{
		this.setAfterImage();
		this.stopTransition();
		this.base = null;
		this.back = null;
		this.screen = null;
		this.screenpr = null;
		::Object.destructor();
	}

	function getScreen()
	{
		return this.base;
	}

	_visible = true;
	function getVisible()
	{
		return this._visible;
	}

	function setVisible( v )
	{
		if (this._visible != v)
		{
			this._visible = v;
			this.base.setVisible(v);

			if (this.transbase != null)
			{
				this.transbase.setVisible(v);
			}
		}
	}

	function getCurrentSecond()
	{
		return ::System.getSystemSecond();
	}

	function getLocalDateTime()
	{
		return ::System.getLocalDateTime();
	}

	function getPassedFrame()
	{
		return ::System.getPassedFrame();
	}

	function getMsgOwner()
	{
		return this.getScreen();
	}

	function getMsgPriority()
	{
		return 12;
	}

	function getMsgScale()
	{
		return 1.0;
	}

	afterimages = null;
	afterfolder = null;
	function setAfterImage( level = 0 )
	{
		if (level == 0)
		{
			this.afterimages = null;
			this.afterfolder = null;
		}
		else
		{
			level += 1;
			local screen = this.getMsgOwner();
			local priority = this.getMsgPriority();
			local scale = this.getMsgScale();
			local w = this.SCWIDTH * scale;
			local h = this.SCHEIGHT * scale;

			if (this.afterimages == null)
			{
				this.afterimages = [];
				this.afterfolder = this.LayerFolder(screen);
				this.afterfolder.setScale(scale, scale);
				this.afterfolder.setOffset(w / 2, h / 2);
				this.afterfolder.setPriority(priority - 2);
				this.afterfolder.visible = true;
			}

			while (this.afterimages.len() > level)
			{
				this.afterimages.erase(this.afterimages.len() - 1);
			}

			while (this.afterimages.len() < level)
			{
				local capture = ::Capture(screen, w, h);
				capture.setOffset(w / 2, h / 2);
				capture.setPriority(priority - 1);
				local captured = ::Captured(this.afterfolder, capture);
				this.afterimages.append({
					capture = capture,
					captured = captured
				});
			}
		}
	}

	function updateAfterImage()
	{
		if (this.afterimages != null)
		{
			local l = this.afterimages.len();
			local op = 256;
			local down = 0.60000002;
			local priority = this.getMsgPriority();

			foreach( i, info in this.afterimages )
			{
				info.capture.visible = i == 0;
				info.captured.visible = i != 0;
				info.captured.opacity = op;
				info.captured.priority = i;
				op *= down;
			}

			local a = this.afterimages[0];
			this.afterimages.erase(0);
			this.afterimages.append(a);
		}
	}

	btLayer = null;
	function hideBlackLayer()
	{
		if (this.btLayer != null)
		{
			this.btLayer = null;
		}
	}

	function doBlackTrans( elm )
	{
		this.startTransition(elm);
		local canskip = ::getval(elm, "canskip", true);

		if (this.waitTransition(canskip) == 0)
		{
			this.waitTime(::getval(elm, "wait", 0), canskip);
		}
	}

	function blackTransBegin( elm )
	{
		local color = 4278190080 | ::getint(elm, "bgcolor", 0);
		this.btLayer = ::BackLayer(this.base, color);
		this.btLayer.setPriority(10000000);
		this.btLayer.visible = true;
		this.doBlackTrans(elm);
	}

	function blackTransEnd( elm )
	{
		if (this.btLayer == null)
		{
			this.stopTransition();
		}
		else
		{
			this.doBlackTrans(elm);
			this.hideBlackLayer();
		}
	}

	transitionTime = null;
	transitionTick = null;
	transcapture = null;
	transcaptured = null;
	transrule = null;
	transbase = null;
	translayers = null;
	msgchange = null;
	transMode = 0;
	onTransitionCompleted = null;
	function getScreenCapture( screen, priority )
	{
		local bounds = ::getScreenBounds(screen);
		local capture = ::Capture(screen, bounds.width, bounds.height);
		capture.setOffset(-bounds.left, -bounds.top);
		capture.setPriority(priority);
		capture.visible = true;
		::suspend();
		this.checkSkipStop();
		capture.visible = false;
		return capture;
	}

	function addTransLayer( layer )
	{
		this.translayers.append(layer);
	}

	function entryTransitionLayer( layer )
	{
		if (layer != null && layer.owner == this.transbase)
		{
			layer.owner = this.base;
			local proxy = ::LayerProxy(this.transbase, layer);
			proxy.priority = layer.priority;
			this.translayers.append(proxy);
		}
	}

	function doneTransitionLayer( layer )
	{
		if (layer != null && layer.owner != this.base)
		{
			layer.owner = this.base;
		}
	}

	function onPrepareTransition( msgchange )
	{
	}

	function onSetupTransition( msgchange )
	{
	}

	function onCompleteTransition( msgchange )
	{
	}

	function setupTransition( msgchange = null )
	{
		this.stopTransition();
		this.transbase = this.base;
		this.transbase.setPriority(2);
		this.base = ::EnvLayerFolder(this.screen, this.envscale, this.envclip);
		this.base.setVisible(this._visible);
		this.base.setPriority(6);
		this.onPrepareTransition(msgchange);

		if (this.afterfolder != null)
		{
			this.afterfolder.owner = this.getMsgOwner();

			foreach( info in this.afterimages )
			{
				info.capture.owner = this.getMsgOwner();
			}
		}

		local bounds = ::getScreenBounds(this.screen);
		this.transcapture = ::Capture(this.screen, bounds.width, bounds.height);
		this.transcapture.setOffset(-bounds.left, -bounds.top);
		this.transcapture.setPriority(3);
		this.transcapture.visible = true;
		this.transcaptured = ::Captured(this.screen, this.transcapture);
		this.transcaptured.setOffset(-bounds.left, -bounds.top);
		this.transcaptured.setPriority(11);
		this.transcaptured.opacity = 255;
		this.transcaptured.visible = true;
		this.transMode = 1;
		this.msgchange = msgchange;
		this.onSetupTransition(msgchange);
	}

	function calcTransitionSpeed( option = null )
	{
		return 1.0;
	}

	function inTransition()
	{
		return this.transitionTime != null;
	}

	function startTransition( trans = null, onTransitionCompleted = null, option = null )
	{
		this.onTransitionCompleted = onTransitionCompleted;
		this.transMode = 0;

		if (this.transcapture != null)
		{
			this.transitionTime = this.getint(trans, "time", 0) * this.calcTransitionSpeed(option);

			if (this.transitionTime > 0)
			{
				if (trans != null)
				{
					local method = this.getval(trans, "method");

					if (method == "universal")
					{
						local rule = this.getval(trans, "rule");
						local useCapture = false;

						if (rule != null)
						{
							if (rule == "capture" && ::BASESCALE == 1.0)
							{
								this.suspend();
								this.transcapture.visible = false;
								local _scale = this.getfloat(trans, "blurscale", 8.0);
								local _blurX = this.getfloat(trans, "blurx", 0.80000001);
								local _blurY = this.getfloat(trans, "blury", 1.6);
								local _rawimage = ::RawImage(this.SCWIDTH / _scale, this.SCHEIGHT / _scale);
								this.transcapture.storeThumbnail(_rawimage, _scale);
								_rawimage.grayscale();
								_rawimage.boxBlur(_blurX, _blurY);
								local _swidth = _rawimage.getWidth();
								local _sheight = _rawimage.getHeight();
								local _base = 128;
								local _dwidth = _swidth;
								local _dheight = _sheight;

								while (true)
								{
									if (_dwidth <= _base)
									{
										_dwidth = _base;
										break;
									}

									_base = _base << 1;
								}

								for( _base = 128; true; _base = _base << 1 )
								{
									if (_dheight <= _base)
									{
										_dheight = _base;
										break;
									}
								}

								local _powimage = ::RawImage(_dwidth, _dheight);
								_powimage.stretchCopy(0, 0, _dwidth, _dheight, _rawimage, 0, 0, _swidth, _sheight);
								this.transrule = _powimage;
								useCapture = true;
							}
							else
							{
								local image;
								image = this.loadImageData(rule);

								if (image != null)
								{
									this.transrule = ::Image(image);
								}
								else
								{
									this.printf("XXX\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x00ab\x00e7\x0094\x00bb\x00e5\x0083\x008f\x00e8\x00aa\x00ad\x00e3\x0081\x00bf\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", rule);
								}
							}

							if (this.transrule != null)
							{
								if (useCapture)
								{
									this.transcaptured.setOpacityMapRaw(this.transrule, this.getint(trans, "vague", 64));
								}
								else
								{
									this.transcaptured.setOpacityMap(this.transrule, this.getint(trans, "vague", 64));
								}

								this.transcaptured.opacityMapSmoothing = true;
								this.transcaptured.setOpacityMapRepeat(1, 1);
							}
							else
							{
								this.printf("XXX\x00e3\x0083\x00ab\x00e3\x0083\x00bc\x00e3\x0083\x00ab\x00e7\x0094\x00bb\x00e5\x0083\x008f\x00e3\x0081\x00ae\x00e7\x0094\x009f\x00e6\x0088\x0090\x00e3\x0081\x00ab\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", rule);
							}
						}
					}
				}

				this.transitionTick = 0;
			}
			else
			{
				this.stopTransition();
			}
		}
	}

	function stopTransition()
	{
		if (typeof this.onTransitionCompleted == "function")
		{
			this.onTransitionCompleted();
		}

		this.onTransitionCompleted = null;

		if (this.transcapture != null)
		{
			this.base.setPriority(6);
			this.transbase = null;
			this.transcaptured = null;
			this.transcapture = null;
			this.transrule = null;
			this.transMode = 0;
			this.transitionTick = null;
			this.transitionTime = null;
			this.onCompleteTransition(this.msgchange);
			this.msgchange = null;
		}

		this.translayers.clear();
	}

	function updateTransition( diff )
	{
		if (this.transitionTick != null)
		{
			this.transitionTick += diff;

			if (this.transitionTick < this.transitionTime)
			{
				foreach( layer in this.translayers )
				{
					if (layer instanceof ::AffineLayer)
					{
						layer.updateAffine();
					}
				}

				this.transcaptured.opacity = 255 * (1 - this.transitionTick / this.transitionTime);
			}
			else
			{
				this.stopTransition();
			}
		}
	}

	function waitTransition( canSkip = true, timeout = null )
	{
		return this.waitFunction(canSkip, this.inTransition.bindenv(this), this.stopTransition.bindenv(this), timeout);
	}

	function systemTransition( trans = null, canSkip = false )
	{
		this.startTransition(trans, null, "system");
		local click;

		if (canSkip)
		{
			this.waitTransition();
		}
		else
		{
			while (this.inTransition())
			{
				this.sysSync();
			}
		}
	}

	function snap( image, sceneName, point = 0, update = null )
	{
		local baseBack = this.base;
		local snapenv = this.Environment(this);
		this.base = ::EnvLayerFolder(this.screen, this.envscale, this.envclip);
		this.base.setPriority(2);
		local storage = this.getStorage(sceneName);
		local label = this.getLabel(sceneName);

		try
		{
			local scnStorage = this.StorageData(storage);
			local scenario = scnStorage.findScene(label);

			if (scenario != null && "lines" in scenario)
			{
				local state;

				if (("selects" in scenario) && scenario.selects.len() > 0)
				{
					local newcur = 0;
					local obj;

					for( obj = scenario.lines[newcur]; obj != null; newcur++ )
					{
						if (typeof obj == "array" && typeof obj[0] == "integer" && obj[0] >= point)
						{
							state = obj[1];
							break;
						}
					}
				}
				else
				{
					local newcur = 0;
					local obj;
					local find;

					for( obj = scenario.lines[newcur]; obj != null; newcur++ )
					{
						if (typeof obj == "integer")
						{
							if (find)
							{
								if ("texts" in scenario)
								{
									local text = scenario.texts[obj - 1];

									if (text != null)
									{
										state = text[5];
									}
								}

								break;
							}
						}
						else if (typeof obj == "array")
						{
							if (typeof obj[0] == "integer" && obj[0] >= point)
							{
								state = obj[1];
								find = true;
							}
						}
					}
				}

				if (state != null)
				{
					snapenv.onRestore(state, true);
				}
				else
				{
					this.printf("\x00e9\x0081\x00a9\x00e5\x0088\x0087\x00e3\x0081\x00aa\x00e3\x0082\x00b9\x00e3\x0083\x0086\x00e3\x0083\x00bc\x00e3\x0083\x0088\x00e3\x0081\x008c\x00e8\x00a6\x008b\x00e3\x0081\x00a4\x00e3\x0081\x008b\x00e3\x0082\x0089\x00e3\x0081\x00aa\x00e3\x0081\x0084\n");
				}
			}
		}
		catch( e )
		{
			this.printf("\x00e3\x0082\x00b9\x00e3\x0083\x008a\x00e3\x0083\x0083\x00e3\x0083\x0097\x00e7\x0094\x00a8\x00e3\x0082\x00b7\x00e3\x0083\x00bc\x00e3\x0083\x00b3\x00e8\x00aa\x00ad\x00e3\x0081\x00bf\x00e8\x00be\x00bc\x00e3\x0081\x00bf\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s\n", storage);
			::printException(e);
			snapenv = null;
			this.base = baseBack;
			return false;
		}

		if (update != null)
		{
			snapenv.objUpdate(update);
		}

		local bounds = ::getScreenBounds(this.screen);
		local capture = ::Capture(this.screen, bounds.width, bounds.height);
		capture.setOffset(-bounds.left, -bounds.top);
		capture.setPriority(3);
		capture.visible = true;
		::suspend();
		capture.visible = false;

		if (image instanceof ::RawImage)
		{
			capture.storeThumbnail(image, 2);
		}
		else if (typeof image == "table")
		{
			capture.storeThumbnail(image.data, image.width, image.height, 2);
		}

		snapenv = null;
		this.base = baseBack;
		return true;
	}

}

