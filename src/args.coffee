
exports.parseArgs = ->
  defination =
    '-l': 'local_port'
    '-p': 'server_port'
    '-s': 'server'
    '-k': 'password'

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

