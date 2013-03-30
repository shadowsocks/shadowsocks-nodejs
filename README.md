shadowsocks-nodejs
===========

Current version: 0.10.0-dev [![Build Status](https://travis-ci.org/clowwindy/shadowsocks-nodejs.png?branch=node-v0.10)](https://travis-ci.org/clowwindy/shadowsocks-nodejs)

**Notice: This branch is for Node v0.10**

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

The protocol is compatible with the origin shadowsocks(if both have been upgraded to the
 latest version). For example, you can use a python client with a nodejs server.

Other ports and clients can be found [here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).

Usage
-----------

Download the lastest Node **v0.10** stable release. 

    wget http://nodejs.org/dist/v0.10.2/node-v0.10.2.tar.gz
    tar xf node-v0.10.2.tar.gz
    cd node-v0.10.2/
    ./configure
    make -j2 && sudo make install

Clone the repo and **switch to node-v0.10 branch**:

    git clone git://github.com/clowwindy/shadowsocks-nodejs.git
    git checkout node-v0.10
    cd shadowsocks-nodejs

Edit `config.json`, change the following values:

    server          your server IP (IPv4/IPv6), notice that your server will listen to this IP
    server_port     server port
    local_port      local port
    password        a password used to encrypt transfer
    timeout         in seconds
    method          encryption method, null by default, or use "rc4"

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

    node local.js -s server_name -p server_port -l local_port -k password -m rc4
    node server.js -p server_port -k password -m rc4

Example of multi-user server support can be found in `test/config-multi-passwd.json`.

What's wrong with Node v0.10?
-----------------------------
Node v0.10 moved to new Readable Stream API. Though it's almost backward compatible, it has introduced a bug, resulting in
memory leaks.

So I decided to create a new node-v0.10 branch, in which only the new API is used.

If you have any ideas about this, please file an issue.
