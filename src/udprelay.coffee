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


utils = require('./utils')
inet = require('./inet')
encryptor = require('./encrypt')

dgram = require 'dgram'
net = require 'net'

class LRUCache
  constructor: (@timeout, sweepInterval) ->
    that = this
    sweepFun = ->
      that.sweep()
    
    @interval = setInterval(sweepFun, sweepInterval)
    @dict = {}
    
  setItem: (key, value) ->
    cur = process.hrtime()
    @dict[key] = [value, cur]
  
  getItem: (key) ->
    v = @dict[key]
    if v
      v[1] = process.hrtime()
      return v[0]
    return null
  
  delItem: (key) ->
    delete @dict[key]

  destroy: ->
    clearInterval @interval
  
  sweep: ->
    utils.debug "sweeping"
    dict = @dict
    keys = Object.keys(dict)
    swept = 0
    for k in keys
      v = dict[k]
      diff = process.hrtime(v[1])
      if diff[0] > @timeout * 0.001
        swept += 1
        v0 = v[0]
        v0.close()
        delete dict[k]
    utils.debug "#{swept} keys swept"

# SOCKS5 UDP Request
# +----+------+------+----------+----------+----------+
# |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +----+------+------+----------+----------+----------+
# | 2  |  1   |  1   | Variable |    2     | Variable |
# +----+------+------+----------+----------+----------+

# SOCKS5 UDP Response
# +----+------+------+----------+----------+----------+
# |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +----+------+------+----------+----------+----------+
# | 2  |  1   |  1   | Variable |    2     | Variable |
# +----+------+------+----------+----------+----------+

# shadowsocks UDP Request (before encrypted)
# +------+----------+----------+----------+
# | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +------+----------+----------+----------+
# |  1   | Variable |    2     | Variable |
# +------+----------+----------+----------+

# shadowsocks UDP Response (before encrypted)
# +------+----------+----------+----------+
# | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +------+----------+----------+----------+
# |  1   | Variable |    2     | Variable |
# +------+----------+----------+----------+

# shadowsocks UDP Request and Response (after encrypted)
# +-------+--------------+
# |   IV  |    PAYLOAD   |
# +-------+--------------+
# | Fixed |   Variable   |
# +-------+--------------+

# HOW TO NAME THINGS
# ------------------
# `dest` means destination server, which is from DST fields in the SOCKS5 request
# `local` means local server of shadowsocks
# `remote` means remote server of shadowsocks
# `client` means UDP client, which is used for connecting, or the client that connects our server
# `server` means UDP server, which is used for listening, or the server for our client to connect

encrypt = (password, method, data) ->
  try
    return encryptor.encryptAll(password, method, 1, data)
  catch e
    utils.error e
    return null
  
decrypt = (password, method, data) ->
  try
    return encryptor.encryptAll(password, method, 0, data)
  catch e
    utils.error e
    return null

parseHeader = (data, requestHeaderOffset) ->
  try
    addrtype = data[requestHeaderOffset]
    if addrtype is 3
      addrLen = data[requestHeaderOffset + 1]
    else unless addrtype in [1, 4]
      utils.warn "unsupported addrtype: " + addrtype
      return null
    if addrtype is 1
      destAddr = utils.inetNtoa(data.slice(requestHeaderOffset + 1, requestHeaderOffset + 5))
      destPort = data.readUInt16BE(requestHeaderOffset + 5)
      headerLength = requestHeaderOffset + 7
    else if addrtype is 4
      destAddr = inet.inet_ntop(data.slice(requestHeaderOffset + 1, requestHeaderOffset + 17))
      destPort = data.readUInt16BE(requestHeaderOffset + 17)
      headerLength = requestHeaderOffset + 19
    else
      destAddr = data.slice(requestHeaderOffset + 2, requestHeaderOffset + 2 + addrLen).toString("binary")
      destPort = data.readUInt16BE(requestHeaderOffset + 2 + addrLen)
      headerLength = requestHeaderOffset + 2 + addrLen + 2
    return [addrtype, destAddr, destPort, headerLength]
  catch e
    utils.error e
    return null
 

