
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
  result

exports.version = "shadowsocks-nodejs v1.2.2"

exports.DEBUG = 0
exports.INFO = 1
exports.WARN = 2
exports.ERROR = 3

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
