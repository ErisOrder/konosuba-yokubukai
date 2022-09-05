function setProperty( target, name, value, time = 0, accel = 0 )
{
	if (name.charAt(0) == "$")
	{
		try
		{
			target.setVariable(name.substr(1), value, time, accel);
		}
		catch( e )
		{
			this.printf("\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e8\x00a8\x00ad\x00e5\x00ae\x009a\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s:%s\n", target, name, e);
			::printException(e);
		}
	}
	else
	{
		target[name] = value;
	}
}

function getProperty( target, name )
{
	if (name.charAt(0) == "$")
	{
		return target.getVariable(name.substr(1));
		  // [013]  OP_POPTRAP        1      0    0    0
		  // [014]  OP_JMP            0      9    0    0
		this.printf("\x00e5\x00a4\x0089\x00e6\x0095\x00b0\x00e5\x008f\x0096\x00e5\x00be\x0097\x00e5\x00a4\x00b1\x00e6\x0095\x0097:%s:%s:%s\n", $[stack offset 1], name, target.getVariable(name.substr(1)));
		::printException(target.getVariable(name.substr(1)));
	}
	else
	{
		return target[name];
	}
}

function getRelative( value, orig, context = null )
{
	if (typeof value == "string")
	{
		if (value.charAt(0) == "#")
		{
			return value.substr(1);
		}
		else if (value.find("@") != null)
		{
			return ::eval(value.replace("@", orig.tostring()), context);
		}
		else
		{
			return ::tonumber(value);
		}
	}
	else
	{
		return ::tonumber(value);
	}
}

function getCompleteFunc( func, target )
{
	return func.getenv() == null ? func.bindenv(target) : func;
}

function copyCompleteFunc( func, dest, src )
{
	return typeof func == "function" && func.getenv() == src ? func.bindenv(dest) : func;
}

this.actionParams <- {
	name = true,
	time = true,
	mag = true,
	speed = true,
	delay = true,
	accel = true,
	starttime = true,
	quake = true,
	nowait = true,
	complete = true,
	after = true
};
function _convDictAction( dict, elm, nowait = null )
{
	local e;

	if (typeof elm == "table")
	{
		e = clone elm;
	}
	else if (typeof elm == "string" && elm.charAt(0) == "#")
	{
		e = {
			handler = "",
			[this.value] = elm
		};
	}
	else if (typeof elm == "string" || typeof elm == "integer" || typeof elm == "float")
	{
		e = {
			handler = "MoveAction",
			[this.value] = elm
		};
	}
	else
	{
		e = {
			handler = "wait"
		};
	}

	if ("mag" in dict)
	{
		if ("mag" in e)
		{
			e.mag = e.mag * ::tonumber(dict.mag);
		}
		else
		{
			e.mag <- ::tonumber(dict.mag);
		}
	}

	if ("speed" in dict)
	{
		if ("speed" in e)
		{
			e.speed = e.speed * ::tonumber(dict.speed);
		}
		else
		{
			e.speed <- ::tonumber(dict.speed);
		}
	}

	if ("delay" in dict)
	{
		if ("delay" in e)
		{
			e.delay = e.delay + ::tonumber(dict.delay);
		}
		else
		{
			e.delay <- ::tonumber(dict.delay);
		}
	}

	if ("starttime" in dict)
	{
		if ("starttime" in e)
		{
			e.starttime += ::tonumber(dict.starttime);
		}
		else
		{
			e.starttime <- ::tonumber(dict.starttime);
		}
	}

	if ("time" in dict)
	{
		e.time <- ::tonumber(dict.time);
	}

	if ("accel" in dict)
	{
		e.accel <- dict.accel;
	}

	if ("quake" in dict)
	{
		e.quake <- dict.quake;
	}

	if ("nowait" in dict)
	{
		e.nowait <- dict.nowait;
	}

	if (nowait != null)
	{
		e.nowait <- nowait;
	}

	return e;
}

function convDictAction( dict, name, nowait = null )
{
	local elm = ::getval(dict, name);

	if (elm == null && (name == "zoomx" || name == "zoomy"))
	{
		elm = ::getval(dict, "zoom");
	}

	if (typeof elm == "array")
	{
		local ret = [];

		foreach( a in elm )
		{
			ret.append(this._convDictAction(dict, a, nowait));
		}

		return ret;
	}
	else
	{
		return this._convDictAction(dict, elm, nowait);
	}
}

