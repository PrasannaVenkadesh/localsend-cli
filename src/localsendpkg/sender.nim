import std/[asyncdispatch, strutils, json, jsonutils, tables]

# Third party imports
import yahttp

#local imports
import protocol
from apiroutes import ApiRoute


proc sendText*(peer: Peer, device: Device, text: string):
               Future[bool] {.async.} =
  let endpoint: string = buildFQDN(peer) & $ApiRoute.PrepareUpload
  let fileID: string = "999"
  let data = FileDto(
    id: fileID,
    fileName: "does not matter",
    size: text.len,
    fileType: $FileType.Text,
    preview: text
  )
  let payload = PrepareUploadDto(
    info: device,
    files: toTable({fileID: data})
  )
  # NOTE: yahttp is not yet async, this will be a blocking call. But it will be
  # async in future. See https://github.com/mishankov/yahttp/issues/22
  let response = yahttp.post(endpoint, ignoreSsl = true, body= $payload.toJson)
  case response.status
  of 200, 204:
    return true
  else:
    return false
