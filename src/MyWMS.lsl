#include "VoreHeader.lsl"

#define startingWight 40
#define SecondsInAminute 60
#define COLOR_WHITE < 1.0, 1.0, 1.0 >
#define OPAQUE 1.0
#define OneCalory 7.7161
#define CaloriesInOneLB 3500
#define StartingDigestion 5
#define StartingMetab 1.24
//in kg
float Weight = startingWight;
// in grams
float MaxAppitie = 2000;
float fullness = 0;
//grams per minute
float Digestion = StartingDigestion;
//callories per minute
float metabolism = StartingMetab;
//grams Converted
float callories = 0;
//activity user is currently performing
string Activity;
integer ActivityNumber = 0;
float TimeDilation = 1.0;

integer ClockSeconds = 0;

float VisibleFullness = 0;

integer SpecialChannel;

string FormatDecimal(float number, integer precision)
{
    float roundingValue = llPow(10, -precision) * 0.5;
    float rounded;
    if (number < 0) rounded = number - roundingValue;
    else rounded = number + roundingValue;

    if (precision < 1) // Rounding integer value
    {
        integer intRounding = (integer)llPow(10, -precision);
        rounded = (integer)rounded / intRounding * intRounding;
        precision = -1; // Don't truncate integer value
    }

    string strNumber = (string)rounded;
    return llGetSubString(strNumber, 0, llSubStringIndex(strNumber, ".") + precision);
}
string MyformattedDec(float Number) {
    return FormatDecimal(Number, 2);
}
DigestAndBurn() {
    if(Weight > startingWight) {
        Weight -= metabolism;
    }
    //Handle Digestion increases if full of food
    if(VisibleFullness > 100) {
        Digestion += 5;
    }
    //slowly decrease digestion overtime
    if(VisibleFullness < 100 & Digestion > StartingDigestion) {
        Digestion -= 1;
    }
}
FasterUpdating() {
    if (fullness > 0) {
        fullness -= Digestion;
        callories += Digestion;
    }
    if(callories > CaloriesInOneLB) {
        float foundlbs = callories/CaloriesInOneLB;
        Weight += foundlbs;
        callories -= (CaloriesInOneLB*foundlbs);
    }

}
UpdateStats() {
    VisibleFullness = (fullness / MaxAppitie) * 100;
    GetAgentActivity();
    if (fullness < 0) {
        fullness = 0;
    }
    if (Weight < 0) {
        Weight = 0;
    }
    if(callories < 0) {
        callories =0;
    }
    FasterUpdating();
}

GetAgentActivity() {
    integer buf = llGetAgentInfo(llGetOwner());
    if ((buf & AGENT_SITTING) || (buf & AGENT_ON_OBJECT)) {
        Activity = "Sitting";
        ActivityNumber = 0;
    } else if (buf & AGENT_WALKING) {
        Activity = "Walking";
        ActivityNumber = 1;
    } else if (buf & AGENT_IN_AIR) {
        Activity = "In Air";
        ActivityNumber = 2;
    } else {
        Activity = "Standing";
        ActivityNumber = 3;
    }
}
PrintVisibleStats()
{
    string MyText;
    MyText = MyText + "Activity: " + Activity + "\n";
    MyText = MyText + "Weight: " + MyformattedDec(Weight) + " kg\n";
    MyText = MyText + "Max appitie: " + MyformattedDec(MaxAppitie) + " g\n";
    MyText = MyText + "Fullness: " + FormatDecimal(VisibleFullness, 0) + "%\n";
    MyText = MyText + "Digestion: " + MyformattedDec(Digestion) + " g/min\n";
    MyText = MyText + "Metabolism: " + MyformattedDec(metabolism) + " cal/min";
    llSetText(MyText, COLOR_WHITE, OPAQUE);
}

default
{
    state_entry()
    {
        SpecialChannel = generateChan(llGetOwner());
        llListen(SpecialChannel, "", "", "");
        llSetTimerEvent(TimeDilation);
    }
    timer()
    {
        if (ClockSeconds <= SecondsInAminute) {
            ClockSeconds = ClockSeconds + 1;
            UpdateStats();
            PrintVisibleStats();
        } else {
            DigestAndBurn();
            ClockSeconds = 0;
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        list innerMessage = llParseString2List(message, [" "], [""]);
        string Command = llList2String(innerMessage, 0);
        if (Command == "feed") {
            float fedamount = llList2Float(innerMessage, 1);
            llOwnerSay("You were fed: " + FormatDecimal(fedamount, 2));
            fullness += fedamount;
        }
    }
}