utils = require('./utils')

inetNtoa = (buf) ->
  buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3]

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
  
  sweep: ->
    utils.debug "sweeping"
    dict = @dict
    keys = Object.keys(dict)
    swept = 0
    for k in keys
      v = dict[k]
      diff = process.hrtime(v[1])
      if diff[0] > @timeout
        swept += 1
        v0 = v[0]
        v0.close()
        delete dict[k]
    utils.debug "#{swept} keys swept"

# +----+------+------+----------+----------+----------+
# |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +----+------+------+----------+----------+----------+
# | 2  |  1   |  1   | Variable |    2     | Variable |
# +----+------+------+----------+----------+----------+

# how to name variables
# dest means destination server, which is from DST fields in the SOCKS5 request
# local means local server of shadowsocks
# remote means remote server of shadowsocks
# client means UDP client, which is used for connecting
# server means UDP server, which is used for listening

exports.createServer = (listenAddr, listenPort, remoteAddr, remotePort, 
                        key, method, timeout, isLocal) ->
  udpTypesToListen = []
  if listenAddr == null
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
      console.error("server got: " + data + " from " + rinfo.address + ":" + rinfo.port)
      frag = data[2]
      utils.debug "frag:#{frag}"
      if frag != 0
        utils.wran "drop a message since frag is not 0"
        return
      addrtype = data[3]
      if addrtype is 3
        addrLen = data[4]
      else unless addrtype in [1, 4]
        utils.error "unsupported addrtype: " + addrtype
        connection.destroy()
        return
      # read address and port
      if addrtype is 1
        destAddr = inetNtoa(data.slice(4, 8))
        destPort = data.readUInt16BE(8)
        headerLength = 10
      else if addrtype is 4
        destAddr = inet.inet_ntop(data.slice(4, 20))
        destPort = data.readUInt16BE(20)
        headerLength = 22
      else
        destAddr = data.slice(5, 5 + addrLen).toString("binary")
        destAddr = data.readUInt16BE(5 + addrLen)
        headerLength = 5 + addrLen + 2
      utils.debug "UDP send to #{destAddr}:#{destPort}"
      
      key = clientKey(rinfo.address, rinfo.port, destAddr, destPort)
      client = clients.getItem(key)
      if not client?
        ipType = net.isIP(destAddr)
        if ipType == 6
          client = dgram.createSocket("udp6")
        else
          client = dgram.createSocket("udp4")
        clients.setItem(key, client)
      
        client.on "message", (data1, rinfo1) ->
          utils.debug "client got #{data1} from #{rinfo1.address}:#{rinfo1.port}"
          data2 = Buffer.concat([data.slice(0, headerLength), data1])
          server.send data2, 0, data2.length, rinfo.port, rinfo.address, (err, bytes) ->
            utils.debug "remote to client sent"
    
        client.on "error", (err) ->
          utils.debug "error: #{err}"
        
        client.on "close", ->
          utils.debug "close"
          clients.delItem(key)
  
      utils.debug "pairs: #{Object.keys(clients.dict).length}"
  
      client.send data, headerLength, data.length - headerLength, destPort, destAddr, (err, bytes) ->
        utils.debug "client to remote sent"
  
    )
    
    server.on("listening", ->
      address = server.address()
      console.error("server listening " + address.address + ":" + address.port)
    ) 
    
    if remoteAddr
      server.bind(listenPort, remoteAddr)
    else
      server.bind(listenPort)
    
    return server