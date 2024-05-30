const API_VERSION = "v2"
const API_BASE = "/api/localsend/" & API_VERSION

type
  ApiRoute* = enum
    INFO = API_BASE & "/info"
    REGISTER = API_BASE & "/register"
    PREPARE_UPLOAD = API_BASE & "/prepare-upload"
    PREPARE_DOWNLOAD = API_BASE & "/prepare-download"
    UPLOAD = API_BASE & "/upload"
    DOWNLOAD = API_BASE & "/download"
    CANCEL = API_BASE & "/cancel"
