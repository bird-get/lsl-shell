import requests
import warnings
from urllib3.connectionpool import InsecureRequestWarning
from json.decoder import JSONDecodeError
import sys

SECRET_KEY: str = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9"

warnings.filterwarnings("ignore", category=InsecureRequestWarning)

def init() -> str:
    initialized: bool = False
    while not initialized:
        try:
            data = {"secret_key": SECRET_KEY,
                    "command": "init"}
            url = input("url > ")
            response = requests.post(url, json=data, verify=False)
            error = response.json().get("error")
            if error:
                print(f"Error: {error}")
                sys.exit(1)
        except (requests.ConnectionError, requests.exceptions.MissingSchema,
                requests.exceptions.InvalidURL):
            print("Error: Invalid URL")
        except (KeyError, JSONDecodeError):
            print(f"Error: Invalid response")
        else:
            try:
                uuid = response.json().get("uuid")
            except KeyError:
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
        data = {"secret_key": SECRET_KEY,
                "command": input("sl > ")}
        response = requests.post(url, json=data, verify=False)
        print(response.content.decode("utf-8"))

try:
    url = init()
    run(url)
except EOFError:
    disconnect(url)
    pass
