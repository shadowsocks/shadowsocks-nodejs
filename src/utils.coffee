
util = require 'util'

exports.parseArgs = ->
  defination =
    '-l': 'local_port'
    '-p': 'server_port'
    '-s': 'server'
    '-k': 'password',
    '-c': 'config_file',
    '-m': 'method'

  result = {}
  nextIsValue = false
  lastKey = null
  for _, oneArg of process.argv
    if nextIsValue
      result[lastKey] = oneArg
      nextIsValue = false
    else if oneArg of defination
      lastKey = defination[oneArg]
      nextIsValue = true
    else if '-v' == oneArg
      result['verbose'] = true
  result

exports.checkConfig = (config) ->
  if config.server in ['127.0.0.1', 'localhost']
    exports.warn "Server is set to #{config.server}, maybe it's not correct"
    exports.warn "Notice server will listen at #{config.server}:#{config.server_port}"
  if (config.method or '').toLowerCase() == 'rc4'
    exports.warn 'RC4 is not safe; please use a safer cipher, like AES-256-CFB'

exports.version = "shadowsocks-nodejs v1.3.7"

exports.EVERYTHING = 0
exports.DEBUG = 1
exports.INFO = 2
exports.WARN = 3
exports.ERROR = 4

_logging_level = exports.INFO

exports.config = (level) ->
  _logging_level = level

exports.log = (level, msg)->
  if level >= _logging_level
    util.log msg
    
exports.debug = (msg)->
  exports.log exports.DEBUG, msg
  
exports.info = (msg)->
  exports.log exports.INFO, msg 
  
exports.warn = (msg)->
  exports.log exports.WARN, msg 
  
exports.error = (msg)->
  exports.log exports.ERROR, msg

setInterval(->
  if global.gc
    exports.debug 'GC'
    gc()
, 30000)
