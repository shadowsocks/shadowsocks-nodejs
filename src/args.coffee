
exports.version = "shadowsocks-nodejs v0.10.0-dev"
exports.requiredNodeVersion = "0.10.0"

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


exports.compareVersion = (l, r) ->
  # compare two version numbers
  ls = l.split '.'
  rs = r.split '.'
  for i in [0..Math.min(ls.length, rs.length)]
    lp = ls[i]
    rp = rs[i]
    if lp != rp
      return lp - rp
   return ls.length - rs.length

exports.requireVersion = (version) ->
  nodeVersion = process.versions.node
  if exports.compareVersion(nodeVersion, version) < 0
    throw new Error("Node version must >= #{version}")

exports.requireVersion exports.requiredNodeVersion

