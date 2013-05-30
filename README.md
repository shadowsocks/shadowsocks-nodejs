shadowsocks-nodejs
===========

Current version: 1.2.2
[![Build Status](https://travis-ci.org/clowwindy/shadowsocks-nodejs.png)](https://travis-ci.org/clowwindy/shadowsocks-nodejs)

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

The protocol is compatible with the origin shadowsocks(if both have been upgraded to the
 latest version). For example, you can use a python client with a nodejs server.

Other ports and clients can be found [here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).

Usage
-----------

Download the lastest Node stable release. You can find them [here](http://nodejs.org/). Don't just use master branch of
Node source code from Github! It's not stable.

    wget http://nodejs.org/dist/v0.8.22/node-v0.8.22.tar.gz
    tar xf node-v0.8.22.tar.gz
    cd node-v0.8.22/
    ./configure
    make -j2 && sudo make install

Clone the repo:

    git clone git://github.com/clowwindy/shadowsocks-nodejs.git
    cd shadowsocks-nodejs

Edit `config.json`, change the following values:

    server          your server IP (IPv4/IPv6), notice that your server will listen to this IP
    server_port     server port
    local_port      local port
    password        a password used to encrypt transfer
    timeout         in seconds
    method          encryption method, "bf-cfb", "aes-256-cfb", "des-cfb", "rc4", etc. Default is table

Run `node server.js` on your server. To run it in the background, run
`nohup node server.js > log &`.

On your client machine, run `node local.js`.

Change the proxy setting in your browser into

    protocol: socks5
    hostname: 127.0.0.1
    port:     your local_port

Advanced
------------

You can use args to override settings from `config.json`.

    node local.js -s server_name -p server_port -l local_port -k password -m bf-cfb
    node server.js -p server_port -k password -m bf-cfb

Example of multi-user server support can be found in `test/config-multi-passwd.json`.

Developing
-----------------------------

You can build coffee source code and test it:

    npm install -g coffee-script
    cake build test


Issue with Node v0.10
-----------------------------
Node v0.10 moved to new Readable Stream API. Though it's almost backward compatible, its early versions may have
introduced a bug, resulting in memory leaks.

I'm working on a [node v0.10 branch](https://github.com/clowwindy/shadowsocks-nodejs/tree/node-v0.10), if you have
CPU 100% problem with node v0.10, you can try this branch if you like.

If you have any ideas about this, please file an issue.

License
-----------------
MIT