function splitAction( action, names, nowait = null )
{
	local result = {};

	if (typeof action == "table")
	{
		foreach( name in names )
		{
			result[name] <- [
				this.convDictAction(action, name, nowait)
			];
		}
	}
	else if (typeof action == "array")
	{
		foreach( ac in action )
		{
			if (typeof ac == "table")
			{
				foreach( name in names )
				{
					local list = ::getval(result, name);

					if (list == null)
					{
						list = [];
						result[name] <- list;
					}

					if ("loop" in ac)
					{
						list.append({
							handler = "loop",
							loop = this.i - ac.loop,
							count = ::getval(ac, "count")
						});
					}
					else if ("wait" in ac)
					{
						local e = {
							handler = "wait",
							time = ac.wait
						};

						if ("speed" in ac)
						{
							e.speed <- ac.speed;
						}

						list.append(e);
					}
					else
					{
						list.append(this.convDictAction(ac, name, nowait));
					}
				}
			}
			else if (typeof ac == "array")
			{
				foreach( name in names )
				{
					local list = ::getval(result, name);

					if (list == null)
					{
						list = [];
						result[name] <- list;
					}

					list.append({
						handler = "loop",
						loop = this.i - ac[0],
						count = ac[1]
					});
				}
			}
			else if (typeof ac == "integer")
			{
				foreach( name in names )
				{
					local list = ::getval(result, name);

					if (list == null)
					{
						list = [];
						result[name] <- list;
					}

					list.append({
						handler = "wait",
						time = ac
					});
				}
			}
		}
	}

	return result;
}

class this.PropActionInfo 
{
	propName = null;
	absolute = null;
	relative = null;
	complete = null;
	after = null;
	first = true;
	done = false;
	startTime = null;
	nowait = false;
	onlyMove = false;
	constructor( propName )
	{
		this.propName = propName;
		this.relative = [];
		this.first = true;
		this.onlyMove = false;
	}

	target = null;
	value = null;
	function startValue( target )
	{
		this.target = target.weakref();
		this.value = this.getProperty(target, this.propName);
	}

	function endValue( target )
	{
		this.setProperty(target, this.propName, this.value);
	}

	function setValue( value )
	{
		this.value = value;
	}

	function getValue()
	{
		return this.value;
	}

	function next()
	{
		this.first = true;
		this.startTime = null;
		this.done = false;

		if (typeof this.absolute == "instance")
		{
			this.absolute.next();
		}

		foreach( idx, info in this.relative )
		{
			info.next();
		}
	}

	function cloneObj( dest, src )
	{
		local ret = ::PropActionInfo(this.propName);
		ret.absolute = this.absolute;

		foreach( idx, info in this.relative )
		{
			ret.relative.append(info);
		}

		ret.complete = this.copyCompleteFunc(this.complete, dest, src);
		ret.after = this.copyCompleteFunc(this.after, dest, src);
		ret.first = this.first;
		ret.done = this.done;
		ret.startTime = this.startTime;
		ret.nowait = this.nowait;
		return ret;
	}

	function addAction( target, handler, elm )
	{
		this.startValue(target);

		if (typeof handler == "class")
		{
			if (this.inherited(handler, this.AbsoluteActionHandler))
			{
				this.absolute = handler(this, elm);
				this.relative.clear();
				this.first = true;
				this.done = false;
				this.complete = ::getval(elm, "complete");
				this.after = ::getval(elm, "after");
				this.nowait = ::getbool(elm, "nowait", false);
			}
			else if (this.inherited(handler, this.RelativeActionHandler))
			{
				if (this.absolute == null)
				{
					this.absolute = this.DefaultAction(this, {});
					this.first = true;
					this.done = false;
					this.complete = ::getval(elm, "complete");
					this.after = ::getval(elm, "after");

					if ("nowait" in elm)
					{
						this.nowait = ::getbool(elm, "nowait", false);
					}
				}

				this.relative.append(handler(this, elm));
			}
			else
			{
				this.dm("\x00e3\x0083\x008f\x00e3\x0083\x00b3\x00e3\x0083\x0089\x00e3\x0083\x00a9\x00e7\x0095\x00b0\x00e5\x00b8\x00b8:" + handler);
			}
		}
		else
		{
			this.absolute = ::getRelative(handler, this.getValue(), this);
			this.first = true;
			this.done = false;
			this.complete = ::getval(elm, "complete");
			this.after = ::getval(elm, "after");
			this.nowait = ::getbool(elm, "nowait", false);
		}
	}

	function doComplete( target, queue )
	{
		if (target != null)
		{
			if (this.complete != null)
			{
				try
				{
					this.getCompleteFunc(this.complete, target)(this.propName);
				}
				catch( e )
				{
					this.dm("complete\x00e5\x00ae\x009f\x00e8\x00a1\x008c\x00e6\x0099\x0082\x00e4\x00be\x008b\x00e5\x00a4\x0096");
					::printException(e);
				}
			}

			if (queue != null && this.after != null)
			{
				queue.append(this.getCompleteFunc(this.after, target));
			}
		}
	}

