function getScreenBounds( screen = null )
{
	return screen != null ? screen.getBounds() : ::System.getScreenBounds();
}

local bounds = ::getScreenBounds();
::BASEWIDTH <- bounds.width;
::BASEHEIGHT <- bounds.height;
::TARGET_SYSTEM <- "WIN";

switch("WIN")
{
case "PSP":
	::SCWIDTH <- 480;
	::SCHEIGHT <- 272;
	::DEBUG_FONTSIZE <- 16;
	::DLSIZE <- 524288;
	::DIALOG_SHIFT <- 20;
	break;

case "VITA":
	::SCWIDTH <- 960;
	::SCHEIGHT <- 544;
	::DEBUG_FONTSIZE <- 18;
	::DLSIZE <- 524288;
	::DIALOG_SHIFT <- 30;
	break;

default:
	::SCWIDTH <- 1920;
	::SCHEIGHT <- 1080;
	::DEBUG_FONTSIZE <- 24;
	::DIALOG_SHIFT <- 50;
	break;
}

::RESTRICTED_AGE <- 15;
this.mountPaths <- {};
function mountArchive( arcname, path = null )
{
	if (path == null)
	{
		path = arcname;
	}

	if (path != "")
	{
		if (path.charAt(path.len() - 1) != "/")
		{
			path += "/";
		}
	}

	this.printf("mountArchive:%s:%s\n", path, arcname);
	this.mountPaths[path] <- true;
	this.System.mountArchive(path, arcname + "_info" + this.ARCHIVE_INFO_EXT, arcname + "_body" + this.ARCHIVE_BODY_EXT);
}

function unmountArchive( path )
{
	if (path.charAt(path.len() - 1) != "/")
	{
		path += "/";
	}

	if (path in this.mountPaths)
	{
		this.printf("unmountArchive:%s\n", path);
		this.System.unmountArchive(path);
		delete this.mountPaths[path];
	}
}

this.mountArchive("config");
::init <- ::loadData("config/init.psb");

if (this.init != null)
{
	foreach( name, value in this.init.root.constant )
	{
		local global = ::getroottable();
		global[name] <- value;
	}

	if ("archives" in this.init.root)
	{
		foreach( name, value in this.init.root.archives )
		{
			this.mountArchive(name, value);
		}
		this.mountArchive("patch", "");
	}

	if (this.BASEWIDTH <= 640 && "screenShotSD" in this.init.root)
	{
		this.printf("init screenShot SD\n");
		::initScreenShot(this.init.root.screenShotSD);
	}
	else if (this.BASEWIDTH <= 1280 && "screenShotHD" in this.init.root)
	{
		this.printf("init screenShot HD\n");
		::initScreenShot(this.init.root.screenShotHD);
	}
	else if ("screenShot" in this.init.root)
	{
		this.printf("init screenShot\n");
		::initScreenShot(this.init.root.screenShot);
	}
}

this.specInit(::init != null ? ::init.root : null);
this.printf("%s:screen size:%s %s %s\n", this.TARGET_SYSTEM, this.BASEWIDTH, this.SCWIDTH, 1920);
::BASESCALE <- this.min(::BASEWIDTH / ::SCWIDTH, ::BASEHEIGHT / ::SCHEIGHT);

