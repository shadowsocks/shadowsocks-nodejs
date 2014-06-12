###
  Copyright (c) 2014 clowwindy
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
###


util = require 'util'
pack = require '../../package.json'

printLocalHelp = ->
    console.log """
                usage: sslocal [-h] -s SERVER_ADDR -p SERVER_PORT [-b LOCAL_ADDR] -l LOCAL_PORT -k PASSWORD -m METHOD [-t TIMEOUT] [-c config]
                
                optional arguments:
                  -h, --help            show this help message and exit
                  -s SERVER_ADDR        server address
                  -p SERVER_PORT        server port
                  -b LOCAL_ADDR         local binding address, default is 127.0.0.1
                  -l LOCAL_PORT         local port
                  -k PASSWORD           password
                  -m METHOD             encryption method, for example, aes-256-cfb
                  -t TIMEOUT            timeout in seconds
                  -c CONFIG             path to config file
                """

printServerHelp = ->
    console.log """
                usage: ssserver [-h] -s SERVER_ADDR -p SERVER_PORT -k PASSWORD -m METHOD [-t TIMEOUT] [-c config]
                
                optional arguments:
                  -h, --help            show this help message and exit
                  -s SERVER_ADDR        server address
                  -p SERVER_PORT        server port
                  -k PASSWORD           password
                  -m METHOD             encryption method, for example, aes-256-cfb
                  -t TIMEOUT            timeout in seconds
                  -c CONFIG             path to config file
                """

exports.parseArgs = (isServer=false)->
  defination =
    '-l': 'local_port'
    '-p': 'server_port'
    '-s': 'server'
    '-k': 'password',
    '-c': 'config_file',
    '-m': 'method',
    '-b': 'local_address',
    '-t': 'timeout'

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
    else if oneArg.indexOf('-') == 0
      if isServer
        printServerHelp()
      else
        printLocalHelp()
      process.exit 2
  result

exports.checkConfig = (config) ->
  if config.server in ['127.0.0.1', 'localhost']
    exports.warn "Server is set to #{config.server}, maybe it's not correct"
    exports.warn "Notice server will listen at #{config.server}:#{config.server_port}"
  if (config.method or '').toLowerCase() == 'rc4'
    exports.warn 'RC4 is not safe; please use a safer cipher, like AES-256-CFB'

exports.version = "#{pack.name} v#{pack.version}"

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
    if level >= exports.DEBUG
      util.log(new Date().getMilliseconds() + 'ms ' + msg)
    else
      util.log msg
    
exports.debug = (msg)->
  exports.log exports.DEBUG, msg
  
exports.info = (msg)->
  exports.log exports.INFO, msg 
  
exports.warn = (msg)->
  exports.log exports.WARN, msg 
  
exports.error = (msg)->
  exports.log exports.ERROR, msg?.stack or msg

exports.inetNtoa = (buf) ->
  buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3]
  
exports.inetAton = (ipStr) ->
  parts = ipStr.split(".")
  unless parts.length is 4
    null
  else
    buf = new Buffer(4)
    i = 0
    while i < 4
      buf[i] = +parts[i]
      i++
    buf

setInterval(->
  if _logging_level <= exports.DEBUG
    exports.debug(JSON.stringify(process.memoryUsage(), ' ', 2))
    if global.gc
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
