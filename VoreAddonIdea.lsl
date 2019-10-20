
#define CaloriesOfHuman 81500
#include "VoreHeader.lsl"


default
{
	touch_start(integer s)
	{
		integer BaseChannel = generateChan(llDetectedKey(0));
        llSay(BaseChannel,"feed " + (string)CaloriesOfHuman);
	}
}