if (::TARGET_SYSTEM == "PSP" || ::TARGET_SYSTEM == "VITA")
{
	::baseScreen <- null;
}
else
{
	function setupZoom( owner )
	{
		local dialog = ::ConfirmDialog(owner);
		dialog.show("\x00e7\x0089\x00b9\x00e6\x00ae\x008a\x00e6\x008b\x00a1\x00e7\x00b8\x00ae\x00e3\x0083\x0081\x00e3\x0082\x00a7\x00e3\x0083\x0083\x00e3\x0082\x00af \x00e4\x00b8\x008a\x00e4\x00b8\x008b:\x00e6\x008b\x00a1\x00e7\x00b8\x00ae A:\x00e7\x00a2\x00ba\x00e5\x00ae\x009a B:\x00e3\x0082\x00ad\x00e3\x0083\x00a3\x00e3\x0083\x00b3\x00e3\x0082\x00bb\x00e3\x0083\x00ab");
		local result;
		local initZoom = owner.zoom;
		local zoom = initZoom;

		do
		{
			::sync();
			local ozoom = zoom;

			switch(this.getPadKey())
			{
			case this.KEY_OK:
				result = true;
				break;

			case this.KEY_CANCEL:
				result = false;
				break;

			case 64:
				zoom += 0.0099999998;

				if (zoom > 1)
				{
					zoom = 1;
				}

				break;

			case 128:
				zoom -= 0.0099999998;

				if (zoom < 0.5)
				{
					zoom = 0.5;
				}

				break;
			}

			if (zoom != ozoom)
			{
				owner.setZoom(zoom);
			}
		}
		while (result == null);

		if (!result)
		{
			owner.setZoom(initZoom);
		}

		dialog.hide();
	}


	if (!0 && ::BASEWIDTH <= ::SCWIDTH)
	{
		this.printf("sd screen\n");
		class this.ScreenBase extends ::Screen
		{
			projection = null;
			scale = 1.0;
			zoom = 1.0;
			constructor()
			{
				::Screen.constructor(::SCWIDTH, ::SCHEIGHT);
				this.scale = this.min(::BASEWIDTH / ::SCWIDTH, ::BASEHEIGHT / ::SCHEIGHT);
				this.projection = ::ScreenProjection(null, this);
				this.projection.setZoom(this.scale);
				this.projection.setCenter(::SCWIDTH / 2, ::SCHEIGHT / 2);
				this.projection.setOffset(::SCWIDTH / 2, ::SCHEIGHT / 2);
				this.projection.visible = true;
				this.projection.smoothing = true;
			}

			function destructor()
			{
				this.projection = null;
				::Screen.destructor();
			}

			function setZoom( zoom )
			{
				if (zoom != this.zoom)
				{
					this.projection.setZoom(this.scale * zoom);
					this.zoom = zoom;
				}
			}

			function changeSizeScale( width, height, s )
			{
				this.projection.setCenter(width / 2, height / 2);
				this.projection.setOffset(width / 2, height / 2);
			}

			function setup()
			{
				this.setupZoom(this);
			}

			function captureScale()
			{
				return 1.0;
			}

		}

	}
	else
	{
		this.printf("hd screen or no scale\n");
		class this.ScreenBase extends ::LayerFolder
		{
			bounds = null;
			zoom = null;
			constructor()
			{
				::LayerFolder.constructor();
				this.bounds = ::getScreenBounds();
				this.smoothing = true;
				this.visible = true;
				this.setZoom(1.0);
			}

			function getBounds()
			{
				return this.bounds;
			}

			function setZoom( zoom )
			{
				if (zoom != this.zoom)
				{
					::LayerFolder.setZoom(zoom);
					this.zoom = zoom;
					local w = ::SCWIDTH * ::BASESCALE * zoom;
					local h = ::SCHEIGHT * ::BASESCALE * zoom;
					this.setBaseClip(-w / 2, -h / 2, w, h);
				}
			}

			function setup()
			{
				this.setupZoom(this);
			}

			function captureScale()
			{
				return 1.0 / this.zoom;
			}

		}

	}

	::baseScreen <- this.ScreenBase();
}

this.specAfterScreenInit();
this.printf("baseScreen:%s baseScreein is Screen:%s\n", ::baseScreen, ::baseScreen instanceof ::Screen);
this.inputHub <- this.InputHub();
function getInput( n )
{
	local input = this.inputHub.inputAt(n);
	input.setKeyRepeat(64 | 128 | 32 | 16, 20, 3);
	return input;
}

this.inputs <- [];
this.inputNo <- 0;

for( local i = 0; i < this.inputHub.getInputNum(); i++ )
{
	this.inputs.append(this.getInput(i));
}

function checkKeyPressed( key )
{
	foreach( input in ::inputs )
	{
		local key = input.keyPressed(key);

		if (key)
		{
			return key;
		}
	}

	return 0;
}

function checkInputFunc( func, choice = false )
{
	foreach( i, input in ::inputs )
	{
		local ret = func(i, input);

		if (ret != null)
		{
			if (ret && choice)
			{
				::inputNo = i;
			}

			return ret;
		}
	}
}

