# std packages
import std/[net, asyncnet, asyncdispatch, json, jsonutils]

# Third party packages
import multicast

# local imports
import protocol

const
  MulticastGroup = "224.0.0.167"
  MulticastPort = 53317

var peers: seq[Peer];


proc advertise*(sock: AsyncSocket, device: Device) {.async.} =
  await sock.sendTo($MulticastGroup, MulticastPort.Port, $device.toJson)


proc recvMsg(sock: AsyncSocket) {.async.} =
  const buffer = 10240;
  var packet = await sock.recv_from(buffer)
  var new_peer: Peer = protocol.parsePeer(packet.data, packet.address);
  if new_peer notin peers:
    peers.add(new_peer)


proc scan*(sock: AsyncSocket, device: Device, scan_duration_s: int = 10):
           Future[seq[Peer]] {.async.} =
  peers = newSeq[Peer]();

  if not sock.join_group(MulticastGroup):
    echo("could not join Multicast Group");
    quit();

  let scan_duration_ms = scan_duration_s * 1000; # convert sec to millisec
  var time_elapsed_ms: int = 0; # millisec
  let sleep_for_ms: int = 500;

  while (time_elapsed_ms < scan_duration_ms):
    asyncCheck recvMsg(sock);
    await sleepAsync(sleep_for_ms);
    time_elapsed_ms += sleep_for_ms;

  assert sock.leave_group(MulticastGroup) == true;
  return peers
