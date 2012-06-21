shadowsocks-nodejs
===========

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

The nodejs version has a better performance than the original Python version.

The protocol is compatible with the origin shadowsocks(if both have been upgraded to the
 latest version). For example, you can use a python client with a nodejs server.

usage
-----------

Put all the files on your server. Edit `server.js`, change the following values:

    PORT          server port
    KEY           a password to identify clients

Run `node server.js` on your server. To run it in the background, run `setsid node server.js`.

Put all the files on your client machine. Edit `local.js`, change these values:

    SERVER        your server ip or hostname
    REMOTE_PORT   server port
    PORT          local port
    KEY           a password, it must be the same as the password of your server

Run `node local.js` on your client machine.

Change proxy settings of your browser into

    SOCKS5 127.0.0.1:PORT

