this.system("script/include.nut");
this.system("script/title.nut");
::System.setVariableFrame(true);
local bounds = ::System.getScreenBounds();
this.printf("render resolution: %d x %d\n", bounds.width, bounds.height);
local date = ::System.getLocalDateTime();
::srand(date.hour * 3600 + date.min * 60 + date.sec);
this.system("script/spec.nut");
this.specSetup();
this.system("script/exception.nut");
this.system("script/util.nut");
this.system("script/init.nut");
this.setexceptionclass(::Exception);
this.printf("startup vargc:%s\n", vargc);
local args = {};
local cnt = 0;

while (cnt < vargc)
{
	switch(vargv[cnt])
	{
	case "-s":
		cnt++;

		if (cnt < vargc)
		{
			args.startScene <- vargv[cnt];
		}

		break;

	case "-l":
		cnt++;

		if (cnt < vargc)
		{
			args.startLine <- vargv[cnt].charAt(0) == "*" ? vargv[cnt] : this.tonumber(vargv[cnt]);
		}

		break;

	case "-a":
		::allSeen <- true;
		break;

	case "-ne":
		args.noEffect <- true;
		break;

	case "-f":
		args.allSkip <- true;
		break;
	}

	cnt++;
}

this.gameMain(args, ::init != null ? ::init.root : null);
