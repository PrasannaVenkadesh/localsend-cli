# Package

version       = "0.3.0"
author        = "Prasanna Venkadesh"
description   = "cli tool to send & receive data with other localsend devices"
license       = "GPL-3.0-or-later"
srcDir        = "src"
installExt    = @["nim"]
binDir        = "bin"
bin           = @["localsend=localsend-cli"]

# Dependencies

requires "nim >= 2.0.4"
requires "argparse == 4.0.1"
requires "multicast#0b374fb"
requires "sysinfo#ebbf985"
requires "yahttp == 0.11.0"
requires "checksums == 0.1.0"
