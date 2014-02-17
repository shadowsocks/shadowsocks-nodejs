# Copyright (c) 2013 clowwindy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

exports.version = "shadowsocks-nodejs v1.4.3"

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
    exports.debug(JSON.stringify(process.memoryUsage(), ' ', 2))
    exports.debug 'GC'
    gc()
    exports.debug(JSON.stringify(process.memoryUsage(), ' ', 2))
    cwd = process.cwd()
    if _logging_level == exports.DEBUG
      try
        heapdump = require 'heapdump'
        process.chdir '/tmp'
#        heapdump.writeSnapshot()
        process.chdir cwd
      catch e
        exports.debug e
, 1000)
