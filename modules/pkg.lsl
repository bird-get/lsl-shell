integer CHANNEL = -54321;
string ENDPOINT_SCRIPT_NAME = "endpoint.lsl";
string COMMAND = "pkg";
string USAGE = \
"usage: pkg [-h] command [args...]
 
Install or uninstall modules from a nearby repository.

arguments:
  install MODULE        install MODULE
  uninstall MODULE      uninstall MODULE
  enable MODULE         enable MODULE
  disable MODULE        disable MODULE
  list                  list installable modules
  current               list currently installed modules

optional arguments:
  -h, --help    show help and exit
";

integer listen_handle;
string installing_module;
key command_request_id;

string pkg(list params)
{
    // Display help
    if(llListFindList(params, ["-h"]) != -1 ||
        llListFindList(params, ["--help"]) != -1)
    {
        return USAGE;
    }

    string cmd = llList2String(params, 0);
    string module = llList2String(params, 1);

    if(cmd == "install") return install_module(module);
    else if(cmd == "uninstall") return uninstall_module(module);
    else if(cmd == "enable") return enable_module(module);
    else if(cmd == "disable") return disable_module(module);
    else if(cmd == "list") return list_modules();
    else if(cmd == "current") return list_installed_modules();

    if(llGetListLength(params) == 0)
        return llList2Json(JSON_OBJECT, ["error", "Missing command."]);

    return llList2Json(JSON_OBJECT, ["error", "Invalid command."]);
}

string install_module(string module)
{
    // TODO Sanitize module name
    installing_module = module;
    string data = llList2Json(JSON_OBJECT, ["command", "request", "module", module]);
    listen_handle = llListen(CHANNEL, "", "", "");
    llRegionSay(CHANNEL, data);
    return "AWAIT";
}

string uninstall_module(string module)
{
    return "TODO";
}

string enable_module(string module)
{
    string name = module;

    if(module == "") return llList2Json(JSON_OBJECT, ["error", "Missing argument."]);

    // Append extension if it's missing
    if(llGetSubString(module, -4, -1) != ".lsl") module = module + ".lsl";
    else name = llGetSubString(module, 0, -5);

    // Return error if module does not exist
    integer exists = llListFindList(get_installed_modules(), [module]);
    if(exists == -1) return llList2Json(JSON_OBJECT, ["error", "Module is not installed."]);

    if(llGetScriptState(module) == FALSE)
    {
        llSetScriptState(module, TRUE);
        return "Module '" + name + "' enabled.";
    }

    return llList2Json(JSON_OBJECT, ["error", "Module '" + name + "' is already enabled."]);
}

string disable_module(string module)
{
    // TODO Refactor; lots of code duplication
    string name = module;

    if(module == "") return llList2Json(JSON_OBJECT, ["error", "Missing argument."]);

    // Append extension if it's missing
    if(llGetSubString(module, -4, -1) != ".lsl") module = module + ".lsl";
    else name = llGetSubString(module, 0, -5);

    // Return error if module does not exist
    integer exists = llListFindList(get_installed_modules(), [module]);
    if(exists == -1) return llList2Json(JSON_OBJECT, ["error", "Module is not installed."]);

    if(llGetScriptState(module) == TRUE)
    {
        llSetScriptState(module, FALSE);
        return "Module '" + name + "' disabled.";
    }

    return llList2Json(JSON_OBJECT, ["error", "Module '" + name + "' is already disabled."]);
}

string list_modules()
{
    return llList2Json(JSON_ARRAY, ["TODO 1", "TODO 2"]);
}

string list_installed_modules()
{
    list rows = [llList2Json(JSON_ARRAY, ["Name", "Version", "Enabled"])];
    list modules = get_installed_modules();
    integer count = llGetListLength(modules);
    while(count--)
    {
        // TODO Get version number
        string name = llList2String(modules, count);
        string enabled = "Yes";
        if(llGetScriptState(name) == FALSE) enabled = "No";
        name = llGetSubString(name, 0, -5);
        rows += [llList2Json(JSON_ARRAY, [name, "unknown", enabled])];
    }
    return llList2Json(JSON_ARRAY, rows);
}

list get_installed_modules()
{
    /* Return a list of installed modules. */

    list modules;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(count--)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName() && name != ENDPOINT_SCRIPT_NAME)
        {
            string extension = llGetSubString(name, -4, -1);
            if(extension == ".lsl")
            {
                modules += [name];
            }
        }
    }
    return modules;
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);

        if(id == "get_commands")
        {
            llMessageLinked(LINK_SET, 0, COMMAND + "|" + USAGE, "command_info");
        }
        else if(param0 == COMMAND)
        {
            command_request_id = id;
            string result = pkg(llDeleteSubList(params, 0, 0));
            if(result != "AWAIT") llMessageLinked(LINK_SET, 1, result, id);
        }
    }

    listen(integer channel, string name, key id, string data)
    {
        llOwnerSay(data);
        llOwnerSay(installing_module);
        // TODO Validate response data

        integer available = (integer)llJsonGetValue(data, ["available"]);

        if(!available)
        {
            string result = llList2Json(JSON_OBJECT, ["error", "Module not available in repository."]);
            llMessageLinked(LINK_SET, 1, result, command_request_id);
            return;
        }

        integer pin = (integer)llJsonGetValue(data, ["pin"]);

        llSetRemoteScriptAccessPin(pin);

        string response = llList2Json(JSON_OBJECT, ["command", "send",
                                                    "module", installing_module]);
        llRegionSayTo(id, channel, response);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            // TODO cleanup; disable script pin, remove listen, etc.
            // TODO Validate if correct script was added
            integer script_added = TRUE;
            if(script_added)
            {
                llMessageLinked(LINK_SET, 1, "Module '" + installing_module + "' installed.", command_request_id);
            }
            else
            {
                // TODO Return message with removed module
                llMessageLinked(LINK_SET, 1, "TODO", command_request_id);
            }
        }
    }
}
