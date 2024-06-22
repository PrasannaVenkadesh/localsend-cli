import std/[asyncnet, asyncdispatch, os, strutils, terminal]

# local imports
from protocol import Device, Peer, `$`, FileType, FileDto, PrepareUploadDto
from scanner import advertise, scan
from status import Transfer
from sender import ItemType, sendItems

from cli_utils import AsciiMoji, displayPeerName, displayOperation


proc selectPeer(peers: seq[Peer]): Peer =
  # list discoverd peers
  for idx in 0..peers.len() - 1:
    if idx == 0:
      displayPeerName(peers[idx], true)
    else:
      displayPeerName(peers[idx])

  cursorUp peers.len

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
  return peers[line_number]


proc displayProgress(msg: string, timeout_s: int) {.async.} =
  var remaining: int = timeout_s
  for i in 0..timeout_s:
    echo(msg, $remaining)
    await sleepAsync(1000)
    cursorUp 1
    eraseLine
    remaining.dec


proc send*(sock: AsyncSocket, device: Device, values: seq[string],
           scan_interval: int = 10, itemType: ItemType) {.async.} =

  if itemType == ItemType.Files:
    for fileName in values:
      if not fileExists(fileName):
        stderr.writeLine("File not found: " & fileName)
        quit(1)
  try:
    await advertise(sock, device)
    displayOperation("Advertise", $Transfer.OK)
  except OSError:
    displayOperation("Advertise", $Transfer.FAIL, error=true)

  let
    progressTask = displayProgress(
      $AsciiMoji.Innocent & " scanning for peers -> ", scan_interval
    )
    scanTask = sock.scan(device, scan_interval)

  waitFor progressTask and scanTask

  if scanTask.finished:
    let peers: seq[Peer] = scanTask.read()

    eraseLine
    if peers.len > 0:
      styledEcho(bgYellow, styleBright, $AsciiMoji.Happy, " Nearby Peers -> ",
                 $peers.len)
      # prompt user to select a peer from list 
      let peer: Peer = peers.selectPeer()

      displayPeerName(peer, true)
      displayOperation("Sending", $Transfer.PROGRESS)

      let sent: bool = await peer.sendItems(device, values, itemType)
      
      cursorUp 1
      eraseLine
      if sent:
        displayOperation("Sending", $Transfer.OK)
      else:
        displayOperation("Sending", $Transfer.FAIL, error=true)

    else:
      styledEcho(bgRed, styleBright, $AsciiMoji.Shrug, " No peers found!")
