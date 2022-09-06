if (!this.DMMAuth.checkHostname("api-gameplayer.dmm.com"))
{
	this.DMMAuth.inform(this.format("DMM\x00e8\x00aa\x008d\x00e8\x00a8\x00bc\x00e3\x0081\x00ab\x00e5\x00a4\x00b1\x00e6\x0095\x0097\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0080\x0082\x00e3\x0083\x009b\x00e3\x0082\x00b9\x00e3\x0083\x0088\x00e5\x0090\x008d\x00e3\x0081\x008c\x00e4\x00b8\x008d\x00e6\x00ad\x00a3\x00e3\x0081\x00a7\x00e3\x0081\x0099:%s\n", "api-gameplayer.dmm.com"), "DMM Authorization");
	this.System.terminate();
}

local mac_address = this.DMMAuth.getMacAddress()[0];
mac_address = mac_address.replace("-", "");
mac_address = mac_address.replace("\"", "");
this.printf("mac_address:%s\n", mac_address);
local hdd_serial = this.DMMAuth.getWMIC("Win32_DiskDrive", "SerialNumber");
this.printf("hdd_serial:%s\n", hdd_serial);
local motherboard = this.DMMAuth.getWMIC("Win32_BIOS", "SerialNumber");
this.printf("motherboard:%s\n", motherboard);
local url = this.format("https://%s/%s", "api-gameplayer.dmm.com", "api/gameplayer/product/check");
local tokenPath = this.format("%s/%s/%s", this.DMMAuth.getUserProfileDirectory(), ".DMMGamePlayer", this.DMMAuth.encodeBase64(this.DMM_APPID));
local drmToken = this.DMMAuth.loadLine(tokenPath);
this.printf("token:%s:%s\n", tokenPath, drmToken);
local drmcode = this.DMMAuth.getMD5HashString(this.format("%s_%s_%s_%s", this.DMM_APPID, mac_address, hdd_serial, motherboard));
local data = this.format("{\"mac_address\":\"%s\",\"hdd_serial\":\"%s\",\"motherboard\":\"%s\",\"product_id\":\"%s\",\"token\":\"%s\"}", mac_address, hdd_serial, motherboard, this.DMM_APPID, drmToken);
this.printf("send data:%s\n", data);
local ret = false;
local www = this.WWW();
www.init();
www.setUserAgent("M2Keleido");

if (www.isAvailable())
{
	www.setTimeoutSec(30);
	www.setDefaultEncodeType(0);
	local header = "Content-Type: application/json";
	www.startPostString(url, header, data);

	while (www.getRunning())
	{
		this.wait();
	}

	local status = www.getResultStatus();

	if (www.isCanceled())
	{
		this.printf("\x00e3\x0082\x00ad\x00e3\x0083\x00a3\x00e3\x0083\x00b3\x00e3\x0082\x00bb\x00e3\x0083\x00ab\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f\x00e3\x0080\x0082\n");
	}
	else if (status == 200)
	{
		local response = www.getDataString();
		this.printf("response:%s\n", response);
		ret = response == drmcode;
	}
}

www.exit();
www = null;

if (ret)
{
	this.printf("DMM\x00e8\x00aa\x008d\x00e8\x00a8\x00bc\x00e6\x0088\x0090\x00e5\x008a\x009f\n");
	this.DMMAuth.deleteFile(tokenPath);
}
else
{
	this.DMMAuth.inform("DMM\x00e8\x00aa\x008d\x00e8\x00a8\x00bc\x00e5\x0087\x00a6\x00e7\x0090\x0086\x00e3\x0081\x00ab\x00e5\x00a4\x00b1\x00e6\x0095\x0097\x00e3\x0081\x0097\x00e3\x0081\x00be\x00e3\x0081\x0097\x00e3\x0081\x009f: failed to DMM Authorization", "DMM Authorization");
	this.System.terminate();
}
