integer connected = 0;
key SECRET_KEY = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9";

default
{
    state_entry()
    {
        llRequestSecureURL();
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
                    llHTTPResponse(id, 200, "{\"uuid\": \"" + string(llGetKey()) + "\"}");
                    connected = 1;
                }
                else if(llJsonGetValue(body, ["command"]) == "disconnect")
                {
                    llHTTPResponse(id, 200, "{\"result\": \"disconnected\"}");
                    connected = 0;
                }
                else
                {
                    llHTTPResponse(id, 200, "{\"result\": \"success\"}");
                }
            }
            else
            {
                llHTTPResponse(id, 401, "{\"error\": \"Invalid secret key\"}");
            }
        }
    }
}
