import requests
import warnings
from urllib3.connectionpool import InsecureRequestWarning
from json.decoder import JSONDecodeError
import sys
from typing import Dict
import readline
import cmd


class Shell(cmd.Cmd):
    prompt = "> "

    def get_names(self):
        return dir(self)

SECRET_KEY: str = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9"

warnings.filterwarnings("ignore", category=InsecureRequestWarning)

def send_cmd(url: str, cmd: str) -> Dict:
    data = {"secret_key": SECRET_KEY,
            "command": cmd}

    try:
        response = requests.post(url, json=data, verify=False)
        response_data = response.json()
    except (requests.ConnectionError, requests.exceptions.MissingSchema,
            requests.exceptions.InvalidURL):
        raise requests.exceptions.InvalidURL
    except JSONDecodeError:
        raise Exception("Error: Response has malformed json")

    error = response_data.get("error", None)
    if error:
        raise Exception(f"Error: {error}")

    return response_data

def init() -> str:
    initialized: bool = False
    while not initialized:
        url = input("url > ")
        try:
            result = send_cmd(url, "init")
        except requests.exceptions.InvalidURL:
            print("Error: Invalid URL")
            continue

        uuid = result.get("uuid", None)
        if not uuid:
            raise Exception("Error: Invalid response")

        initialized = True

    print(f"Connected to {uuid}")
    print("_______________________________________________________________________________")
    print("")
    return url

def disconnect(url: str):
    result = send_cmd(url, "disconnect")
    print("")
    if result.get("result") == "disconnected":
        print("Disconnected from remote.")
    else:
        print("Disconnected from remote (without acknowledgement).")

def add_cmd(cls, name, help_text):
    def do_cmd(arg):
        result = send_cmd(cls.url, arg)
        print(result)

    do_cmd.__doc__ = help_text
    do_cmd.__name__ = name

    setattr(cls, f"do_{name}", do_cmd)

def run(url: str):
    cmd = Shell()
    cmd.url = url
    add_cmd(cmd, "exit", "Disconnect from remote.")
    cmd.cmdloop()

try:
    url = init()
    run(url)
except EOFError:
    disconnect(url)
    pass
