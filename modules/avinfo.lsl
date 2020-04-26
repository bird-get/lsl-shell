string COMMAND = "avinfo";
string USAGE = \
"usage: avinfo [uuid] [-h]
 
Request info about avatar with the given UUID.

positional arguments:
  uuid          uuid of avatar

optional arguments:
  -h, --help    show help and exit

ex: avinfo c53bf932-81ea-4a9f-b464-c4b545f93db1
";

string avinfo(list params)
{
    // Display help
    if(llListFindList(params, ["-h"]) != -1 ||
        llListFindList(params, ["--help"]) != -1 ||
        llGetListLength(params) == 0)
    {
        return USAGE;
    }

    key id = llList2Key(params, 0);

    list rows = [];

    list details = llGetObjectDetails(id, [
        OBJECT_RENDER_WEIGHT, OBJECT_STREAMING_COST,
        OBJECT_HOVER_HEIGHT, OBJECT_BODY_SHAPE_TYPE, OBJECT_GROUP_TAG,
        OBJECT_ATTACHED_SLOTS_AVAILABLE, 
        OBJECT_RUNNING_SCRIPT_COUNT, OBJECT_TOTAL_SCRIPT_COUNT,
        OBJECT_SCRIPT_MEMORY, OBJECT_SCRIPT_TIME]);

    rows += llList2Json(JSON_OBJECT, ["display name", llGetDisplayName(id)]);
    rows += llList2Json(JSON_OBJECT, ["username", llGetUsername(id)]);
    rows += llList2Json(JSON_OBJECT, ["language", llGetAgentLanguage(id)]);

    string group_tag = llList2String(details, 4);
    if(group_tag == "") group_tag = "none";
    rows += llList2Json(JSON_OBJECT, ["group tag", group_tag]);

    float hover_height = llList2Float(details, 2);
    float body_shape = llList2Float(details, 3);
    rows += llList2Json(JSON_OBJECT, ["hover height", (string)hover_height]);
    rows += llList2Json(JSON_OBJECT, ["body shape", (string)body_shape]);
    rows += llList2Json(JSON_OBJECT, ["size", (string)llGetAgentSize(id)]);

    rows += llList2Json(JSON_OBJECT, ["attached slots", llList2String(details, 5)]);

    float streaming_cost = llList2Float(details, 1);
    string render_weight = llList2String(details, 0);
    rows += llList2Json(JSON_OBJECT, ["streaming cost", (string)streaming_cost]);
    rows += llList2Json(JSON_OBJECT, ["render weight", (string)render_weight]);

    string running_scripts = llList2String(details, 6);
    string total_scripts = llList2String(details, 7);
    string script_memory = (string)llRound(llList2Float(details, 8) / 1024);
    float script_time = llList2Float(details, 9);
    rows += llList2Json(JSON_OBJECT, ["script count", running_scripts + " / " + total_scripts]);
    rows += llList2Json(JSON_OBJECT, ["script memory", script_memory + " kb"]);
    rows += llList2Json(JSON_OBJECT, ["script time", (string)((integer)((script_time*1000000))) + " μs"]);

    return llList2Json(JSON_ARRAY, rows);
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);
        string param1 = llList2String(params, 1);

        if(id == "get_commands")
        {
            llMessageLinked(LINK_SET, -1, COMMAND + "|" + USAGE, "command_info");
        }
        else if(param0 == COMMAND)
        {
            string response = avinfo(llDeleteSubList(params, 0, 0));
            llMessageLinked(LINK_SET, 0, response, id);
        }
    }
}
