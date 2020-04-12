integer connected = 0;

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
            if(body == "init")
            {
                llHTTPResponse(id, 200, "{\"uuid\": \"" + string(llGetKey()) + "\"}");
                connected = 1;
            }
            else if(body == "disconnect")
            {
                llHTTPResponse(id, 200, "disconnected");
                connected = 0;
            }
            else
            {
                llOwnerSay("POST: " + body);
                llHTTPResponse(id, 200, "success");
            }
        }
    }
}