	function doFirst( target, now = 0 )
	{
		if (this.first)
		{
			if (this.startTime == null)
			{
				this.startTime = now;
			}

			if (typeof this.absolute == "instance")
			{
				this.absolute.init(this);
			}
			else if (this.absolute != null)
			{
				this.setValue(this.absolute);
			}

			foreach( idx, info in this.relative )
			{
				info.init(this);
			}

			this.onlyMove = this.relative.len() == 0 && (this.absolute instanceof this.MoveAction) && !(this.absolute instanceof this.PathAction) && this.absolute.starttime == 0 && this.absolute.delay == null && ("canMove" in target) && target.canMove(this.propName);

			if (this.onlyMove)
			{
				if (this.absolute.setstart != null)
				{
					this.setProperty(target, this.propName, this.absolute.start);
				}

				this.setProperty(target, this.propName, this.absolute.value, this.absolute.time, this.absolute.accel);
			}

			this.first = false;
		}
	}

	function doAction( target, now, queue )
	{
		if (!this.done)
		{
			this.startValue(target);
			this.doFirst(target, now);
			now -= this.startTime;
			this.done = true;

			if (this.onlyMove)
			{
				if (now < this.absolute.time)
				{
					this.done = false;
				}
			}
			else
			{
				if (typeof this.absolute == "instance")
				{
					if (!this.absolute.action(this, now))
					{
						this.done = false;
					}
				}

				foreach( idx, info in this.relative )
				{
					if (!info.action(this, now))
					{
						this.done = false;
					}
				}

				this.endValue(target);
			}

			if (this.done)
			{
				this.doComplete(target, queue);
			}
		}

		return this.done;
	}

	function stopAction( target, queue )
	{
		if (!this.done)
		{
			this.startValue(target);
			this.doFirst(target, 0);
			this.done = true;

			if (typeof this.absolute == "instance")
			{
				this.absolute.action(this, 0, true);
			}

			this.endValue(target);
			this.doComplete(target, queue);
		}

		return this.done;
	}

}

class this.ActionWaitInfo 
{
	wait = null;
	startTime = null;
	speed = 1.0;
	constructor( wait, speed = 1.0 )
	{
		this.wait = wait;
		this.speed = speed != null ? speed : 1.0;
	}

	function cloneObj( dest, src )
	{
		return ::ActionWaitInfo(this.wait, this.speed);
	}

	function doAction( target, now )
	{
		if (target == null)
		{
			return true;
		}

		if (this.startTime == null)
		{
			this.startTime = now;
		}

		now -= this.startTime;
		now *= this.speed;
		return now >= this.wait;
	}

	function next()
	{
		this.startTime = null;
	}

}

class this.ActionLoopInfo 
{
	count = null;
	point = null;
	constructor( point, count )
	{
		this.point = point;

		if (count != null && count > 0)
		{
			this.count = count;
		}
	}

	function cloneObj( dest, src )
	{
		return ::ActionLoopInfo(this.point, this.count);
	}

	function doLoop()
	{
		if (this.count == null)
		{
			return this.point;
		}
		else
		{
			if (--this.count <= 0)
			{
				return -1;
			}

			return this.point;
		}
	}

}

class this.ActionSequense 
{
	propName = null;
	actions = null;
	complete = null;
	after = null;
	cur = 0;
	constructor( propName )
	{
		this.propName = propName;
		this.actions = [];
		this.cur = 0;
	}

	function cloneObj( dest, src )
	{
		local ret = ::ActionSequense(this.propName);

		foreach( idx, info in this.actions )
		{
			ret.actions.append(info.cloneObj(dest, src));
		}

		ret.cur = this.cur;
		ret.complete = this.copyCompleteFunc(this.complete, dest, src);
		ret.after = this.copyCompleteFunc(this.after, dest, src);
		return ret;
	}

	function getNowait()
	{
		for( local i = 0; i < this.actions.len(); i++ )
		{
			if ((this.actions[i] instanceof this.PropActionInfo) && this.actions[i].nowait)
			{
				return true;
			}
		}

		return false;
	}

	function getWorking()
	{
		return this.cur < this.actions.len();
	}

	function getWorkingWait()
	{
		return this.getWorking() && !this.getNowait();
	}

	function addAction( target, handler, elm, init = false )
	{
		if (!init && this.getWorking() && (this.actions[this.cur] instanceof this.PropActionInfo))
		{
			local info = this.actions[this.cur];
			info.addAction(target, handler, elm);
		}
		else
		{
			local info = this.PropActionInfo(this.propName);
			info.addAction(target, handler, elm);
			this.actions.append(info);
		}
	}

