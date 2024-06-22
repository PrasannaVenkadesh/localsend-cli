## [Unreleased]

- Send multiple items in parallel (async)
- Track & Display Sending Progress
- Receive Text
- Recieve Files

## [0.3.0]

### Added

- [cli] Send more than one text to a selected peer.
- [cli] Send file(s) to a selected peer.
- [lib] ItemType Enum in `sender.nim`
- [lib] SendingFile Object in `sender.nim`

### Changed

- [cli] `send` command expects `text` or `file` kind instead of `-text` or `-file` option.
- [lib] `sendText` procedure is replaced with `sentItems` procedure to send both texts and files.

## [0.2.0]

### Added

- `-port` option
- `-name` option

### Changed

- reorganize modules separating library & application code

## [0.1.0]

### Added

- Scan and discover nearby localsend peers.
- Send a text to a selected peer.
