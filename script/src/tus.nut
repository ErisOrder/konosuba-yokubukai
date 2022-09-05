class this.TUS extends this.NetworkModule
{
	constructor( info )
	{
		::NetworkModule.constructor();
		this.setup(info.communicationId, info.passPhrase, info.signature);

		for( local i = 1; i <= info.count; i++ )
		{
			this.setUserStorageSize(i, info.size);
		}

		this.printf("TUS Initialize:%s\n", info.communicationId);
	}

	logoffFlag = false;
	function onStatus( state, error )
	{
		if (state == 0)
		{
			this.logoffFlag = true;
		}
	}

	function checkLogin()
	{
		if (!("getAge" in this))
		{
			local ret = this.isLoginUser();

			if (ret < 0)
			{
				return ret;
			}

			if (ret == 0)
			{
				this.openStartDialog(3, this.RESTRICTED_AGE);
				local ret;
				ret = this.checkStartDialog();

				while (ret == null)
				{
					this.wait(0);
				}

				if (ret < 0)
				{
					return ret;
				}

				ret = this.isLoginUser();

				if (ret < 0)
				{
					return ret;
				}

				if (ret == 0)
				{
					return -1;
				}
			}
		}
		else
		{
			if (this.isLoginUser() == false)
			{
				this.openStartDialog(3);

				while (this.checkStartDialog() == null)
				{
					this.wait(0);
				}

				if (this.isLoginUser() == false)
				{
					return -1;
				}
			}

			this.printf("restricted:%s %s\n", this.restricted, this.age);

			if (this.restricted && this.age < this.RESTRICTED_AGE)
			{
				return -2;
			}
		}

		this.logoffFlag = false;
		return true;
	}

	function sendMain( structRaw, slot = 1 )
	{
		this.printf("TUS send test start\n");
		this.logoffFlag = false;
		local result;

		if (this.sendUserStorage(slot, structRaw) == true)
		{
			local timeout = 0;
			result = this.checkSendUserStorage();

			while (result == null)
			{
				if (timeout++ > 15 * 60)
				{
					return null;
				}

				this.wait(0);
			}

			if (this.logoffFlag)
			{
				return -3;
			}

			if (typeof result == "integer")
			{
				if (result < 0)
				{
					this.printf("sendUserStorage error :%08x\n", result);

					if (result == 2147656819)
					{
						return false;
					}

					return result;
				}
				else
				{
					this.printf("TUS send success.%d\n", result);
					return true;
				}
			}
		}
		else
		{
			if (this.logoffFlag)
			{
				return -3;
			}

			if (typeof result == "integer")
			{
				this.printf("error :%08x\n", result);
				return result;
			}
			else
			{
				this.printf("TUS send fail\n");
				return null;
			}
		}
	}

	function recvMain( slot = 1 )
	{
		this.printf("TUS recv test start\n");
		this.logoffFlag = false;
		local result = 0;
		result = this.recvUserStorage(slot);

		if (result == true)
		{
			result = 0;
			local timeout = 0;
			result = this.checkRecvUserStorage();

			while (result == null)
			{
				if (timeout++ > 15 * 60)
				{
					return null;
				}

				this.wait(0);
			}

			if (this.logoffFlag)
			{
				return -3;
			}

			if (typeof result == "integer")
			{
				this.printf("recv user storage error :%08x\n", result);
				return result;
			}

			return result;
		}
		else
		{
			if (this.logoffFlag)
			{
				return -3;
			}

			if (typeof result == "integer")
			{
				this.printf("recvUserStorage error :%08x\n", result);
				return result;
			}
			else
			{
				this.printf("TUS recv fail\n");
				return null;
			}
		}
	}

	function doSave( struct, slot = 1 )
	{
		local ret = this.sendMain(struct.serialize(), slot);

		if (ret == null)
		{
			this.print("TUS SEND FAIL.\n");
			return false;
		}
		else if (ret == true)
		{
			this.print("SEND SUCCESS\n");
			return true;
		}
		else
		{
			if (typeof ret == "integer")
			{
				return ret;
			}

			return false;
		}
	}

	function doLoad( struct, slot = 1 )
	{
		local ret = this.recvMain(slot);

		if (ret == null)
		{
			this.print("TUS RECV FAIL.\n");
			return false;
		}

		if (typeof ret == "integer")
		{
			this.printf("TUS RECV error:%08x\n", ret);
			return ret;
		}

		struct.clear();

		try
		{
			struct.unserialize(ret);
			this.print("RECV SUCCESS\n");
			return true;
			  // [031]  OP_POPTRAP        1      0    0    0
		}
		catch( e )
		{
			this.print("SAVEDATA IS BROKEN." + e + "\n");
			return false;
		}
	}

}

