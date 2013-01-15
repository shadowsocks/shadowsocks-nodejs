# Copyright (c) 2012 clowwindy
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

net = require("net")
fs = require("fs")
path = require("path")
util = require('util')
args = require("./args")
Encryptor = require("./encrypt").Encryptor

console.log(args.version)

inetNtoa = (buf) ->
  buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3]
inetAton = (ipStr) ->
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

configFromArgs = args.parseArgs()
configFile = configFromArgs.config_file or path.resolve(__dirname, "config.json")
configContent = fs.readFileSync(configFile)
config = JSON.parse(configContent)
for k, v of configFromArgs
  config[k] = v
timeout = Math.floor(config.timeout * 1000)
portPassword = config.port_password
port = config.server_port
key = config.password
METHOD = config.method
SERVER = config.server

if portPassword 
  if port or key
    util.log 'warning: port_password should not be used with server_port and password. server_port and password will be ignored'
else
  portPassword = {}
  portPassword[port.toString()] = key
    
  
for port, key of portPassword
  (->
    # let's use enclosures to seperate scopes of different servers
    PORT = port
    KEY = key
#    util.log "calculating ciphers for port #{PORT}"
    
    server = net.createServer((connection) ->
      encryptor = new Encryptor(KEY, METHOD)
      stage = 0
      headerLength = 0
      remote = null
      cachedPieces = []
      addrLen = 0
      remoteAddr = null
      remotePort = null
      connection.on "data", (data) ->
        data = encryptor.decrypt data
        if stage is 5
          connection.pause()  unless remote.write(data)
          return
        if stage is 0
          try
            addrtype = data[0]
            if addrtype is 3
              addrLen = data[1]
            else unless addrtype is 1
              util.log "unsupported addrtype: " + addrtype
              console.log data
              connection.end()
              return
            # read address and port
            if addrtype is 1
              remoteAddr = inetNtoa(data.slice(1, 5))
              remotePort = data.readUInt16BE(5)
              headerLength = 7
            else
              remoteAddr = data.slice(2, 2 + addrLen).toString("binary")
              remotePort = data.readUInt16BE(2 + addrLen)
              headerLength = 2 + addrLen + 2
            # connect remote server
            remote = net.connect(remotePort, remoteAddr, ->
              util.log "connecting #{remoteAddr}:#{remotePort}"
              i = 0
    
              while i < cachedPieces.length
                piece = cachedPieces[i]
                remote.write piece
                i++
              cachedPieces = null # save memory
              stage = 5
            )
            remote.on "data", (data) ->
              data = encryptor.encrypt data
              remote.pause()  unless connection.write(data)
    
            remote.on "end", ->
              connection.end()
    
            remote.on "error", (e)->
              util.log "remote #{remoteAddr}:#{remotePort} error: #{e}"
              connection.destroy()
    
            remote.on "drain", ->
              connection.resume()
    
            remote.setTimeout timeout, ->
              connection.end()
              remote.destroy()
    
            if data.length > headerLength
              # make sure no data is lost
              buf = new Buffer(data.length - headerLength)
              data.copy buf, 0, headerLength
              cachedPieces.push buf
              buf = null
            stage = 4
          catch e
            # may encouter index out of range
            util.log e
            connection.destroy()
            remote.destroy()  if remote
        else cachedPieces.push data  if stage is 4
          # remote server not connected
          # cache received buffers
          # make sure no data is lost
    
      connection.on "end", ->
        remote.destroy()  if remote
    
      connection.on "error", (e)->
        util.log "local error: #{e}"
        remote.destroy()  if remote
    
      connection.on "drain", ->
        remote.resume()  if remote
    
      connection.setTimeout timeout, ->
        remote.destroy()  if remote
        connection.destroy()
    )
    servers = SERVER
    unless servers instanceof Array
      servers = [servers]
    for server_ip in servers
      server.listen PORT, server_ip, ->
        util.log "server listening at #{server_ip}:#{PORT} "
    
    server.on "error", (e) ->
      util.warn "Address in use, aborting"  if e.code is "EADDRINUSE"
      process.exit 1
  )()