function getCurrentInput()
{
	return ::inputs[::inputNo];
}

class this.MotionLayer extends ::Layer
{
	motion = null;
	constructor( screen, file, chara = null, width = null, height = null )
	{
		if (width == null)
		{
			width = ::SCWIDTH;
		}

		if (height == null)
		{
			height = ::SCHEIGHT;
		}

		::Layer.constructor(screen);
		local bounds = ::getScreenBounds(screen);
		this.setZoom(this.min(bounds.width / width, bounds.height / height));
		this.smoothing = true;

		if (typeof file == "array")
		{
			foreach( f in file )
			{
				local data = ::loadData(f);

				if (data != null)
				{
					this.registerMotionResource(data);
				}
			}
		}
		else
		{
			local data = ::loadData(file);

			if (data != null)
			{
				this.registerMotionResource(data);
			}
		}

		this.visible = true;
		this.motion = ::Motion(this);
		this.motion.visible = true;

		if (chara != null)
		{
			this.motion.chara = chara;
		}
	}

	function setChara( name )
	{
		this.motion.chara = name;
	}

	function play( motionName, flag = 0 )
	{
		this.motion.play(motionName, flag);
	}

	function setVariable( variables, flag = 0 )
	{
		foreach( n, v in variables )
		{
			this.motion.setVariable(n, v, flag);
		}
	}

	function stop()
	{
		this.motion.tickCount = this.motion.lastTime;
		this.motion.progress(0);
		this.motion.stop();
	}

	function wait( canskip = true )
	{
		while (this.motion.playing)
		{
			::suspend();

			if (canskip && this.checkKeyPressed(this.ENTERKEY | this.KEY_CANCEL | 1024 | 2048))
			{
				this.stop();
				::suspend();
				return false;
			}
		}

		return true;
	}

	function playWait( motionName, flag = 0, canskip = true )
	{
		this.play(motionName, flag);
		this.wait(canskip);
	}

}

local spec = ::System.getSpec();
this.loading <- null;
this.system("script/startup.nut");
this.specStartup();

if (this.loading == null)
{
	try
	{
		this.loading = ::MotionLayer(::baseScreen, "motion/loading.psb", "LOADING");
	}
	catch( e )
	{
		this.printf("not found loading motion\n");
	}
}

if (this.loading)
{
	if (spec == "ps4")
	{
		::System.hideSplash();
	}

	this.loading.setPriority(100);
	this.loading.play("show");
}

this.system("script/action.nut");
this.system("script/doublepicture.nut");
this.system("script/fontinfo.nut");
this.system("script/basictext.nut");
this.system("script/basicpicture.nut");
this.system("script/basicrender.nut");
this.system("script/basepicture.nut");
this.system("script/baselayer.nut");
this.system("script/basiclayer.nut");
this.system("script/gestureinfo.nut");
this.system("script/motionpanel.nut");
this.system("script/sound.nut");
this.system("script/text.nut");
this.system("script/confirmdialog.nut");
this.system("script/selectdialog.nut");
this.defaultFont <- this.FontInfo();

if (this.init != null && "fontList" in this.init.root)
{
	foreach( value in this.init.root.fontList )
	{
		this.defaultFont.entryFont(value);
	}
}
else
{
	this.defaultFont.entryFont("textfont24");
	this.defaultFont.entryFont("textfont16");
	this.defaultFont.entryFont("textfont8");
}

if (true)
{
	this.system("script/debug.nut");
}
else
{
	function addGlobalVariable( name )
	{
	}

	function checkDebug( input )
	{
		return true;
	}

}

this.system("script/savesystem.nut");
this.system("script/envsystem.nut");
this.system("script/world.nut");
this.system("script/envenv.nut");
this.system("script/envplayer.nut");
this.system("script/application.nut");
this.system("script/system.nut");
this.allSeen <- false;
this.musicAllSeen <- false;
function gameMain( args, init )
{
	this.Application(init).main(args);
}

this.system("script/override.nut");
this.specAfterInit();

if (this.loading)
{
	this.loading.playWait("hide", 8);
	this.loading = null;
}
else if (spec == "ps4")
{
	::System.hideSplash();
}