	function addLoop( loop, count )
	{
		this.actions.append(::ActionLoopInfo(loop, count));
	}

	function addWait( wait, speed )
	{
		this.actions.append(::ActionWaitInfo(wait, speed));
	}

	function _addActionList( target, action, init )
	{
		if (typeof action == "table")
		{
			local handler;

			if (!("handler" in action))
			{
				handler = this.MoveAction;
			}
			else if (typeof action.handler == "string")
			{
				if (action.handler == "")
				{
					handler = action.value;
				}
				else
				{
					handler = ::eval(action.handler);
				}
			}
			else if (typeof action.handler == "class")
			{
				handler = action.handler;
			}
			else
			{
				handler = this.MoveAction;
			}

			this.addAction(target, handler, action, init);
		}
		else
		{
			this.addAction(target, action, null, init);
		}
	}

	function addActionList( target, list )
	{
		local first = true;

		foreach( action in list )
		{
			if (typeof action == "array")
			{
				foreach( j, act in action )
				{
					this._addActionList(target, act, !first && j == 0);
				}
			}
			else if (typeof action == "table" && "handler" in action)
			{
				switch(action.handler)
				{
				case "loop":
					this.addLoop(::getint(action, "loop"), ::getint(action, "count"));
					break;

				case "wait":
					this.addWait(::getval(action, "time"), ::getval(action, "speed"));
					break;

				default:
					this._addActionList(target, action, !first);
					break;
				}
			}
			else
			{
				this._addActionList(target, action, !first);
			}

			first = false;
		}
	}

	function setComplete( complete, after = null )
	{
		if (complete != null)
		{
			this.complete = complete;
		}

		if (after != null)
		{
			this.after = after;
		}
	}

	function doComplete( target, queue )
	{
		if (target != null)
		{
			if (this.complete != null)
			{
				try
				{
					this.getCompleteFunc(this.complete, target)();
				}
				catch( e )
				{
					this.dm("complete\x00e5\x00ae\x009f\x00e8\x00a1\x008c\x00e6\x0099\x0082\x00e4\x00be\x008b\x00e5\x00a4\x0096");
					::printException(e);
				}
			}

			if (("onActionComplete" in target) && typeof target.onActionComplete == "function")
			{
				target.onActionComplete(this.propName);
			}

			if (queue != null)
			{
				if (this.after != null)
				{
					queue.append(this.getCompleteFunc(this.after, target));
				}

				if (("onActionCompleteAfter" in target) && target.onActionCompleteAfter == "function")
				{
					this.quque.append(function () : ( propName, target )
					{
						if (target != null)
						{
							target.onActionCompleteAfter(propName);
						}
					});
				}
			}
		}
	}

	function doAction( target, now, queue )
	{
		if (this.cur < this.actions.len())
		{
			local action = this.actions[this.cur];

			if (action instanceof ::ActionLoopInfo)
			{
				local loop = action.doLoop();

				if (loop > 0)
				{
					this.cur -= loop;
				}
				else
				{
					this.cur++;
				}
			}
			else if (action instanceof ::ActionWaitInfo)
			{
				if (action.doAction(target, now))
				{
					action.next();
					this.cur++;
				}
			}
			else if (action.doAction(target, now, queue))
			{
				action.next();
				this.cur++;
			}
		}

		if (!this.getWorking())
		{
			this.doComplete(target, queue);
			return true;
		}

		return false;
	}

	function stopAction( target, all, queue )
	{
		while (this.cur < this.actions.len() && (all || !this.getNowait()))
		{
			local action = this.actions[this.cur];

			if (action instanceof ::PropActionInfo)
			{
				action.stopAction(target, queue);
			}

			this.cur++;
		}

		if (!this.getWorking())
		{
			this.actions.clear();
			this.cur = 0;
			this.doComplete(target, queue);
			return true;
		}

		return false;
	}

}

class this.ActionTargetInfo 
{
	target = null;
	actionDict = null;
	complete = null;
	constructor( target )
	{
		this.target = target.weakref();
		this.actionDict = {};
	}

	function cloneObj( newtarget )
	{
		local ret = ::ActionTargetInfo(newtarget);
		ret.complete = this.copyCompleteFunc(this.complete, newtarget, this.target);

		foreach( name, info in this.actionDict )
		{
			local newact = info.cloneObj(newtarget, this.target);
			ret.actionDict[name] <- newact;
		}

		return ret;
	}

	function getWorking()
	{
		foreach( name, action in this.actionDict )
		{
			if (action.getWorking())
			{
				return true;
			}
		}

		return false;
	}

