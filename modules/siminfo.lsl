string COMMAND = "siminfo";
string USAGE = \
"usage: siminfo

Request simulator details.
";

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
            list rows = [
                llList2Json(JSON_OBJECT, ["agent_limit",  llGetEnv("agent_limit")]),
                llList2Json(JSON_OBJECT, ["dynamic_pathfinding", llGetEnv("dynamic_pathfinding")]),
                llList2Json(JSON_OBJECT, ["estate_id", llGetEnv("estate_id")]),
                llList2Json(JSON_OBJECT, ["estate_name", llGetEnv("estate_name")]),
                llList2Json(JSON_OBJECT, ["frame_number", llGetEnv("frame_number")]),
                llList2Json(JSON_OBJECT, ["region_cpu_ratio", llGetEnv("region_cpu_ratio")]),
                llList2Json(JSON_OBJECT, ["region_idle", llGetEnv("region_idle")]),
                llList2Json(JSON_OBJECT, ["region_product_name", llGetEnv("region_product_name")]),
                llList2Json(JSON_OBJECT, ["region_product_sku", llGetEnv("region_product_sku")]),
                llList2Json(JSON_OBJECT, ["region_start_time", llGetEnv("region_start_time")]),
                llList2Json(JSON_OBJECT, ["sim_channel", llGetEnv("sim_channel")]),
                llList2Json(JSON_OBJECT, ["sim_version", llGetEnv("sim_version")]),
                llList2Json(JSON_OBJECT, ["simulator_hostname", llGetEnv("simulator_hostname")]),
                llList2Json(JSON_OBJECT, ["region_max_prims", llGetEnv("region_max_prims")]),
                llList2Json(JSON_OBJECT, ["region_object_bonus", llGetEnv("region_object_bonus")])
            ];

            string response = llList2Json(JSON_ARRAY, rows);

            llMessageLinked(LINK_SET, 1, response, id);
        }
    }
}
