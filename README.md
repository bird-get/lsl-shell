# lsl-shell
`lsl-shell` provides a simple Python-based shell for interacting with
in-world API endpoints.

**Note**: This project is still in an early development stage. Communication
protocols will likely change.

## Getting started
1. Clone the repository
2. Copy the `endpoint.lsl` script contents and paste it in an in-world script
3. Add the script to a prim
4. Copy the emitted URL
5. Run `python lslsh.py`
6. Enter the URL: `connect https://sim[...].agni.lindenlab.com:12043/cap/[...]`
7. Type `help` for a list of available commands

## Use cases
#### Interacting with other scripts
You can directly interact with other scripts inside the endpoint object.
This primarily happens via link messages. Responses from the scripts
are returned to the shell.

#### Rapid script development
You can save a script and directly communicate with it through the endpoint.
For example, you can work on a mathematical function and receive its output
straight in your terminal.

#### Administrative tasks
For example:
- Kicking and banning avatars
- Retrieving sim usage statistics (which you can then easily process locally)
- Remotely sending sim-wide messages

#### HTTP proxy
It's possible to use the endpoint as a HTTP proxy to visit websites or to
make HTTP calls to other in-world objects.
