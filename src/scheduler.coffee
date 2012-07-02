
class Scheduler
  constructor: (servers) ->
    if servers instanceof Array
      this._servers = servers
    else
      this._servers = [servers]

  _servers: []
  _failureCount: {}
  _successCount: {}
  _ping: {}

  toString: ->
    "[" + this._servers.join(',') + "]"

  _increaseCounter: (counter, key) ->
    if key of counter
      counter[key]++
    else
      counter[key] = 1

  serverFailed: (server) ->
    console.log "#{server} failed"
    this._increaseCounter(this._failureCount, server)

  serverSucceeded: (server) ->
    console.log "#{server} succeeded"
    this._increaseCounter(this._successCount, server)

  updatePing: (server, ping)->
    if server of _ping
      _ping[server] = ping
    else
      _ping[server] = (_ping[server] * 0.8 + ping * 0.2)

  getServer: ->
    this._servers[Math.floor(Math.random() * this._servers.length)]

exports.Scheduler = Scheduler