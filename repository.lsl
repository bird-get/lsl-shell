integer CHANNEL = -54321;

integer pin;
regenerate_pin()
{
    /* Generate a pseudo-random number to use as a PIN. */
    string md5 = "seed";
    integer count = 10;
    while(count--)
    {
        md5 = llMD5String(md5 + (string)llGetUnixTime() + (string)llGetTime(), 0x5EED);
    }
    pin = (integer)("0x" + llGetSubString(md5, 0, 7));
}

integer module_is_available(string module)
{
    list modules;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(count--)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName())
        {
            string extension = llGetSubString(name, -4, -1);
            if(extension == ".lsl")
            {
                modules += [name];
            }
        }
    }

    if(llListFindList(modules, [module]) == -1) return FALSE;
    else return TRUE;
}

list get_modules()
{
    /* Return a list of available modules.
    */
    list modules;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(count--)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName())
        {
            string extension = llGetSubString(name, -4, -1);
            if(extension == ".lsl") modules += [name];
        }
    }
    return modules;
}

default
{
    state_entry()
    {
        llListen(CHANNEL, "", "", "");
    }

    listen(integer channel, string name, key id, string data)
    {
        // TODO Handle invalid data
        string command = llJsonGetValue(data, ["command"]);
        string module = llJsonGetValue(data, ["module"]);

        if(command == "request")
        {
            string response = llList2Json(JSON_OBJECT, ["available", FALSE]);
            if(module_is_available(module))
            {
                regenerate_pin();
                response = llList2Json(JSON_OBJECT, ["available", TRUE, "pin", pin]);
            }
            llRegionSayTo(id, channel, response);
            return;
        }
        else if(command == "send")
        {
            llRemoteLoadScriptPin(id, module, pin, TRUE, 0xDEADBEEF);
            return;
        }
        else if(command == "query")
        {
            string modules = llList2Json(JSON_ARRAY, get_modules());
            string response = llList2Json(JSON_OBJECT, ["modules", modules]);
            llRegionSayTo(id, channel, response);
            return;
        }

        string response = llList2Json(JSON_OBJECT, ["error", "Invalid command."]);
        llRegionSayTo(id, channel, response);
    }
}
