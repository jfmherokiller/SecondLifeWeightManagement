#include "VoreHeader.lsl"

#define startingWight 40
#define SecondsInAminute 60
#define COLOR_WHITE < 1.0, 1.0, 1.0 >
#define OPAQUE 1.0
#define OneCalory 7.7161
#define CaloriesInOneLB 3500
#define StartingDigestion 5
#define StartingMetab 1.24
#define ImmobleWeight 907
#define StartingMaxApp 2000
integer IMMOBLE = FALSE;
integer WeightImpared = FALSE;

integer Controls = CONTROL_FWD|
                CONTROL_BACK |
                CONTROL_LEFT |
                CONTROL_RIGHT |
                CONTROL_ROT_LEFT |
                CONTROL_ROT_RIGHT |
                CONTROL_UP |
                CONTROL_DOWN |
                CONTROL_LBUTTON |
                CONTROL_ML_LBUTTON;

//in kg
float Weight = startingWight;
// in grams
float MaxAppitie = StartingMaxApp;
float fullness = 0;
//grams per minute
float Digestion = StartingDigestion;
//callories per minute
float metabolism = StartingMetab;
//grams Converted
float callories = 0;
//activity user is currently performing
string Activity;
float ActivityNumber = 0;

float TimeDilation = 1.0;

integer ClockSeconds = 0;

float VisibleFullness = 0;

integer SpecialChannel;
float WeightPecent() {
    return (Weight/ImmobleWeight);
}
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
        Weight -= (metabolism * ActivityNumber);
    }
    //Handle Digestion/appitite increases if full of food
    if(VisibleFullness > 100) {
        Digestion += 5;
        MaxAppitie += 5;
    }
    //slowly decrease digestion overtime
    if(VisibleFullness < 100 & Digestion > StartingDigestion) {
        Digestion -= 1;
    }
    if(VisibleFullness < 100 & MaxAppitie > StartingMaxApp) {
        MaxAppitie -= 1;
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
    if(Weight >= 100) {
        if(!WeightImpared) {
            WeightImpared = TRUE;
            llTakeControls(Controls,TRUE, TRUE);
            llOwnerSay("Your massive belly is starting to make getting around tougher");
        }
        if(Weight >= ImmobleWeight) {
            if(!IMMOBLE) {
                IMMOBLE = TRUE;
                llOwnerSay("You have lost the ability to move");
                llTakeControls(Controls,TRUE, FALSE);
            }
        } else {
            if(IMMOBLE) {
                llOwnerSay("You have regained the ability to move");
                IMMOBLE = FALSE;
                llTakeControls(Controls,TRUE, TRUE);
            }
        }
    } else if( Weight <= 100) {
        if(WeightImpared || IMMOBLE) {
            WeightImpared = FALSE;
            IMMOBLE = FALSE;
            llTakeControls(Controls,FALSE,FALSE);
            llOwnerSay("Your weight no longer impedes your travel");
        }
    }
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
        ActivityNumber = 1;
    } else if (buf & AGENT_WALKING) {
        Activity = "Walking";
        ActivityNumber = 1.5;
    } else if (buf & AGENT_IN_AIR) {
        Activity = "In Air";
        ActivityNumber = 2;
    } else {
        Activity = "Standing";
        ActivityNumber = 1;
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
        llRequestPermissions(llGetOwner() ,PERMISSION_OVERRIDE_ANIMATIONS| PERMISSION_TRIGGER_ANIMATION| PERMISSION_TAKE_CONTROLS);
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
            llOwnerSay("You were fed: " + FormatDecimal(fedamount, 2) + " g");
            fullness += fedamount;
        }
    }
    control( key id, integer level, integer edge )
    {
        if(IMMOBLE) return;
         if(level & CONTROL_FWD)
        {
            if(llGetAgentInfo(llGetOwner()) & AGENT_WALKING )  

            { 
                llApplyImpulse(<-WeightPecent(),0,0>,TRUE);
            }
        }
    }
}