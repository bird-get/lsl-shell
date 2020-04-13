integer connected = 0;
key SECRET_KEY = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9";
list commands = [];

respond(key id, integer status, string key_, string data)
{
    llHTTPResponse(id, status, llList2Json(JSON_OBJECT, [key_, data]));
}

broadcast_command(key request_id, string command)
{
    // Broadcast the message to other scripts. We expect one script to return
    // a link_message in response. We pass the request_id to be able
    // to identify the response.
    llMessageLinked(LINK_SET, 0, command, request_id);
}

default
{
    state_entry()
    {
        llRequestSecureURL();
        llMessageLinked(LINK_SET, 0, "", "request_command_info");
    }

    link_message(integer link, integer num, string msg, key id)
    {
        if(id == "command_info")
        {
            commands += llParseString2List(msg, ["|"], []);
        }
        else if(num == 1)
        {
            respond(id, 200, "result", msg);
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER || change & CHANGED_REGION || \
           change & CHANGED_REGION_START)
            llResetScript();
    }

    http_request(key id, string method, string body)
    {
        if(method == URL_REQUEST_GRANTED)
        {
            string url = body;
            llOwnerSay(url);
        }
        else if(method == "POST")
        {
            llOwnerSay("POST: " + body);
            if(llJsonGetValue(body, ["secret_key"]) == SECRET_KEY)
            {
                string command = llJsonGetValue(body, ["command"]);
                if(command == "connect")
                {
                    if(connected == FALSE)
                    {
                        respond(id, 200, "uuid", llGetKey());
                        connected = TRUE;
                    }
                    else
                    {
                        respond(id, 423, "error", "Session is currently in use");
                    }
                }
                else if(command == "disconnect")
                {
                    respond(id, 200, "result", "disconnected");
                    connected = FALSE;
                }
                else if(command == "get_commands")
                {
                    respond(id, 200, "available_commands", llList2Json(JSON_OBJECT, \
                                                                       commands));
                }
                else
                {
                    broadcast_command(id, command);
                }
            }
            else
            {
                respond(id, 401, "error", "Invalid secret key");
            }
        }
    }
}
