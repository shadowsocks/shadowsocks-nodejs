shadowsocks-nodejs
===========

Current version: 1.4.12
[![Build Status](https://travis-ci.org/clowwindy/shadowsocks-nodejs.png)](https://travis-ci.org/clowwindy/shadowsocks-nodejs)

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

Both TCP CONNECT and UDP ASSOCIATE are implemented.

Other ports and clients can be found [here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).

Usage
-----------

Download the lastest Node stable release. You can find them [here](http://nodejs.org/). Don't just use master branch of
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

`cd` into the directory of `config.json`. Run `ssserver` on your server. To run it in the background, run
`nohup ssserver > log &`.

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
Please visit [issue tracker](https://github.com/clowwindy/shadowsocks-nodejs/issues?state=open)

Mailing list: http://groups.google.com/group/shadowsocks

Also see [troubleshooting](https://github.com/clowwindy/shadowsocks/wiki/Troubleshooting)
