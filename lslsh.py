import requests
import warnings
from urllib3.connectionpool import InsecureRequestWarning
from json.decoder import JSONDecodeError

warnings.filterwarnings("ignore", category=InsecureRequestWarning)

def init() -> str:
    initialized: bool = False
    while not initialized:
        try:
            url = input("url > ")
            response = requests.post(url, data="init", verify=False)
            uuid = response.json().get("uuid")
        except (requests.ConnectionError, requests.exceptions.MissingSchema,
                requests.exceptions.InvalidURL):
            print("Error: Invalid URL")
        except (KeyError, JSONDecodeError):
            print(f"Error: Invalid response")
        else:
            initialized = True

    print(f"Connected to {uuid}")
    print("-------------------------------------------------------------------------------")
    print("")
    return url

def disconnect(url: str):
    response = requests.post(url, data="disconnect", verify=False)
    print("")
    if response.content.decode("utf-8") == "disconnected":
        print("Disconnected from remote.")
    else:
        print("Disconnected from remote (without acknowledgement).")

def run(url: str):
    while True:
        data = {"input": input("sl > ")}
        response = requests.post(url, data=data, verify=False)
        print(response.content.decode("utf-8"))

try:
    url = init()
    run(url)
except EOFError:
    disconnect(url)
    pass