	function getWorkingWait()
	{
		foreach( name, action in this.actionDict )
		{
			if (action.getWorkingWait())
			{
				return true;
			}
		}

		return false;
	}

	function hasAction( propName )
	{
		return (propName in this.actionDict) && this.actionDict[propName].getWorking();
	}

	function delAction( propName, queue )
	{
		if (propName == "zoom")
		{
			this.delAction("zoomx", queue);
			this.delAction("zoomy", queue);
			return;
		}

		if (propName in this.actionDict)
		{
			local ret = this.actionDict[propName];
			ret.stopAction(this.target, true, queue);
			delete this.actionDict[propName];
		}
	}

	function addAction( propName, list )
	{
		local seq;

		if (propName in this.actionDict)
		{
			seq = this.actionDict[propName];
		}
		else
		{
			seq = ::ActionSequense(propName);
			this.actionDict[propName] <- seq;
		}

		seq.addActionList(this.target, list);
	}

	function copyAction( propName, src, queue )
	{
		this.delAction(propName, queue);

		if (propName in src.actionDict)
		{
			this.actionDict[propName] <- src.actionDict[propName].cloneObj(this.target, src.target);
		}
	}

	function setComplete( propName, complete, after )
	{
		if (propName in this.actionDict)
		{
			local seq = this.actionDict[propName];
			seq.setComplete(complete, after);
		}
	}

	function _doComplete( queue )
	{
		if (queue != null && this.complete != null)
		{
			queue.push(this.getCompleteFunc(this.complete, this.target));
			this.complete = null;
		}
	}

	function doAction( now, queue )
	{
		local done = true;

		foreach( name, info in this.actionDict )
		{
			if (!info.doAction(this.target, now, queue))
			{
				done = false;
			}
		}

		if (done)
		{
			this._doComplete(queue);
		}

		return done;
	}

	function stopAction( all, queue )
	{
		local done = true;

		if (this.target != null)
		{
			foreach( name, info in this.actionDict )
			{
				if (!info.stopAction(this.target, all, queue))
				{
					done = false;
				}
			}
		}

		if (done)
		{
			this._doComplete(queue);
		}

		return done;
	}

	function hasProperty( name )
	{
		return name.charAt(0) == "$" || this.target.hasSetProp(name);
	}

	function _getActionPropNames( action, names )
	{
		foreach( name, value in action )
		{
			if (name == "zoom")
			{
				names.zoomx <- true;
				names.zoomy <- true;
				return;
			}

			if (!(name in this.actionParams || name.len() > 4 && name.substr(0, 4) == "flag") && this.hasProperty(name))
			{
				names[name] <- true;
			}
		}
	}

	function getActionPropNames( action )
	{
		local names = {};

		if (typeof action == "table")
		{
			this._getActionPropNames(action, names);
		}
		else if (typeof action == "array")
		{
			foreach( act in action )
			{
				if (typeof act == "table")
				{
					this._getActionPropNames(act, names);
				}
			}
		}

		return names.keys();
	}

	function beginAction( action, complete, nowait, queue )
	{
		if (typeof action == "table" || typeof action == "array")
		{
			local names = this.getActionPropNames(action);
			local result = this.splitAction(action, names, nowait);

			foreach( name in names )
			{
				this.delAction(name, queue);
				this.addAction(name, ::getval(result, name));
			}
		}

		this._doComplete(queue);
		this.complete = complete;
	}

}

class this.ActionHandler 
{
	time = null;
	delay = null;
	starttime = null;
	speed = 1.0;
	mag = 1.0;
	constructor( target, elm )
	{
		this.time = ::getfloat(elm, "time", null);
		this.delay = ::getfloat(elm, "delay", null);
		this.starttime = ::getfloat(elm, "starttime", 0);
		this.speed = ::getfloat(elm, "speed", 1.0);
		this.mag = ::getfloat(elm, "mag", 1.0);
	}

	function getRelative( value, orig )
	{
		return ::getRelative(value, orig, this);
	}

	function init( target )
	{
	}

	function next()
	{
	}

	function action( target, now, stopFlag = false )
	{
		if (!stopFlag && this.delay != null)
		{
			now -= this.delay;

			if (now < 0)
			{
				return false;
			}
		}

		now += this.starttime;
		now *= this.speed;
		return this.doAction(target, now, stopFlag || this.time != null && now > this.time);
	}

	function doAction( target, now, stopFlag )
	{
		return true;
	}

}

class this.AbsoluteActionHandler extends this.ActionHandler
{
	constructor( target, elm )
	{
		::ActionHandler.constructor(target, elm);
	}

}

