import std/
  [asyncnet, asyncdispatch, strutils, terminal, json, jsonutils, tables]

# Third party imports
import yahttp

# local imports
from apiroutes import ApiRoute
from protocol import Device, Peer, `$`, FileType, FileDto, PrepareUploadDto
from scan_service import scan, peers, displayPeerName


proc selectPeer(): Peer =
  var line_number = 0
  while true:
    let keypress = terminal.getch()
    case keypress.ord
    of 3, 13: # Interrupt & Enter
      stdout.eraseLine()
      break
    of 65: # Up Arrow
      if line_number == 0:
        continue
      displayPeerName(peers[line_number])
      terminal.cursorUp(2)
      line_number.dec
      displayPeerName(peers[line_number], true)
      terminal.cursorUp(1)
    of 66: # Down Arrow
      if (line_number+1 == peers.len):
        continue
      displayPeerName(peers[line_number])
      line_number.inc
      displayPeerName(peers[line_number], true)
      terminal.cursorUp(1)
    else:
      discard

  result = peers[line_number]


proc buildFQDN(peer: Peer): string =
  result = peer.protocol & "://" & peer.ip & ":" & $peer.port


proc sendMeta(device: Device, peer: Peer, text: string) =
  let fqdn = buildFQDN(peer)
  let endpoint = fqdn & $ApiRoute.PREPARE_UPLOAD
  let fileData = FileDto(
    id: "999",
    fileName: "doesn't matter",
    size: text.len,
    fileType: $FileType.Text,
    preview: text
  )
  device.announce = false
  let payload = PrepareUploadDto(info: device, files: {"999": fileData}.toTable)
  styledEcho(styleDim, "Sending -> ..")
  try:
    let response = yahttp.post(endpoint, ignoreSsl=true, body = $payload.toJson)
    cursorUp 1
    case response.status
    of 200, 204:
      styledEcho(styleDim, "Sending -> ", resetStyle, fgGreen, "OK")
    else:
      styledEcho(styleDim, "Sending -> ", resetStyle, fgRed, "FAILED")
  except OSError:
    styledEcho(fgRed, "Error: device disconnected?")


proc send*(sock: AsyncSocket, device: Device, text: string, scan_interval: int = 10) {.async.} =
  var peer: Peer;
  await scan(sock, device, scan_interval)
  peer = selectPeer()
  displayPeerName(peer, true)
  sendMeta(device, peer, text)
