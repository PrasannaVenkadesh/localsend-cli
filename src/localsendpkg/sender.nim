import std/[asyncdispatch, strutils, json, jsonutils, tables, paths, os,
            mimetypes]

# Third party imports
import checksums/md5
import yahttp

#local imports
import protocol
from apiroutes import ApiRoute


type
  ItemType* {.pure.} = enum
    Texts
    Files

  SendingFile = object
    id: string
    absName: string
    relName: string


var mimeDb = newMimetypes()

proc getMimeType(fileName: string): string =
  let fileNamePart = Path(fileName).splitFile
  result = mimeDb.getMimetype(fileNamePart.ext)


proc preparePayload(device: Device, sendingFiles: seq[SendingFile]): PrepareUploadDto =
  var data = initTable[string, FileDto]()
  for sendingFile in sendingFiles:
    let mimeType = getMimeType(sendingFile.absName)
    data[sendingFile.id] = FileDto(
      id: sendingFile.id,
      fileName: sendingFile.relName,
      size: getFileSize(sendingFile.absName),
      fileType: mimeType,
      sha256: "",
      preview: ""
    )
  result = PrepareUploadDto(info: device, files: data)


proc requestUpload(peer: Peer, payload: PrepareUploadDto):
                   Future[JsonNode] {.async.} =

  result = parseJson("{}")
  let endpoint: string = buildFQDN(peer) & $ApiRoute.PrepareUpload

  # NOTE: yahttp is not yet async, this will be a blocking call. But it will be
  # async in future. See https://github.com/mishankov/yahttp/issues/22
  let response = yahttp.post(endpoint, body= $payload.toJson, ignoreSsl=true)
  if response.status == 200:
    result = response.json()


proc upload(peer: Peer, sendingFile: SendingFile, sessionId: string, token: string):
           Future[bool] {.async.} =
  let endpoint = buildFQDN(peer) & $ApiRoute.Upload
  let qParams = {"sessionId": sessionId, "fileId": sendingFile.id, "token": token}
  let fileContent = readFile(sendingFile.absName)
  let response = yahttp.post(endpoint, query=qParams, body=fileContent, ignoreSsl=true)
  case response.status
  of 200, 201, 204:
    result = true
  else:
    result = false


proc sendItems*(peer: Peer, device: Device, values: seq[string],
                itemType: ItemType): Future[bool] {.async.} =
  result = false

  var sendingFiles: seq[SendingFile]
  var payload: PrepareUploadDto

  try:
    case itemType
    of ItemType.Texts:
      # create temporary files for texts
      for idx, value in pairs(values):
        let tempName = os.joinPath("/tmp", getMD5(value) & ".txt")
        let fd = open(tempName, fmWrite)
        fd.write(value)
        fd.close()
        sendingFiles.add(SendingFile(
          id: "file_" & $idx,
          absName: tempName,
          relName: string(Path(tempName).splitPath.tail)
        ))
    of ItemType.Files:
      for idx, value in pairs(values):
        sendingFiles.add(SendingFile(
          id: "file_" & $idx,
          absName: value,
          relName: string(Path(value).splitPath.tail)
        ))

    payload = preparePayload(device, sendingFiles)

    # enable preview if sending one text value
    if itemType == ItemType.Texts:
      if sendingFiles.len == 1:
        payload.files[sendingFiles[0].id].preview = values[0]

    # request the peer if they can accept our upload
    let sessionInfo = await requestUpload(peer, payload)

    # if the peer accepted proceed to upload
    if sessionInfo.len > 0:
      let sessionId = sessionInfo["sessionId"].getStr()

      # TODO: Track which files are uploaded
      for sendingFile in sendingFiles:
        if sendingFile.id in sessionInfo["files"]:
          discard await peer.upload(
            sendingFile = sendingFile,
            sessionId = sessionId,
            token = sessionInfo["files"][sendingFile.id].getStr()
          )
      result = true
  finally:
    # delete temporary files created for texts
    if itemType == ItemType.Texts:
      for sendingFile in sendingFiles:
        if fileExists(sendingFile.absName):
          removeFile(sendingFile.absName)
