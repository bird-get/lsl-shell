#!/bin/python3

import cmd
import readline
import sys
import warnings
from json.decoder import JSONDecodeError
from typing import Dict, List

import requests
from urllib3.connectionpool import InsecureRequestWarning  # type: ignore

from lib import (
    ErrorReceived,
    InvalidResponseError,
    SessionLockedError,
    UnauthorizedError,
    connect,
    disconnect,
    get_available_commands,
    send_cmd,
)

SECRET_KEY: str = "29731e5170353a8b235098c43cd2099a4e805c55fb4395890e81f437c17334a9"
INTRO_TEXT: str = 'lslsh 0.0.1\nType "help" for more information.'

warnings.filterwarnings("ignore", category=InsecureRequestWarning)


class Shell(cmd.Cmd):
    prompt = "> "
    url = None
    ruler = " "
    doc_header = "Available built-in commands (type help <topic>):"
    undoc_header = "Undocumented built-in commands:"
    doc_remote_header = "Available endpoint commands (type help <topic>):"
    undoc_remote_header = "Undocumented endpoint commands:"
    remote_commands: List[str] = []

    def get_names(self):
        return dir(self)

    def precmd(self, line):
        if line == "EOF":
            print()
            return "disconnect" if self.url else "exit"

        return line

    def emptyline(self):
        return None

    def _send_cmd(self, command: str) -> str:
        if not self.url:
            return "Error: Not connected to an endpoint."

        try:
            result = send_cmd(self.url, SECRET_KEY, command).get("result")
        except TimeoutError as e:
            return str(e)

        return result

    def do_connect(self, url):
        """Connect to given URL."""
        if self.url:
            self.do_disconnect(None)

        try:
            uuid = connect(url, SECRET_KEY)
        except requests.exceptions.InvalidURL as e:
            print("Error: Invalid URL")
            return
        except (
            InvalidResponseError,
            ErrorReceived,
            UnauthorizedError,
            SessionLockedError,
        ) as e:
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

            self.url = None
            for cmd in self.remote_commands:
                self.remove_cmd(cmd)
        else:
            print("Error: Not connected to remote.")

    def add_cmd(self, name, help_text):
        """Make a new command available within the shell."""

        def do_cmd(arg):
            print(self._send_cmd(f"{do_cmd.__name__} {arg}"))

        do_cmd.__doc__ = help_text
        do_cmd.__name__ = name

        setattr(self, f"do_{name}", do_cmd)
        self.remote_commands.append(name)

    def remove_cmd(self, name):
        """Remove a command from the shell."""

        if not hasattr(Shell, f"do_{name}") and hasattr(self, f"do_{name}"):
            delattr(self, f"do_{name}")
            filter(lambda a: a != name, self.remote_commands)

    def do_help(self, arg):
        """List available commands with "help" or detailed help with "help cmd"."""
        if arg:
            try:
                func = getattr(self, "help_" + arg)
            except AttributeError:
                try:
                    doc = getattr(self, "do_" + arg).__doc__
                    if doc:
                        self.stdout.write("%s\n" % str(doc))
                        return
                except AttributeError:
                    pass
                self.stdout.write("%s\n" % str(self.nohelp % (arg,)))
                return
            func()
        else:
            names = self.get_names()
            cmds_doc = []
            cmds_undoc = []
            cmds_doc_remote = []
            cmds_undoc_remote = []
            help = {}
            for name in names:
                if name[:5] == "help_":
                    help[name[5:]] = 1

            names.sort()
            # There can be duplicates if routines overridden
            prevname = ""
            for name in names:
                if name[:3] == "do_":
                    if name == prevname:
                        continue
                    prevname = name
                    cmd = name[3:]
                    if cmd in self.remote_commands:
                        if cmd in help:
                            cmds_undoc_remote.append(cmd)
                        else:
                            cmds_doc_remote.append(cmd)
                    elif cmd in help:
                        cmds_doc.append(cmd)
                        del help[cmd]
                    elif getattr(self, name).__doc__:
                        cmds_doc.append(cmd)
                    else:
                        cmds_undoc.append(cmd)

            self.stdout.write("%s\n" % str(self.doc_leader))
            self.print_topics(self.doc_header, cmds_doc, 15, 80)
            self.print_topics(self.doc_remote_header, cmds_doc_remote, 15, 80)
            self.print_topics(self.misc_header, list(help.keys()), 15, 80)
            self.print_topics(self.undoc_header, cmds_undoc, 15, 80)
            self.print_topics(self.undoc_remote_header, cmds_undoc_remote, 15, 80)


def run():
    shell = Shell()
    try:
        shell.cmdloop(INTRO_TEXT)
    except KeyboardInterrupt:
        shell.do_exit(None)
    except Exception:
        # Attempt to disconnect so the session immediately becomes available again
        try:
            shell.do_disconnect()
        except Exception:
            pass

        raise


run()
