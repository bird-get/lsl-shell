integer CHANNEL = -54321;
string ENDPOINT_SCRIPT_NAME = "endpoint.lsl";
string COMMAND = "pkg";
string USAGE = \
"usage: pkg [-h] command [args...]
 
Manage modules. Installing modules requires a nearby repository.

arguments:
  install MODULE        install MODULE from nearby repository
  remove MODULE         remove MODULE
  enable MODULE         enable MODULE
  disable MODULE        disable MODULE
  query                 query installable modules
  list                  list currently installed modules

optional arguments:
  -h, --help    show help and exit
";

integer listen_handle;
string installing_module;
key command_request_id;
list old_modules;

string pkg(list params)
{
    /* Parse the param list to call sub-commands depending on user input.

       Return the output of the sub-command.
       On error or invalid input, return a JSON object with a short descriptive message.
    */

    // Display help
    if(llListFindList(params, ["-h"]) != -1 ||
        llListFindList(params, ["--help"]) != -1 ||
        llGetListLength(params) == 0)
    {
        return USAGE;
    }

    string cmd = llList2String(params, 0);

    if(cmd == "query") return query_modules();
    else if(cmd == "list") return list_installed_modules();

    // Parse module param; check for errors and append '.lsl'
    string module = llList2String(params, 1);
    if(module == "") return llList2Json(JSON_OBJECT, ["error", "Missing argument."]);
    if(llGetSubString(module, -4, -1) != ".lsl") module = module + ".lsl";

    if(cmd == "install") return install_module(module);

    // Return error if module does not exist
    integer exists = llListFindList(get_installed_modules(), [module]);
    if(exists == -1) return llList2Json(JSON_OBJECT, ["error", "Module is not installed."]);

    if(cmd == "remove") return remove_module(module);
    else if(cmd == "enable") return enable_module(module);
    else if(cmd == "disable") return disable_module(module);

    return llList2Json(JSON_OBJECT, ["error", "Invalid command."]);
}

string install_module(string module)
{
    /* Start the install process for the given module.

       Send a request to a repository in the sim and wait for a response.
    */
    installing_module = module;
    old_modules = get_installed_modules();
    listen_handle = llListen(CHANNEL, "", "", "");
    string data = llList2Json(JSON_OBJECT, ["command", "request", "module", module]);
    llRegionSay(CHANNEL, data);
    return "AWAIT";
}

string remove_module(string module)
{
    /* Remove the given module from our inventory.
    */
    llRemoveInventory(module);
    string name = llGetSubString(module, 0, -5);
    return "Module '" + name + "' removed.";
}

string enable_module(string module)
{
    /* Set the script state of the module to TRUE if not already enabled.
    */
    string name = llGetSubString(module, 0, -5);

    if(llGetScriptState(module) == FALSE)
    {
        llSetScriptState(module, TRUE);
        return "Module '" + name + "' enabled.";
    }

    return llList2Json(JSON_OBJECT, ["error", "Module '" + name + "' is already enabled."]);
}

string disable_module(string module)
{
    /* Set the script state of the module to FALSE if not already disabled.
    */
    string name = llGetSubString(module, 0, -5);

    if(llGetScriptState(module) == TRUE)
    {
        llSetScriptState(module, FALSE);
        return "Module '" + name + "' disabled.";
    }

    return llList2Json(JSON_OBJECT, ["error", "Module '" + name + "' is already disabled."]);
}

string query_modules()
{
    /* Broadcast a message with a query for available modules.
    */
    listen_handle = llListen(CHANNEL, "", "", "");
    string data = llList2Json(JSON_OBJECT, ["command", "query"]);
    llRegionSay(CHANNEL, data);
    llSetTimerEvent(3);
    return "AWAIT";
}

string list_installed_modules()
{
    /* Return a JSON array with installed modules.
    */
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
    /* Return a list of installed modules.
    */
    list modules;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(count--)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(name != llGetScriptName() && name != ENDPOINT_SCRIPT_NAME)
        {
            string extension = llGetSubString(name, -4, -1);
            if(extension == ".lsl") modules += [name];
        }
    }
    return modules;
}

list list_x_not_y(list lx, list ly)
{
    /* Return a list of items that are in list X, but not in list Y.

       Source: http://wiki.secondlife.com/wiki/ListXnotY
    */
    list lz;
    integer i = llGetListLength(lx);
    while(i--)
    {
	    if(!~llListFindList(ly,llList2List(lx,i,i)))
        {
            lz += llList2List(lx,i,i);
        }
    }
    return lz;
}

string handle_inventory_change()
{
    /* Examine the inventory change and return an appropriate response.
    */
    string response;
    string name = llGetSubString(installing_module, 0, -5);
    list new_modules = get_installed_modules();
    if(llGetListLength(new_modules) == llGetListLength(old_modules))
    {
        response = "Module '" + name + "' reinstalled.";
    }
    else
    {
        // Ensure the correct script was added
        list diff = list_x_not_y(get_installed_modules(), old_modules);
        if(llList2String(diff, 0) == installing_module)
        {
            response = "Module '" + name + "' installed.";
        }
        else
        {
            response = llList2Json(JSON_OBJECT, ["error", "Warning: Unexpected module '" + installing_module + "' was installed!"]);
        }
    }

    llSetRemoteScriptAccessPin(0);
    llListenRemove(listen_handle);
    installing_module = "";

    return response;
}

respond(integer code, string data)
{
    /* Send a response to the endpoint.

       If error_msg is not empty, it will be sent instead of data.
    */
    key id = command_request_id;
    if(code == -1) id = "command_info";

    llMessageLinked(LINK_SET, code, data, id);
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);

        if(id == "get_commands")
        {
            respond(-1, COMMAND + "|" + USAGE);
        }
        else if(param0 == COMMAND)
        {
            command_request_id = id;
            string result = pkg(llDeleteSubList(params, 0, 0));
            if(result != "AWAIT")
            {
                string error = llJsonGetValue(result, ["error"]);
                if(error != JSON_INVALID)
                {
                    respond(1, error);
                    return;
                }
                respond(0, result);
            }
        }
    }

    listen(integer channel, string name, key id, string data)
    {
        // Return the error message if the repository raised one
        string error = llJsonGetValue(data, ["error"]);
        if(error != JSON_INVALID)
        {
            respond(1, error);
            return;
        }

        // Return the module listing if the repository returned it
        string modules = llJsonGetValue(data, ["modules"]);
        if(modules != JSON_INVALID)
        {
            string response = llList2Json(JSON_OBJECT, ["Modules"] + (list)modules);
            respond(0, response);
            return;
        }

        // Return an error message if the module is not available in the repository
        integer available = (integer)llJsonGetValue(data, ["available"]);
        if(!available)
        {
            respond(1, "Module not available in repository.");
            return;
        }

        // Set the script access PIN that was returned by the repository
        // in order to accept the new module
        integer pin = (integer)llJsonGetValue(data, ["pin"]);
        llSetRemoteScriptAccessPin(pin);

        // Ask the repository to send the new module
        string response = llList2Json(JSON_OBJECT, ["command", "send",
                                                    "module", installing_module]);
        llRegionSayTo(id, channel, response);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY && installing_module != "")
        {
            respond(0, handle_inventory_change());
        }
    }

    timer()
    {
        respond(1, "No repository nearby.");
        llSetTimerEvent(0);
    }
}
