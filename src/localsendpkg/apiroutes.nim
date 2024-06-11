const ApiVersion = "v2"
const ApiBase = "/api/localsend/" & ApiVersion

type
  ApiRoute* {.pure.} = enum
    Info = ApiBase & "/info"
    Register = ApiBase & "/register"
    PrepareUpload = ApiBase & "/prepare-upload"
    PrepareDownload = ApiBase & "/prepare-download"
    Upload = ApiBase & "/upload"
    Download = ApiBase & "/download"
    Cancel = ApiBase & "/cancel"
