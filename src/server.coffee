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


net = require("net")
fs = require("fs")
path = require("path")
udpRelay = require("./udprelay")
utils = require("./utils")
inet = require("./inet")
Encryptor = require("./encrypt").Encryptor

exports.main = ->
  
  console.log(utils.version)
  configFromArgs = utils.parseArgs(true)
  configPath = 'config.json'
  if configFromArgs.config_file
    configPath = configFromArgs.config_file
  if not fs.existsSync(configPath)
    configPath = path.resolve(__dirname, "config.json")
    if not fs.existsSync(configPath)
      configPath = path.resolve(__dirname, "../../config.json")
      if not fs.existsSync(configPath)
        configPath = null
  if configPath
    utils.info 'loading config from ' + configPath
    configContent = fs.readFileSync(configPath)
    try
      config = JSON.parse(configContent)
    catch e
      utils.error('found an error in config.json: ' + e.message)
      process.exit 1
  else
    config = {}
  for k, v of configFromArgs
    config[k] = v
  if config.verbose
    utils.config(utils.DEBUG)
    
  utils.checkConfig config

  timeout = Math.floor(config.timeout * 1000) or 300000
  portPassword = config.port_password
  port = config.server_port
  key = config.password
  METHOD = config.method
  SERVER = config.server
  
  if not (SERVER and (port or portPassword) and key)
    utils.warn 'config.json not found, you have to specify all config in commandline'
    process.exit 1
    
  connections = 0
  
  if portPassword 
    if port or key
      utils.warn 'warning: port_password should not be used with server_port and password. server_port and password will be ignored'
  else
    portPassword = {}
    portPassword[port.toString()] = key
      
    
  for port, key of portPassword
    servers = SERVER
    unless servers instanceof Array
      servers = [servers]
    for a_server_ip in servers
      (->
        # let's use enclosures to seperate scopes of different servers
        PORT = port
        KEY = key
        server_ip = a_server_ip
        utils.info "calculating ciphers for port #{PORT}"
        server = net.createServer((connection) ->
          connections += 1
          encryptor = new Encryptor(KEY, METHOD)
          stage = 0
          headerLength = 0
          remote = null
          cachedPieces = []
          addrLen = 0
          remoteAddr = null
          remotePort = null
          utils.debug "connections: #{connections}"
          
          clean = ->
            utils.debug "clean"
            connections -= 1
            remote = null
            connection = null
            encryptor = null
            utils.debug "connections: #{connections}"
    
          connection.on "data", (data) ->
            utils.log utils.EVERYTHING, "connection on data"
            try
              data = encryptor.decrypt data
            catch e
              utils.error e
              remote.destroy() if remote
              connection.destroy() if connection
              return
            if stage is 5
              connection.pause()  unless remote.write(data)
              return
            if stage is 0
              try
                addrtype = data[0]
                if addrtype is undefined
                  return
                if addrtype is 3
                  addrLen = data[1]
                else unless addrtype in [1, 4]
                  utils.error "unsupported addrtype: " + addrtype + " maybe wrong password"
                  connection.destroy()
                  return
                # read address and port
                if addrtype is 1
                  remoteAddr = utils.inetNtoa(data.slice(1, 5))
                  remotePort = data.readUInt16BE(5)
                  headerLength = 7
                else if addrtype is 4
                  remoteAddr = inet.inet_ntop(data.slice(1, 17))
                  remotePort = data.readUInt16BE(17)
                  headerLength = 19
                else
                  remoteAddr = data.slice(2, 2 + addrLen).toString("binary")
                  remotePort = data.readUInt16BE(2 + addrLen)
                  headerLength = 2 + addrLen + 2
                
                # avoid reading from cache before getting connected
                connection.pause()
                
                # connect remote server
                remote = net.connect(remotePort, remoteAddr, ->
                  utils.info "connecting #{remoteAddr}:#{remotePort}"
                  if not encryptor or not remote or not connection
                    remote.destroy() if remote
                    return
                  i = 0
                  
                  # now we get connected, resume data flow
                  connection.resume()
        
                  while i < cachedPieces.length
                    piece = cachedPieces[i]
                    remote.write piece
                    i++
                  cachedPieces = null # save memory
                   
                  # use a small timeout for connect()
                  remote.setTimeout timeout, ->
                    utils.debug "remote on timeout during connect()"
                    remote.destroy() if remote
                    connection.destroy() if connection
        
                  stage = 5
                  utils.debug "stage = 5"
                )
                remote.on "data", (data) ->
                  utils.log utils.EVERYTHING, "remote on data"
                  if not encryptor
                    remote.destroy() if remote
                    return
                  data = encryptor.encrypt data
                  remote.pause() unless connection.write(data)
        
                remote.on "end", ->
                  utils.debug "remote on end"
                  connection.end() if connection
        
                remote.on "error", (e)->
                  utils.debug "remote on error"
                  utils.error "remote #{remoteAddr}:#{remotePort} error: #{e}"
     
                remote.on "close", (had_error)->
                  utils.debug "remote on close:#{had_error}"
                  if had_error
                    connection.destroy() if connection
                  else
                    connection.end() if connection
        
                remote.on "drain", ->
                  utils.debug "remote on drain"
                  connection.resume() if connection
        
                # use a small timeout for connect()
                remote.setTimeout 15 * 1000, ->
                  utils.debug "remote on timeout during connect()"
                  remote.destroy() if remote
                  connection.destroy() if connection
        
                if data.length > headerLength
                  # make sure no data is lost
                  buf = new Buffer(data.length - headerLength)
                  data.copy buf, 0, headerLength
                  cachedPieces.push buf
                  buf = null
                stage = 4
                utils.debug "stage = 4"
              catch e
                # may encouter index out of range
                utils.error e
                connection.destroy()
                remote.destroy()  if remote
            else cachedPieces.push data  if stage is 4
              # remote server not connected
              # cache received buffers
              # make sure no data is lost
        
          connection.on "end", ->
            utils.debug "connection on end"
            remote.end()  if remote
         
          connection.on "error", (e)->
            utils.debug "connection on error"
            utils.error "local error: #{e}"
    
          connection.on "close", (had_error)->
            utils.debug "connection on close:#{had_error}"
            if had_error
              remote.destroy() if remote
            else
              remote.end() if remote
            clean()
        
          connection.on "drain", ->
            utils.debug "connection on drain"
            remote.resume()  if remote
        
          connection.setTimeout timeout, ->
            utils.debug "connection on timeout"
            remote.destroy()  if remote
            connection.destroy() if connection
        )
        
        server.listen PORT, server_ip, ->
          utils.info "server listening at #{server_ip}:#{PORT} "
        udpRelay.createServer(server_ip, PORT, null, null, key, METHOD, timeout, false)
         
        server.on "error", (e) ->
          if e.code is "EADDRINUSE"
            utils.error "Address in use, aborting"
          else
            utils.error e
          process.stdout.on 'drain', ->
            process.exit 1
      )()

if require.main is module 
  exports.main()