class this.RelativeActionHandler extends this.ActionHandler
{
	constructor( target, elm )
	{
		::ActionHandler.constructor(target, elm);
	}

}

class this.DefaultAction extends this.AbsoluteActionHandler
{
	initValue = null;
	constructor( target, elm )
	{
		::AbsoluteActionHandler.constructor(target, elm);
		this.initValue = target.getValue();
	}

	function doAction( target, now, stopFlag )
	{
		target.setValue(this.initValue);
		return true;
	}

}

class this.MoveAction extends this.AbsoluteActionHandler
{
	initValue = null;
	setstart = null;
	start = null;
	value = null;
	accel = null;
	diff = null;
	moveFunc = null;
	constructor( target, elm )
	{
		::AbsoluteActionHandler.constructor(target, elm);
		this.initValue = target.getValue();
		this.setstart = "start" in elm ? this.getRelative(::getval(elm, "start"), this.initValue) : null;
		this.value = this.createValue(::getval(elm, "value"), this.initValue);

		if (target.propName == "xpos" || target.propName == "ypos")
		{
			if ("res_align" in target)
			{
				this.value = target.res_align(this.value);
			}
		}

		this.accel = ::getval(elm, "accel");
		this.moveFunc = null;

		if (typeof this.accel == "string")
		{
			switch(this.accel.tolower())
			{
			case "accel":
				this.moveFunc = this.getAccelMove;
				break;

			case "decel":
				this.moveFunc = this.getDecelMove;
				break;

			case "acdec":
				this.moveFunc = this.getAcDecMove;
				break;

			case "accos":
				this.moveFunc = this.getAcCosMove;
				break;

			case "const":
				this.moveFunc = this.getConstMove;
				break;
			}
		}
		else if (typeof this.accel == "function")
		{
			this.moveFunc = this.accel;
		}

		if (this.moveFunc == null)
		{
			if (this.accel == null || this.accel == "")
			{
				this.accel = 0;
			}
			else
			{
				this.accel = ::toint(this.accel);
			}

			this.moveFunc = this.accel == 0 ? this.getConstMove : this.accel > 0 ? this.getAccelMove : this.getDecelMove;
		}
	}

	function createValue( value, initValue )
	{
		return this.getRelative(value, initValue);
	}

	function init( target )
	{
		if (this.setstart != null)
		{
			this.start = this.setstart;
		}
		else
		{
			this.start = target.getValue();
		}

		if (this.time > 0)
		{
			this.diff = ::tofloat(this.value) - ::tofloat(this.start);
		}
	}

	function doAction( target, now, stopFlag )
	{
		if (this.time == 0 || this.time == null || stopFlag)
		{
			if (this.diff != null)
			{
				target.setValue(this.start + this.diff);
			}
			else
			{
				target.setValue(this.value);
			}

			return true;
		}
		else
		{
			target.setValue(this.start + this.diff * this.moveFunc(now.tofloat() / this.time.tofloat()));
			return false;
		}
	}

	function getConstMove( t )
	{
		return t;
	}

	function getAccelMove( t )
	{
		return t * t;
	}

	function getDecelMove( t )
	{
		return t * (2 - t);
	}

	function getAcDecMove( t )
	{
		return t * t * (3 - 2 * t);
	}

	function getAcCosMove( t )
	{
		return (1 - this.cos(t * this.PI)) / 2;
	}

}

class this.PathAction extends this.MoveAction
{
	constructor( target, elm )
	{
		::MoveAction.constructor(target, elm);
	}

	function createValue( value, initValue )
	{
		local ret;

		if (value.find(",") != null)
		{
			ret = value.split(",");
			ret.resize(ret.len() + 1);

			for( local i = ret.len() - 2; i >= 0; i-- )
			{
				ret[i + 1] = this.getRelative(ret[i], initValue);
			}

			ret[0] = null;
		}
		else
		{
			ret = [
				null,
				this.getRelative(value, initValue)
			];
		}

		return ret;
	}

	function init( target )
	{
		if (this.setstart != null)
		{
			this.value[0] = this.setstart;
		}
		else
		{
			this.value[0] = target.getValue();
		}
	}

	function doAction( target, now, stopFlag )
	{
		if (this.time == 0 || this.time == null || stopFlag)
		{
			target.setValue(this.value[this.value.len() - 1]);
			return true;
		}
		else
		{
			local l = this.value.len() - 1;
			local t = this.moveFunc(now / this.time) * l;
			local n = this.toint(t);
			local tdiff = t - n;
			local diff = n >= l ? 0 : this.value[n + 1] - this.value[n];
			target.setValue(this.value[n] + diff * tdiff);
			return false;
		}
	}

}

