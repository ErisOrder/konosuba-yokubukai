class this.GestureInfo extends ::Object
{
	DOUBLETOUCH_GAP = 250;
	SWIPE_DISTANCE = 30;
	DRAG_DISTANCE = 10;
	ROTATE_DISTANCE = 20;
	PINCH_DISTANCE = 30;
	_owner = null;
	_touches = [];
	_touchCount = 0;
	_singleTapThread = null;
	_lastTick = null;
	_lastDiff = 0;
	_taps = 0;
	_prevSwipe = false;
	_start_angle = 0;
	_diff_angle = 0;
	_start_distance = 0;
	_diff_distance = 0;
	constructor( owner )
	{
		this._owner = owner.weakref();
		this._clear();
	}

	function destructor()
	{
		this._clear();
	}

	function _onGesture( name, param = null )
	{
		if (this._owner)
		{
			return this._owner.onGesture(name, param);
		}
	}

	function _removeTouch( id )
	{
		foreach( i, t in this._touches )
		{
			if (t.id == id)
			{
				this._touches.erase(i);
				break;
			}
		}
	}

	function _addTouch( x, y, id )
	{
		this._touches.append({
			startX = x,
			startY = y,
			x = x,
			y = y,
			id = id
		});
	}

	function _moveTouch( x, y, id )
	{
		foreach( t in this._touches )
		{
			if (t.id == id)
			{
				t.x = x;
				t.y = y;
				break;
			}
		}
	}

	function _clearSingleTap()
	{
		if (this._singleTapThread != null)
		{
			this._singleTapThread.exit();
			this._singleTapThread = null;
		}
	}

	function _clear()
	{
		this._touchCount = 0;
		this._lastTick = null;
		this._lastDiff = 0;
		this._taps = 0;
		this._prevSwipe = false;
		this._start_angle = 0;
		this._diff_angle = 0;
		this._start_distance = 0;
		this._diff_distance = 0;
		this._clearSingleTap();
	}

	function _calcAngle( p0, p1 )
	{
		local r = this.atan((p1.y - p0.y) * -1 / (p1.x - p0.x)) * (180 / this.PI);
		return r < 0 ? r + 180 : r;
	}

	function _calcDistance( p0, p1 )
	{
		local dx = p1.x - p0.x;
		local dy = p1.y - p0.y;
		return this.sqrt(dx * dx + dy * dy);
	}

	function _isMove( p, diff )
	{
		return this.abs(p.x - p.startX) > diff || this.abs(p.y - p.startY) > diff;
	}

	function _calcDirection( p )
	{
		local x0 = p.startX;
		local x1 = p.x;
		local y0 = p.startY;
		local y1 = p.y;
		local dx = this.abs(x0 - x1);
		local dy = this.abs(y0 - y1);

		if (dx >= dy)
		{
			return x0 - x1 > 0 ? "Left" : "Right";
		}
		else
		{
			return y0 - y1 > 0 ? "Up" : "Down";
		}
	}

	function _onSingleTap()
	{
		local timeout = this.getCurrentTick() + this.DOUBLETOUCH_GAP;

		while (timeout - this.getCurrentTick() > 0)
		{
			::wait();
		}

		this._onGesture("singleTap");
		this._clear();
	}

	function onTouchDown( x, y, id )
	{
		this._removeTouch(id);
		this._addTouch(x, y, id);
		local now = ::getCurrentTick();
		this._lastDiff = this._lastTick != null ? now - this._lastTick : 0;
		this._lastTick = now;
		this._clearSingleTap();
		this._touchCount = this._touches.len();
		this._taps++;

		if (this._touchCount == 1)
		{
			return this._onGesture("touchdown", {
				x = x,
				y = y
			});
		}
		else if (this._touchCount > 1)
		{
			this._start_angle = this._calcAngle(this._touches[0], this._touches[1]);
			this._start_distance = this._calcDistance(this._touches[0], this._touches[1]);
			this._diff_angle = 0;
			this._diff_distance = 0;
		}
	}

	function onTouchMove( x, y, id )
	{
		this._moveTouch(x, y, id);

		if (this._touchCount == 1)
		{
			local ret;
			local swipe = this._touches.len() > 0 && this._isMove(this._touches[0], this.SWIPE_DISTANCE);

			if (swipe || this._prevSwipe)
			{
				ret = this._onGesture("swiping");
			}

			this._prevSwipe = swipe;
			return ret;
		}
		else if (this._touchCount == 2)
		{
			local diff = this._calcAngle(this._touches[0], this._touches[1]) - this._start_angle;

			if (this.abs(diff) > this.ROTATE_DISTANCE || this._diff_angle != 0)
			{
				this._diff_angle = diff;
				return this._onGesture("rotating", {
					angle = this._diff_angle
				});
			}

			local distance = this._calcDistance(this._touches[0], this._touches[1]);
			local diff = distance - this._start_distance;

			if (this.abs(diff) > this.PINCH_DISTANCE || this._diff_distance != 0)
			{
				this._diff_distance = diff;
				return this._onGesture("pinching", {
					distance = this._diff_distance
				});
			}
		}
	}

	function onTouchUp( x, y, id )
	{
		local ret;
		this._moveTouch(x, y, id);

		if (this._touchCount == 1)
		{
			if (this._onGesture("touch", {
				x = x,
				y = y
			}))
			{
				ret = true;
			}

			if (this._taps == 2 && this._lastDiff <= this.DOUBLETOUCH_GAP)
			{
				if (this._onGesture("doubleTap"))
				{
					ret = true;
				}

				this._clear();
			}
			else if (this._touches.len() > 0 && (this._isMove(this._touches[0], this.SWIPE_DISTANCE) || this._prevSwipe))
			{
				if (this._onGesture("swipe"))
				{
					ret = true;
				}

				if (this._onGesture("swipe" + this._calcDirection(this._touches[0])))
				{
					ret = true;
				}

				this._clear();
			}
			else
			{
				if (this._onGesture("tap"))
				{
					ret = true;
				}

				if (this._taps == 1)
				{
					this._clearSingleTap();
				}
			}
		}
		else if (this._touchCount > 1)
		{
			local ret;
			local t = false;

			if (this._diff_angle != 0)
			{
				local param = {
					angle = this._diff_angle
				};

				if (this._onGesture("rotate", param))
				{
					ret = true;
				}

				if (this._onGesture(this._diff_angle > 0 ? "rotateRight" : "rotateLeft", param))
				{
					ret = true;
				}

				t = true;
			}

			if (this._diff_distance != 0)
			{
				local param = {
					distance = this._diff_distance
				};

				if (this._onGesture("pinch", param))
				{
					ret = true;
				}

				if (this._onGesture(this._diff_distance > 0 ? "pinchOut" : "pinchIn", param))
				{
					ret = true;
				}

				t = true;
			}

			if (!t)
			{
				local p = this._touches[0];

				if (this._isMove(this._touches[0], this.DRAG_DISTANCE))
				{
					if (this._onGesture("drag"))
					{
						ret = true;
					}

					if (this._onGesture("drag" + this._calcDirection(this._touches[0])))
					{
						ret = true;
					}
				}
			}

			this._clear();
		}
		else
		{
			this._clear();
		}

		this._removeTouch(id);
		return ret;
	}

}

