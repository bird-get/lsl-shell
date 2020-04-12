default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);
        string param1 = llList2String(params, 1);

        if(id == "request_command_info")
        {
            llMessageLinked(LINK_SET, 0, "echo|echo: echo [arg ...]", "command_info");
        }
        else if(param0 == "echo")
        {
            string response = llDumpList2String(llDeleteSubList(params, 0, 0), " ");
            llMessageLinked(LINK_SET, 1, response, id);
        }
    }
}
