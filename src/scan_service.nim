# std packages
import std/[net, asyncnet, asyncdispatch, terminal, json, jsonutils]

# Third party packages
import multicast

# local imports
import protocol

const
  MCAST_GROUP = "224.0.0.167"
  MCAST_PORT = 53317
var peers*: seq[Peer];


proc advertise*(sock: AsyncSocket, device: Device) {.async.} =
  await sock.send_to($MCAST_GROUP, MCAST_PORT.Port, $device.toJson);
  styledEcho(styleDim, "Advertise -> ", resetStyle, fgGreen, "OK")


proc displayPeerName*(peer: Peer, styled: bool = false) =
  if styled:
    stdout.styledWriteLine(
      styleBright, fgGreen, peer.alias, resetStyle,
      " [", fgYellow, peer.deviceModel, "]"
    )
  else:
    stdout.styledWriteLine(
      fgGreen, peer.alias, resetStyle,
      " [", fgYellow, peer.deviceModel, "]"
    )


proc recvMsg(sock: AsyncSocket) {.async.} =
  const buffer = 10240;
  var packet = await sock.recv_from(buffer)
  var new_peer: Peer = protocol.parsePeer(packet.data, packet.address);
  if new_peer notin peers:
    if peers.len == 0:
      displayPeerName(new_peer, true)
    else:
      displayPeerName(new_peer)
    peers.add(new_peer)


proc scan*(sock: AsyncSocket, device: Device, scan_duration_s: int = 10) {.async.} =
  peers = newSeq[Peer]();
  await advertise(sock, device);
  
  if not sock.join_group(MCAST_GROUP):
    echo("could not join Multicast Group");
    quit();

  let scan_duration_ms = scan_duration_s * 1000; # convert seconds to milliseconds
  var time_elapsed_ms: int = 0; # milliseconds
  let sleep_for_ms: int = 500;

  echo("waiting for devices -> ", scan_duration_s, " seconds");
  while (time_elapsed_ms < scan_duration_ms) or (peers.len == 0):
    asyncCheck recvMsg(sock);
    await sleepAsync(sleep_for_ms);
    time_elapsed_ms += sleep_for_ms;

  assert sock.leave_group(MCAST_GROUP) == true;

  terminal.cursorUp(peers.len()+1)
  stdout.eraseLine()
  styledEcho(bgYellow, "Nearby Devices:")