class this.LoopMoveAction extends this.AbsoluteActionHandler
{
	initValue = null;
	setstart = null;
	setmin = null;
	setmax = null;
	start = null;
	min = null;
	max = null;
	loop = null;
	constructor( target, elm )
	{
		::AbsoluteActionHandler.constructor(target, elm);
		this.initValue = target.getValue();

		if ("start" in elm)
		{
			this.setstart = this.getRelative(::getval(elm, "start"), this.initValue);
		}

		this.setmin = this.getRelative(::getval(elm, "min", 0), this.initValue);
		this.setmax = this.getRelative(::getval(elm, "max", 0), this.initValue);
		this.loop = ::getint(elm, "loop", this.time);
	}

	function init( target )
	{
		if (this.setstart != null)
		{
			this.start = this.setstart;
		}
		else
		{
			this.start = target.getValue();
		}

		this.min = this.setmin;
		this.max = this.setmax;
		this.max -= this.min;
		this.start -= this.min;
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			target.setValue(this.min + (this.start + this.max * (now % this.loop) / this.loop) % this.max);
			return false;
		}
	}

}

class this.VibrateAction extends this.RelativeActionHandler
{
	vibration = null;
	offset = null;
	constructor( target, elm )
	{
		::RelativeActionHandler.constructor(target, elm);
		local initValue = target.getValue();
		this.vibration = this.getRelative("value" in elm ? ::getval(elm, "value") : ::getval(elm, "vibration"), initValue) * this.mag;
		this.offset = this.getRelative(::getval(elm, "offset"), initValue);

		if (this.offset == null)
		{
			this.offset = 0;
		}
	}

}

class this.RandomAction extends this.VibrateAction
{
	waitTime = null;
	rand = null;
	randomTime = null;
	randomValue = null;
	constructor( target, elm )
	{
		::VibrateAction.constructor(target, elm);

		if ("seed" in elm)
		{
			this.rand = ::Random(elm.seed * 268435455);
		}
		else
		{
			this.rand = ::Random();
		}

		this.waitTime = ::getint(elm, "waittime", 0);
		this.randomTime = 0;
		this.randomValue = 0;
	}

	function next()
	{
		this.randomTime = 0;
		this.randomValue = 0;
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			if (now >= this.randomTime)
			{
				this.randomValue = this.rand.random() * this.vibration * 2 - this.vibration + this.offset;
				this.randomTime += this.waitTime;
			}

			target.setValue(target.getValue() + this.randomValue);
			return false;
		}
	}

}

class this.SquareAction extends this.VibrateAction
{
	ontime = null;
	offtime = null;
	constructor( target, elm )
	{
		::VibrateAction.constructor(target, elm);
		this.ontime = ::getint(elm, "ontime", 0);
		this.offtime = ::getint(elm, "offtime", 0);
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			target.setValue(target.getValue() + (now % (this.ontime + this.offtime) < this.ontime ? this.vibration : -this.vibration) + this.offset);
			return false;
		}
	}

}

class this.TriangleAction extends this.VibrateAction
{
	ontime = null;
	offtime = null;
	constructor( target, elm )
	{
		::VibrateAction.constructor(target, elm);
		this.ontime = ::getint(elm, "ontime", 0);
		this.offtime = ::getint(elm, "offtime", 0);
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			now = now % (this.ontime + this.offtime);
			local v;

			if (now <= this.ontime)
			{
				v = this.vibration * now / this.ontime;
			}
			else if (this.offtime > 0)
			{
				v = this.vibration * (this.offtime - (now - this.ontime)) / this.offtime;
			}
			else
			{
				v = 0;
			}

			target.setValue(target.getValue() + v + this.offset);
			return false;
		}
	}

}

class this.TrigonoAction extends this.VibrateAction
{
	cycle = null;
	nextTime = null;
	distance = null;
	random = false;
	constructor( target, elm )
	{
		::VibrateAction.constructor(target, elm);

		if ("cycle" in elm)
		{
			this.cycle = ::getfloat(elm, "cycle");
		}
		else if ("angvel" in elm)
		{
			this.cycle = 360000.0 / ::getfloat(elm, "angvel");
		}
		else
		{
			this.cycle = 1000.0;
		}

		this.nextTime = 0;
		this.distance = this.vibration;
		this.random = ::getbool(elm, "random", false);
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			if (this.random)
			{
				if (now >= this.nextTime)
				{
					this.distance = ::random(this.vibration * 2) - this.vibration;
					this.nextTime += this.cycle;
				}
			}

			target.setValue(::tofloat(target.getValue()) + this.distance * this.calc(this.PI * 2 * now / this.cycle) + this.offset);
			return false;
		}
	}

}

