integer connected = FALSE;

blink()
{
    llSetColor(<0,0,0>, ALL_SIDES);
    llSleep(.05);
    if(connected) llSetColor(<0,1,0>, ALL_SIDES);
    else llSetColor(<0,0,0>, ALL_SIDES);
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);

        if(param0 == "connect")
        {
            connected = TRUE;
        }
        else if(param0 == "disconnect")
        {
            connected = FALSE;
        }

        blink();
    }
}
