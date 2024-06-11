# std imports
import std/[terminal]

# local imports
from protocol import Peer


type
  AsciiMoji* {.pure.} = enum
    Happy = "\\(ᵔᵕᵔ)/"
    Shrug = "¯\\_(ツ)_/¯"
    Innocent = "(^‿^)"


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


proc displayOperation*(operation: string, status: string, error: bool=false) =
  let color = (if error: fgRed else: fgGreen)
  styledEcho(styleDim, operation, " -> ", resetStyle, styleBright, color, status)
