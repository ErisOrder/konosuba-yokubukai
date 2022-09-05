class this.Exception 
{
	message = null;
	callstacks = null;
	constructor( msg )
	{
		this.message = msg;
		this.callstacks = [];
		local level = 2;
		local stack;
		stack = ::getstackinfos(level++);

		while (stack != null)
		{
			this.callstacks.append(stack);
		}
	}

	function printCallStacks()
	{
		this.printf("\nCALLSTACK\n");

		foreach( info in this.callstacks )
		{
			this.printf("*FUNCTION [%s()] %s line [%d]\n", info.func, info.src, info.line);
		}

		this.printf("\nLOCALS\n");

		foreach( info in this.callstacks )
		{
			foreach( name, value in info.locals )
			{
				this.printf("[%s] %s %s\n", name, this.type(value), value);
			}
		}
	}

	function _tostring()
	{
		return this.message;
	}

}

class this.GameStateException 
{
	message = "GameStateException";
	state = "";
	scene = null;
	constructor( state, scene = null )
	{
		this.state = state;
		this.scene = scene;
	}

}

function printException( e )
{
	if (e instanceof this.Exception)
	{
		this.printf("Runtime Exception:%s\n", e.message);
		e.printCallStacks();
	}
	else
	{
		this.printf("Unknown Exception:%s\n", e);
	}
}

