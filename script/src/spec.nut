this.KEY_OK <- 1;
this.KEY_CANCEL <- 2;
this.ENTERKEY <- this.KEY_OK;
this.upperExtraKey <- 2048;
this.lowerExtraKey <- 1024;
this.movieExt <- "";
function automaticTick()
{
}

function specSetup()
{
}

function specInit( init )
{
}

function specStartup()
{
}

function specAfterInit()
{
}

function specAfterScreenInit()
{
}

local spec = ::System.getSpec();
this.printf("Script System Start spec:%s\n", spec);
this.system("script/spec_" + spec + ".nut");
