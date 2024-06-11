import std/[json, jsonutils, strutils, tables]

type
  DeviceType* {.pure.} = enum
    Web = "web"
    Cli = "headless"
    Server = "server"
    Mobile = "mobile"
    Desktop = "desktop"

  FileType* {.pure.} = enum
    Text = "text/plain"
    Image = "image"
    Video = "video"
    Pdf = "pdf"
    Apk = "apk"
    Other = "other"

type
  Device* = ref object of RootObj
    alias*: string
    version*: string
    deviceModel*: string
    deviceType*: string
    fingerprint*: string
    port*: int
    protocol*: string
    download*: bool
    announce*: bool
    announcement*: bool

  Peer* = ref object of Device
    ip*: string

  FileDto* = ref object
    id*: string
    fileName*: string
    size*: int
    fileType*: string
    sha256*: string
    preview*: string

  PrepareUploadDto* = ref object
    info*: Device
    files*: Table[string, FileDto]


proc `==`*(x, y: Peer): bool =
  x.fingerprint == y.fingerprint


proc `$`*(x: Peer): string =
  result = x.alias & " [" & x.deviceModel & "]"


proc parsePeer*(data: string, peer_ip: string = ""): Peer =
  result = Peer()
  var peer_json = parse_json(data);
  let dev_type = parse_enum[DeviceType](peer_json["deviceType"].str);
  peer_json["ip"] = %peer_ip
  peer_json["deviceType"] = %dev_type
  fromJson(result, peer_json)


proc buildFQDN*(peer: Peer): string =
  result = peer.protocol & "://" & peer.ip & ":" & $peer.port
