child_process = require('child_process')
local = child_process.spawn('node', ['local.js'])
server = child_process.spawn('node', ['server.js'])

local.on 'exit', ->
  server.kill()

server.on 'exit', ->
  local.kill()

localReady = false
serverReady = false
curlRunning = false

runCurl = ->
  curlRunning = true
  curl = child_process.spawn 'curl', ['-v', 'http://www.google.com/', '-L', '--socks5', '127.0.0.1:1080']
  curl.on 'exit', (code)->
    local.kill()
    server.kill()
    if code is 0
      console.log 'Test passed'
      process.exit 0
    else
      console.error 'Test failed'
      process.exit code

  curl.stdout.on 'data', (data) ->
    console.log data.toString()

  curl.stderr.on 'data', (data) ->
    console.warn data.toString()

local.stderr.on 'data', (data) ->
  console.warn data.toString()

server.stderr.on 'data', (data) ->
  console.warn data.toString()

local.stdout.on 'data', (data) ->
  console.log data.toString()
  if data.toString().indexOf 'listening at port'
    localReady = true
    if localReady and serverReady and not curlRunning
      runCurl()

server.stdout.on 'data', (data) ->
  console.log data.toString()
  if data.toString().indexOf 'listening at port'
    serverReady = true
    if localReady and serverReady and not curlRunning
      runCurl()

