import requests
import warnings
from urllib3.connectionpool import InsecureRequestWarning
from json.decoder import JSONDecodeError
import sys
from typing import Dict
import readline
import cmd

SECRET_KEY: str = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9"
INTRO_TEXT: str = "lslsh 0.0.1\nType \"help\" for more information."

warnings.filterwarnings("ignore", category=InsecureRequestWarning)

class Shell(cmd.Cmd):
    prompt = "> "
    url = None

    def get_names(self):
        return dir(self)

    def precmd(self, line):
        if line == "EOF":
            return "exit"
        return line

    def emptyline(self):
        return None

    def send_cmd(self, url: str, cmd: str) -> Dict:
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

    def do_connect(self, url):
        """Connect to given URL."""
        try:
            result = self.send_cmd(url, "init")
        except requests.exceptions.InvalidURL:
            print("Error: Invalid URL")
            return
    
        uuid = result.get("uuid", None)
        if not uuid:
            print("Error: Invalid response")
            return
    
        print(f"Connected to {uuid}")
        print("_______________________________________________________________________________")
        print("")
        self.url = url

    def do_exit(self, arg):
        """Exit the shell."""
        print("")
        if self.url:
            result = self.send_cmd(self.url, "disconnect")
            if result.get("result") == "disconnected":
                print("Disconnected from remote.")
            else:
                print("Disconnected from remote (without acknowledgement).")

        return True
    
    def add_cmd(self, name, help_text):
        def do_cmd(arg):
            result = self.send_cmd(self.url, arg)
            print(result)
    
        do_cmd.__doc__ = help_text
        do_cmd.__name__ = name
    
        setattr(self, f"do_{name}", do_cmd)

def run():
    shell = Shell()
    try:
        shell.cmdloop(INTRO_TEXT)
    except KeyboardInterrupt:
        shell.do_exit(None)

run()
