{print} = require 'util'
{spawn} = require 'child_process'

build = () ->
  os = require 'os'
  if os.platform() == 'win32'
    coffeeCmd = 'coffee.cmd'
  else
    coffeeCmd = 'coffee'
  coffee = spawn coffeeCmd, ['-c', '-o', 'lib/shadowsocks', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    if code != 0
      process.exit code

test = () ->
  os = require 'os'
  coffee = spawn 'node', ['lib/shadowsocks/test.js']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    if code != 0
      process.exit code

task 'build', 'Build ./ from src/', ->
  build()

task 'test', 'Run unit test', ->
  test()