class this.SinAction extends this.TrigonoAction
{
	constructor( target, elm )
	{
		::TrigonoAction.constructor(target, elm);
	}

	function calc( degree )
	{
		return this.sin(degree);
	}

}

class this.CosAction extends this.TrigonoAction
{
	constructor( target, elm )
	{
		::TrigonoAction.constructor(target, elm);
	}

	function calc( degree )
	{
		return this.cos(degree);
	}

}

class this.FallAction extends this.RelativeActionHandler
{
	distance = null;
	fallTime = null;
	constructor( target, elm )
	{
		::RelativeActionHandler.constructor(target, elm);
		this.distance = ::getint(elm, "distance", 0);
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			target.setValue(target.getValue() + this.distance * (now / this.time - 1.0));
			return false;
		}
	}

}

class this.RandomFlipAction extends this.AbsoluteActionHandler
{
	rand = null;
	initValue = null;
	flipTime = null;
	flipFreq = null;
	pattern = null;
	resultValue = 0;
	cur = null;
	nextTime = 0;
	flipValue = null;
	constructor( target, elm )
	{
		::AbsoluteActionHandler.constructor(target, elm);

		if ("seed" in elm)
		{
			this.rand = ::Random(elm.seed * 268435455);
		}
		else
		{
			this.rand = ::Random();
		}

		this.initValue = target.getValue();
		this.flipTime = this.getint(elm, "fliptime", 60);
		this.flipFreq = this.getfloat(elm, "flipfreq", 1);
		this.flipFreq = this.flipFreq * this.flipTime / 1000.0;
		this.pattern = [
			2,
			1,
			0
		];

		if ("pattern" in elm)
		{
			if (elm.pattern == "eye")
			{
				this.pattern = [
					0,
					1,
					2
				];
			}
			else if (elm.pattern == "lip")
			{
				this.pattern = [
					1,
					2,
					0
				];
			}
			else if (elm.pattern.find(",") != null)
			{
				this.pattern = elm.pattern.split(",");

				for( local i = 0; i < this.pattern.len(); i++ )
				{
					this.pattern[i] = ::tonumber(this.pattern[i]);
				}
			}
		}

		this.resultValue = this.pattern[this.pattern.len() - 1];
		this.next();
	}

	function next()
	{
		this.cur = null;
		this.nextTime = 0;
		this.flipValue = null;
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			target.setValue(this.resultValue);
			return true;
		}
		else
		{
			if (now >= this.nextTime)
			{
				if (this.cur == null)
				{
					if (this.rand.random() < this.flipFreq)
					{
						this.cur = 0;
					}
				}
				else if (this.cur < this.pattern.len())
				{
					this.flipValue = this.pattern[this.cur++];
				}
				else
				{
					this.cur = null;
					this.flipValue = null;
				}

				this.nextTime = now + this.flipTime;
			}

			if (this.flipValue != null)
			{
				target.setValue(this.flipValue);
			}

			return false;
		}
	}

}

class this.CopyValueAction extends this.AbsoluteActionHandler
{
	initValue = null;
	delay = 0;
	name = null;
	type = null;
	queue = null;
	constructor( target, elm )
	{
		::AbsoluteActionHandler.constructor(target, elm);
		this.initValue = target.getValue();
		this.delay = ::getint(elm, "delay", 0);
		this.name = ::getval(elm, "name", ("name" in target) && typeof target.name == "string" ? target.name : "");
		this.type = ::getval(elm, "type", target.propName);
		this.queue = [];
	}

	function next()
	{
		this.queue.clear();
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			target.setValue(this.initValue);
			return true;
		}
		else
		{
			if ("copyValue" in target.target)
			{
				this.queue.append(target.target.copyValue(this.name, this.type));

				if (this.queue.len() > this.delay)
				{
					local value = this.queue.top();
					this.queue.remove(0);

					if (value != null)
					{
						target.setValue(value);
					}
					else
					{
						target.setValue(this.initValue);
					}
				}
			}

			return false;
		}
	}

}

class this.EvalAction extends this.AbsoluteActionHandler
{
	exp = null;
	constructor( target, elm )
	{
		this.AbsoluteActionHandler.constructor(target, elm);
		this.exp = "exp" in elm ? elm.exp : "0";
	}

	function doAction( target, now, stopFlag )
	{
		if (stopFlag)
		{
			return true;
		}
		else
		{
			local value;

			if ("eval" in target.target)
			{
				value = target.target.eval(this.exp);
			}
			else
			{
				value = ::eval(this.exp);
			}

			target.setValue(value);
			return false;
		}
	}

}

