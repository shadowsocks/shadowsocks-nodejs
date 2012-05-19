shadowsocks-nodejs
===========

shadowsocks-nodejs is a lightweight tunnel proxy which can help you get through
 firewalls. It is a port of [shadowsocks](https://github.com/clowwindy/shadowsocks).

The protocol is compatible with the origin shadowsocks. For example, you can use a
python client with a nodejs server.

NOTE this project is in an alpha stage. The code may have bugs, such as memory leak.

usage
-----------

Put all the files on your server. Edit `server.js`, change the following values:

    PORT          server port
    KEY           a password to identify clients

Run `node server.js` on your server. To run it in the background, run `setsid node server.js`.

Put `local.js` on your client machine. Edit `local.js`, change these values:

    SERVER        your server ip or hostname
    REMOTE_PORT   server port
    PORT          local port
    KEY           a password, it must be the same as the password of your server

Run `node local.js` on your client machine.

Change proxy settings of your browser into

    SOCKS5 127.0.0.1:PORT

