string COMMAND = "request";
string USAGE = \
"usage: request url [-h] [-m] [-d]
 
Do a HTTP request.

positional arguments:
  url           URL to use

optional arguments:
  -m            method to use (default = GET)
  -d            data to send
  -h, --help    show help and exit
";

key command_request_id;
key http_request_id;


string request(list params)
{
    /* Do a HTTP request.
       Return a string with a message if errors occur.
    */

    // Display help
    if(llListFindList(params, ["-h"]) != -1 ||
        llListFindList(params, ["--help"]) != -1 ||
        !llGetListLength(params))
    {
        return USAGE;
    }

    integer options_mask;
    string method = "GET";
    string data = "";
    string url = llList2String(params, 0);

    // Strip surrounding quotes from url if present
    if(llGetSubString(url, 0, 0) == "\"" && llGetSubString(url, -1, -1) == "\"")
    {
        url = llGetSubString(url, 1, -2);
    }

    // Prepend with http:// if no protocol was specified
    if(llGetSubString(url, 0, 3) != "http")
    {
        url = "http:\/\/" + url;
    }

    // Handle method option
    integer opt_m = llListFindList(params, ["-m"]);
    if(opt_m != -1)
    {
        method = llList2String(params, opt_m + 1);
    }

    // Handle data option
    integer opt_d = llListFindList(params, ["-d"]);
    if(opt_d != -1)
    {
        data = llList2String(params, opt_d + 1);
    }

    list parameters = [
        HTTP_METHOD, method
    ];

    http_request_id = llHTTPRequest(url, parameters, data);

    if(http_request_id == NULL_KEY)
    {
        return llList2Json(JSON_OBJECT, ["error", "URL passed to llHTTPRequest is not valid"]);
    }

    return "";
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        list params = llParseString2List(msg, [" "], [""]);
        string param0 = llList2String(params, 0);

        if(id == "get_commands")
        {
            llMessageLinked(LINK_SET, -1, COMMAND + "|" + USAGE, "command_info");
        }
        else if(param0 == COMMAND)
        {
            command_request_id = id;
            string errors = request(llDeleteSubList(params, 0, 0));
            if(errors != "")
            {
                llMessageLinked(LINK_SET, 1, errors, command_request_id);
            }
        }
    }

    http_response(key id, integer status, list metadata, string body)
    {
        if(id != http_request_id) return;

        llMessageLinked(LINK_SET, 0, body, command_request_id);
    }
}
