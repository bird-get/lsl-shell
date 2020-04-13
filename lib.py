from json.decoder import JSONDecodeError
from typing import Dict

import requests


class InvalidResponseError(Exception):
    pass


class ErrorReceived(Exception):
    pass


def send_cmd(url: str, secret_key: str, cmd: str) -> Dict:
    """Send a command to the endpoint and return the response."""
    data = {"secret_key": secret_key, "command": cmd}

    try:
        response = requests.post(url, json=data, verify=False)
        response.raise_for_status()
    except (
        requests.ConnectionError,
        requests.exceptions.MissingSchema,
        requests.exceptions.InvalidURL,
    ):
        raise requests.exceptions.InvalidURL
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 423:
            error_msg = e.response.json().get("error")
            raise ErrorReceived(f"Error: {error_msg}")
        else:
            raise e

    try:
        response_data = response.json()
    except JSONDecodeError:
        raise Exception("Error: Response has malformed json")

    error = response_data.get("error", None)
    if error:
        raise ErrorReceived(f"Error: {error}")

    return response_data


def connect(url: str, secret_key: str) -> str:
    """Connect to the given URL.

    Returns the UUID of the endpoint."""
    uuid = send_cmd(url, secret_key, "connect").get("uuid", None)
    if not uuid:
        raise InvalidResponseError("Error: Remote did not return its UUID")

    return uuid


def disconnect(url: str, secret_key: str) -> bool:
    """Disconnect from the endpoint.

    Returns True if the endpoint responded with an acknlowledgement."""
    try:
        result = send_cmd(url, secret_key, "disconnect").get("result", None)
        if result == "disconnected":
            return True
    except JSONDecodeError:
        pass

    return False


def get_available_commands(url: str, secret_key: str) -> Dict:
    """Get a list of available commands from the endpoint."""
    cmds = send_cmd(url, secret_key, "get_commands").get("available_commands", None)
    if not cmds:
        raise InvalidResponseError("Error: Remote did not return command list")

    return cmds
