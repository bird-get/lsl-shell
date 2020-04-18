string COMMAND = "avlist";
string USAGE = \
"usage: avlist [-h] [-s] [-r] [-k]
 
Request info about all avatars in the current region.
 
optional arguments:
  -s            get script info
  -r            get render info
  -k            get key
  -h, --help    show help and exit
";

string avlist(list params)
{
    // Display help
    if(llListFindList(params, ["-h"]) != -1 ||
        llListFindList(params, ["--help"]) != -1)
    {
        return USAGE;
    }

    integer options_mask;
    list headers = ["Name"];
    if(llListFindList(params, ["-k"]) != -1) // option: key
    {
        options_mask += 1;
        headers += ["Key"];
    }
    if(llListFindList(params, ["-s"]) != -1) // option: script info
    {
        options_mask += 2;
        headers += ["Scripts", "Mem (kb)", "Time (μs)"];
    }
    if(llListFindList(params, ["-r"]) != -1) // option: render info
    {
        options_mask += 4;
        headers += ["Streaming cost"];
    }

    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer agent_count = llGetListLength(agents);
    list rows = [llList2Json(JSON_ARRAY, headers)];
    integer i;
    for(i=0; i < agent_count; i++)
    {
        key agent_key = llList2Key(agents, i);
        string agent_name = llKey2Name(agent_key);
        list agent_info = [agent_name];

        // [-k] option: show key
        if(options_mask & 1)
        {
            agent_info += [agent_key];
        }

        // [-s] option: script info
        if(options_mask & 2)
        {
            list object_details = llGetObjectDetails(agent_key, [
                OBJECT_RUNNING_SCRIPT_COUNT, OBJECT_TOTAL_SCRIPT_COUNT,
                OBJECT_SCRIPT_MEMORY, OBJECT_SCRIPT_TIME]);
            integer running_scripts = llList2Integer(object_details, 0);
            integer total_scripts = llList2Integer(object_details, 1);
            integer script_memory = llRound(llList2Float(object_details, 2) / 1024);
            float script_time = llList2Float(object_details, 3);
            
            agent_info += [(string)running_scripts + " / " + (string)total_scripts];
            agent_info += [(string)script_memory];
            agent_info += [(string)((integer)((script_time*1000000)))];
        }

        // [-r] option: render info
        if(options_mask & 4)
        {
            float streaming_cost = llList2Float(llGetObjectDetails(agent_key, [OBJECT_STREAMING_COST]), 0);
            agent_info += [streaming_cost];
        }
        rows += llList2Json(JSON_ARRAY, agent_info);
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
            string response = avlist(llDeleteSubList(params, 0, 0));
            llMessageLinked(LINK_SET, 1, response, id);
        }
    }
}
