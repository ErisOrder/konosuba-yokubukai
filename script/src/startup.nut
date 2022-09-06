local backupData = ::loadData("config/backup.psb");
local systemStruct = ::Struct(backupData, "systemdata");
local config = systemStruct.root.config;
local manager = ::AdvBackupManager();
local backup = manager.addSegment(systemStruct, 1);
manager.init();

while (manager.running)
{
	this.wait();
}

backup.autoload(null);

while (backup.running)
{
	this.wait();
}

if (backup.success)
{
	this.printf("load success!!!\n");
	::setScaleMode(config.scaleMode);
	::setFullScreen(config.fullScreen);
}

this.loading = ::MotionLayer(::baseScreen, [
	"motion/loading.psb",
	"motion/particle.psb"
], "LOADING");
this.KEY_OK <- 2;
this.KEY_CANCEL <- 1;
this.ENTERKEY <- this.KEY_OK;
