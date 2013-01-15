shadowsocks-nodejs
===========

[![Build Status](https://travis-ci.org/clowwindy/shadowsocks-nodejs.png)](https://travis-ci.org/clowwindy/shadowsocks-nodejs)  
Current version: 0.9.6

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

The protocol is compatible with the origin shadowsocks(if both have been upgraded to the
 latest version). For example, you can use a python client with a nodejs server.

Other ports and clients can be found [here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).

usage
-----------

Edit `config.json`, change the following values:

    server          your server IP (IPv4/IPv6), notice that your server will listen to this IP
    server_port     server port
    local_port      local port
    password        a password used to encrypt transfer
    timeout         in seconds
    method          encryption method, null by default, or use "rc4"

Put all the files on your server.  Run `node server.js` on your server. To run it in the background, run
`nohup node server.js > log &`.

Put all the files on your client machine. Run `node local.js` on your client machine.

Change proxy settings of your browser into

    SOCKS5 127.0.0.1:local_port

advanced
------------

You can use args to override settings from `config.json`.

    node local.js -s server_name -p server_port -l local_port -k password -m rc4
    node server.js -p server_port -k password -m rc4

Example of multi-user server support can be found in `test/config-multi-passwd.json`.