exports.createServer = (listenAddr, listenPort, remoteAddr, remotePort, 
                        password, method, timeout, isLocal) ->
  # if listen to ANY, listen to both IPv4 and IPv6
  # or listen to IP family of IP address
  udpTypesToListen = []
  if not listenAddr?
    udpTypesToListen = ['udp4', 'udp6']
  else
    listenIPType = net.isIP(listenAddr)
    if listenIPType == 6
      udpTypesToListen.push 'udp6'
    else
      udpTypesToListen.push 'udp4'
  for udpTypeToListen in udpTypesToListen
    server = dgram.createSocket(udpTypeToListen)
    clients = new LRUCache(timeout, 10 * 1000)
    
    clientKey = (localAddr, localPort, destAddr, destPort) ->
      return "#{localAddr}:#{localPort}:#{destAddr}:#{destPort}"
  
    server.on("message", (data, rinfo) ->
      # Parse request
      requestHeaderOffset = 0
      if isLocal
        requestHeaderOffset = 3
        frag = data[2]
        if frag != 0
          utils.debug "frag:#{frag}"
          utils.warn "drop a message since frag is not 0"
          return
      else
        # on remote, client to server
        data = decrypt(password, method, data)
        if not data?
          # drop
          return
      headerResult = parseHeader(data, requestHeaderOffset)
      if headerResult == null
        # drop
        return
      [addrtype, destAddr, destPort, headerLength] = headerResult
       
      if isLocal
        sendDataOffset = requestHeaderOffset
        [serverAddr, serverPort] = [remoteAddr, remotePort]
      else
        sendDataOffset = headerLength
        [serverAddr, serverPort] = [destAddr, destPort]
      
      key = clientKey(rinfo.address, rinfo.port, destAddr, destPort)
      client = clients.getItem(key)
      if not client?
        # Create IPv6 UDP socket if serverAddr is an IPv6 address
        clientUdpType = net.isIP(serverAddr)
        if clientUdpType == 6
          client = dgram.createSocket("udp6")
        else
          client = dgram.createSocket("udp4")
        clients.setItem(key, client)
      
        client.on "message", (data1, rinfo1) ->
#          utils.debug "client got #{data1} from #{rinfo1.address}:#{rinfo1.port}"
          if not isLocal
            # on remote, server to client
            # append shadowsocks response header
            # TODO: support receive from IPv6 addr
            utils.debug "UDP recv from #{rinfo1.address}:#{rinfo1.port}"
            serverIPBuf = utils.inetAton(rinfo1.address)
            responseHeader = new Buffer(7)
            responseHeader.write('\x01', 0)
            serverIPBuf.copy(responseHeader, 1, 0, 4)
            responseHeader.writeUInt16BE(rinfo1.port, 5)
            data2 = Buffer.concat([responseHeader, data1])
            data2 = encrypt(password, method, data2)
            if not data2?
              # drop
              return
          else
            # on local, server to client
            # append socks5 response header
            responseHeader = new Buffer("\x00\x00\x00")
            data1 = decrypt(password, method, data1)
            if not data1?
              # drop
              return
            headerResult = parseHeader(data1, 0)
            if headerResult == null
              # drop
              return
            [addrtype, destAddr, destPort, headerLength] = headerResult
            utils.debug "UDP recv from #{destAddr}:#{destPort}"
            data2 = Buffer.concat([responseHeader, data1])
          server.send data2, 0, data2.length, rinfo.port, rinfo.address, (err, bytes) ->
            utils.debug "remote to local sent"
    
        client.on "error", (err) ->
          utils.error "UDP client error: #{err}"
        
        client.on "close", ->
          utils.debug "UDP client close"
          clients.delItem(key)
  
      utils.debug "pairs: #{Object.keys(clients.dict).length}"
 
      dataToSend = data.slice(sendDataOffset, data.length)
      if isLocal
        # on local, client to server
        dataToSend = encrypt password, method, dataToSend
        if not dataToSend?
          # drop
          return

      utils.debug "UDP send to #{destAddr}:#{destPort}"
      client.send dataToSend, 0, dataToSend.length, serverPort, serverAddr, (err, bytes) ->
        utils.debug "local to remote sent"
  
    )
    
    server.on "listening", ->
      address = server.address()
      utils.info("UDP server listening " + address.address + ":" + address.port)

    server.on "close", ->
      utils.info "UDP server closing"
      clients.destroy()
    
    if listenAddr?
      server.bind(listenPort, listenAddr)
    else
      server.bind(listenPort)
    
    return server
