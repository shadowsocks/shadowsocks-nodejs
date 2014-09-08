shadowsocks-nodejs
===========

[![NPM version]][NPM] [![Build Status]][Travis CI]

shadowsocks-nodejs is a node.js port of [shadowsocks].

**Deprecated; please use [Other versions].**

Many people are asking why. Here's why.

- https://github.com/clowwindy/shadowsocks-nodejs/issues/35
- https://github.com/joyent/node/issues/5949

The GC of node.js sucks.

Python version [handles 5000 connections with 50MB RAM](https://github.com/clowwindy/shadowsocks/wiki/Optimizing-Shadowsocks) while node.js version
handles 100 connections with 300MB RAM. Why should we continue to support
node.js?

Usage
-----------

Download the lastest [Node stable] release. Don't just use master branch of
Node source code from Github! It's not stable.

Run
    
    npm install -g shadowsocks

Create a file named `config.json`, with the following content.

    {
        "server":"my_server_ip",
        "server_port":8388,
        "local_port":1080,
        "password":"barfoo!",
        "timeout":600,
        "method":"table",
        "local_address":"127.0.0.1"
    }

Explaination of the fields:

    server          your server IP (IPv4/IPv6), notice that your server will listen to this IP
    server_port     server port
    local_port      local port
    password        a password used to encrypt transfer
    timeout         in seconds
    method          encryption method, "bf-cfb", "aes-256-cfb", "des-cfb", "rc4", etc. Default is table
    local_address   local binding address, leave it alone if you don't know what it means

`cd` into the directory of `config.json`. Run `ssserver` on your server. Use [Supervisor].

On your client machine, run `sslocal`.

Change the proxy setting in your browser into

    protocol: socks5
    hostname: 127.0.0.1
    port:     your local_port

Advanced
------------

You can use args to override settings from `config.json`.

    sslocal -s server_name -p server_port -l local_port -k password -m bf-cfb -b local_address
    ssserver -p server_port -k password -m bf-cfb -t timeout
    ssserver -c /etc/shadowsocks/config.json

Example of multi-user server support can be found in `test/config-multi-passwd.json`.

Developing
-----------------------------

You can build coffee source code and test it:

    npm install -g coffee-script
    cake build test

License
-----------------
MIT

Bugs and Issues
----------------
Please visit [Issue Tracker]

Mailing list: http://groups.google.com/group/shadowsocks

Also see [Troubleshooting]


[Build Status]:    https://img.shields.io/travis/clowwindy/shadowsocks-nodejs/master.svg?style=flat
[Issue Tracker]:   https://github.com/clowwindy/shadowsocks-nodejs/issues?state=open
[Node stable]:     http://nodejs.org/
[NPM]:             https://www.npmjs.org/package/shadowsocks
[NPM version]:     https://img.shields.io/npm/v/shadowsocks.svg?style=flatp
[Travis CI]:       https://travis-ci.org/clowwindy/shadowsocks-nodejs
[shadowsocks]:     https://github.com/clowwindy/shadowsocks
[Supervisor]:      https://github.com/clowwindy/shadowsocks-nodejs/wiki/Configure-Shadowsocks-nodejs-with-Supervisor
[Other versions]:  https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients
[Troubleshooting]: https://github.com/clowwindy/shadowsocks/wiki/Troubleshooting
