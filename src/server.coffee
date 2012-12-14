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
encrypt = require("./encrypt")

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

configFromArgs = require('./args').parseArgs()
configFile = configFromArgs.config_file or path.resolve(__dirname, "config.json")
configContent = fs.readFileSync(configFile)
config = JSON.parse(configContent)
for k, v of configFromArgs
  config[k] = v
timeout = Math.floor(config.timeout * 1000)
portPassword = config.port_password
port = config.server_port
key = config.password

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
    util.log "calculating ciphers for port #{PORT}"
    tables = encrypt.getTable(KEY)
    encryptTable = tables[0]
    decryptTable = tables[1]
    
    server = net.createServer((connection) ->
      util.log "server connected"
      util.log "concurrent connections: " + server.connections
      stage = 0
      headerLength = 0
      remote = null
      cachedPieces = []
      addrLen = 0
      remoteAddr = null
      remotePort = null
      connection.on "data", (data) ->
        encrypt.encrypt decryptTable, data
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
            util.log remoteAddr
            # connect remote server
            remote = net.connect(remotePort, remoteAddr, ->
              util.log "connecting " + remoteAddr
              i = 0
    
              while i < cachedPieces.length
                piece = cachedPieces[i]
                remote.write piece
                i++
              cachedPieces = null # save memory
              stage = 5
            )
            remote.on "data", (data) ->
              encrypt.encrypt encryptTable, data
              remote.pause()  unless connection.write(data)
    
            remote.on "end", ->
              util.log "remote disconnected"
              util.log "concurrent connections: " + server.connections
              connection.end()
    
            remote.on "error", ->
              if stage is 4
                util.warn "remote connection refused"
                connection.end()
                return
              util.log "remote error"
              connection.end()
              util.log "concurrent connections: " + server.connections
    
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
        util.log "server disconnected"
        remote.destroy()  if remote
        util.log "concurrent connections: " + server.connections
    
      connection.on "error", ->
        util.log "server error"
        remote.destroy()  if remote
        util.log "concurrent connections: " + server.connections
    
      connection.on "drain", ->
        remote.resume()  if remote
    
      connection.setTimeout timeout, ->
        remote.destroy()  if remote
        connection.destroy()
    )
    server.listen PORT, ->
      util.log "server listening at port " + PORT
    
    server.on "error", (e) ->
      util.warn "Address in use, aborting"  if e.code is "EADDRINUSE"
  )()

