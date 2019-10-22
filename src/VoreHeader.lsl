#ifndef VoreHeader
#define VoreHeader
//This header is a place to reduce duplicate code

//special channel unique key
#define ChannelKey 11

//channel calculator
integer generateChan(key id) {
    return 0x80000000 | ((integer)("0x"+(string)id) ^ ChannelKey);
}


#endif //VoreHeader
