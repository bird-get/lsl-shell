string COMMAND = "echo";
string USAGE = "usage: echo [arg ...]

                Repeat the given arguments.";

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);
        string param1 = llList2String(params, 1);

        if(id == "get_commands")
        {
            llMessageLinked(LINK_SET, 0, COMMAND + "|" + USAGE, "command_info");
        }
        else if(param0 == "echo")
        {
            string response = llDumpList2String(llDeleteSubList(params, 0, 0), " ");
            llMessageLinked(LINK_SET, 1, response, id);
        }
    }
}
