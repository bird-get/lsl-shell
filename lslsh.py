#!/bin/python3

import cmd
import readline
import sys
import warnings
from json.decoder import JSONDecodeError
from typing import Dict

import requests
from urllib3.connectionpool import InsecureRequestWarning  # type: ignore

from lib import connect, disconnect, get_available_commands, send_cmd

SECRET_KEY: str = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9"
INTRO_TEXT: str = 'lslsh 0.0.1\nType "help" for more information.'

warnings.filterwarnings("ignore", category=InsecureRequestWarning)


class Shell(cmd.Cmd):
    prompt = "> "
    url = None
    ruler = " "
    doc_header = "Available commands (type help <topic>):"

    def get_names(self):
        return dir(self)

    def precmd(self, line):
        if line == "EOF":
            return "exit"
        return line

    def emptyline(self):
        return None

    def do_connect(self, url):
        """Connect to given URL."""
        if self.url:
            self.do_disconnect(None)

        try:
            uuid = connect(url, SECRET_KEY)
        except requests.exceptions.InvalidURL as e:
            print("Error: Invalid URL")
            return
        except InvalidResponseError as e:
            print(e)
            return

        available_commands = get_available_commands(url, SECRET_KEY)
        for key, value in available_commands.items():
            self.add_cmd(key, value)

        print(f"Connected to {uuid}")
        print(
            "_______________________________________________________________________________"
        )
        print("")
        self.url = url

    def do_exit(self, arg):
        """Exit the shell."""
        print("")
        if self.url:
            self.do_disconnect(None)

        return True

    def do_disconnect(self, arg):
        """Disconnect from remote."""
        if self.url:
            if disconnect(self.url, SECRET_KEY):
                print("Disconnected from remote.")
            else:
                print("Disconnected from remote (without acknowledgement).")

            url = None
        else:
            print("Error: Not connected to remote.")

    def add_cmd(self, name, help_text):
        """Make a new command available within the shell."""

        def do_cmd(arg):
            result = send_cmd(self.url, SECRET_KEY, f"{do_cmd.__name__} {arg}")
            print(result.get("result"))

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
