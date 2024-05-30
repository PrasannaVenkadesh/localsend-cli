# std imports
import std/[net, asyncnet, asyncdispatch, oids, os]

# third party imports
import argparse
from sysinfo import getMachineModel

# local imports
from protocol import Device, DeviceType
from send_service import send

# constants
const MCAST_PORT: int = 53317;


if isMainModule:
  var
    text: string

  var p = newParser:
    help("{prog} - cli tool to send & receive data with other localsend peers")
    command "send":
      option("-text", help="send a text to device", required=true)
    command "receive":
      flag("-quick-save", help="save instantly")

  try:
    let opts = p.parse(os.commandLineParams())
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
    alias: "localsend-cli",
    version: "2.0",
    deviceModel: getMachineModel(),
    deviceType: $DeviceType.CLI,
    fingerprint: $fingerprint,
    port: MCAST_PORT,
    protocol: "http",
    download: false,
    announce: true
  )

  let peer_sock = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  peer_sock.setSockOpt(OptReuseAddr, true);
  peer_sock.bindAddr(MCAST_PORT.Port, "");

  waitFor send(peerSock, device, text);
