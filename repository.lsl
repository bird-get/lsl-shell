integer CHANNEL = -54321;

integer pin;
regenerate_pin()
{
    // TODO Generate a random PIN
    pin = 1234;
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
        }
        else if(command == "send")
        {
            llRemoteLoadScriptPin(id, module, pin, TRUE, 0xDEADBEEF);
        }
    }
}
