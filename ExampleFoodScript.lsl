integer generateChan(key id) {
    return 0x80000000 | ((integer)("0x"+(string)id) ^ 11);
}

default
{
	touch_start(integer s)
	{
		integer BaseChannel = generateChan(llDetectedKey(0));
        llSay(BaseChannel,"feed 5000");
	}
}