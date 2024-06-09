# std imports
import std/[net, asyncnet, asyncdispatch, oids, os]

# third party imports
import argparse
from sysinfo import getMachineModel

# local imports
from localsendpkg/protocol import Device, DeviceType
from localsendpkg/send_service import send

# constants
const
  defaultAlias: string = "localsend-cli"
  defaultPort: int = 53317;


if isMainModule:
  var
    text: string
    multicastPort: int = defaultPort

  var p = newParser:
    help("{prog} - cli tool to send & receive data with other localsend peers")
    option("-name", default=some(defaultAlias), help="name of this device")
    option("-port", default=some($defaultPort), help="port used for discovery")
    command "send":
      option("-text", help="send a text to device", required=true)
    command "receive":
      flag("-quick-save", help="save instantly")

  let opts = p.parse(os.commandLineParams())

  try:
    if opts.port.len < 4:
      stderr.writeLine("Invalid port number, should be > 1000.")
      quit(1)
    multicastPort = parseInt(opts.port)
  except ValueError:
    stderr.writeLine($opts.port & " is not a port number")
    quit(1)

  try:
    if opts.command == "send":
      text = opts.send.get.text
      if (text == ""):
        stderr.writeLine("no text supplied")
        quit(1)
    elif opts.command == "receive":
      echo("Not implemented yet")
      quit(1)
    else:
      echo p.help
      quit(1)
  except ShortCircuit as err:
    if err.flag == "argparse_help":
      echo err.help
      quit(1)
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

  let fingerprint = genOid()

  var device = Device(
    alias: opts.name,
    version: "2.0",
    deviceModel: getMachineModel(),
    deviceType: $DeviceType.Cli,
    fingerprint: $fingerprint,
    port: multicastPort,
    protocol: "http",
    download: false,
    announce: true
  )

  let peer_sock = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  peer_sock.setSockOpt(OptReuseAddr, true);
  peer_sock.bindAddr(multicastPort.Port, "");

  waitFor send(peerSock, device, text);
