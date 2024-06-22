# std imports
import std/[net, asyncnet, asyncdispatch, oids, os]

# third party imports
import argparse
from sysinfo import getMachineModel

# local imports
from localsendpkg/protocol import Device, DeviceType
from localsendpkg/sender import ItemType
from localsendpkg/send_service import send

# constants
const
  defaultAlias: string = "localsend-cli"
  defaultPort: int = 53317;


if isMainModule:
  let
    fingerprint = genOid()
    peer_sock = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  var
    items: seq[string]
    multicastPort: int = defaultPort

  var p = newParser:
    help("{prog} - cli tool to send & receive data with other localsend peers")
    option("-name", default=some(defaultAlias), help="name of this device")
    option("-port", default=some($defaultPort), help="port used for discovery")
    command("send"):
      arg("kind", help="Possible values: [text, file]")
      arg("values", help="items to send", nargs = -1)
    command("receive"):
      flag("--quick-save", help="save without any prompts")

  let opts = p.parse(os.commandLineParams())

  try:
    if opts.port.len < 4:
      stderr.writeLine("Invalid port number, should be > 1000.")
      quit(1)
    multicastPort = parseInt(opts.port)
  except ValueError:
    stderr.writeLine($opts.port & " is not a port number")
    quit(1)

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

  peer_sock.setSockOpt(OptReuseAddr, true);
  peer_sock.bindAddr(multicastPort.Port, "");

  try:
    if opts.send.isSome:
      case opts.send.get.kind
      of "text":
        case len(opts.send.get.values)
        of 0:
          stderr.writeLine("Nothing to Send !!!")
          quit(1)
        else:
          waitFor peer_sock.send(
            device, opts.send.get.values, itemType=ItemType.Texts
          )

      of "file":
        case len(opts.send.get.values)
        of 0:
          stderr.writeLine("Nothing to send !!!")
          quit(1)
        else:
          waitFor peer_sock.send(
            device, opts.send.get.values, itemType=ItemType.Files
          )

      else:
        stderr.writeLine opts.send.get.kind & " is not a supported kind."
        echo p.help
        quit(1)

    elif opts.receive.isSome:
      stderr.writeLine("Not Implemented Yet !!!")
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
