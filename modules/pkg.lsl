string ENDPOINT_SCRIPT_NAME = "endpoint.lsl";
string COMMAND = "pkg";
string USAGE = \
"usage: pkg [-h] command [args...]
 
Install or uninstall modules from a nearby repository.

arguments:
  install MODULE        install MODULE
  uninstall MODULE      uninstall MODULE
  list                  list installable modules
  current               list currently installed modules

optional arguments:
  -h, --help    show help and exit
";

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

    if(cmd == "install")
    {
        return install_module(module);
    }
    else if(cmd == "uninstall")
    {
        return uninstall_module(module);
    }
    else if(cmd == "list")
    {
        return list_modules();
    }
    else if(cmd == "current")
    {
        return list_installed_modules();
    }

    return llList2Json(JSON_OBJECT, ["error", "Invalid command."]);
}

string install_module(string module)
{
    return "TODO";
}

string uninstall_module(string module)
{
    return "TODO";
}

string list_modules()
{
    return llList2Json(JSON_ARRAY, ["TODO 1", "TODO 2"]);
}

string list_installed_modules()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    list rows = [llList2Json(JSON_ARRAY, ["Name", "Version"])];
    while(count--)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName() && name != ENDPOINT_SCRIPT_NAME)
        {
            string extension = llGetSubString(name, -4, -1);
            if(extension == ".lsl")
            {
                // TODO Get version number
                name = llGetSubString(name, 0, -5);
                rows += [llList2Json(JSON_ARRAY, [name, "unknown"])];
            }
        }
    }
    return llList2Json(JSON_ARRAY, rows);
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
            string result = pkg(llDeleteSubList(params, 0, 0));
            llMessageLinked(LINK_SET, 1, result, id);
        }
    }
}