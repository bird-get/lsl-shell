integer connected = 0;
key SECRET_KEY = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9";
list commands = [];
key request_id;

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
        else if(id == request_id && num == 1)
        {
            llHTTPResponse(id, 200, llList2Json(JSON_OBJECT, ["result", msg]));
            request_id = "";
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
                if(llJsonGetValue(body, ["command"]) == "init")
                {
                    llHTTPResponse(id, 200, llList2Json(JSON_OBJECT,
                                                        ["uuid", llGetKey()]));
                    connected = 1;
                }
                else if(llJsonGetValue(body, ["command"]) == "disconnect")
                {
                    llHTTPResponse(id, 200, llList2Json(JSON_OBJECT,
                                                        ["result", "disconnected"]));
                    connected = 0;
                }
                else if(llJsonGetValue(body, ["command"]) == "get_commands")
                {
                    llHTTPResponse(id, 200, llList2Json(JSON_OBJECT,
                                                        ["available_commands",
                                                         llList2Json(JSON_OBJECT, commands)
                                                        ]));
                }
                else
                {
                    // Relay the message to other scripts, we handle the response later
                    request_id = id;
                    llMessageLinked(LINK_SET, 0, llJsonGetValue(body, ["command"]), id);
                }
            }
            else
            {
                llHTTPResponse(id, 401, llList2Json(JSON_OBJECT,
                                                    ["error", "Invalid secret key"]));
            }
        }
    }
}
