/*
 Copyright (c) 2012 clowwindy

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

var SERVER = '127.0.0.1';
var REMOTE_PORT = 8388;
var PORT = 8080;
var KEY = 'barfoo!';
var timeout = 30000;

var net = require('net');
var encrypt = require('./encrypt.js');
console.log('calculating ciphers');
var tables = encrypt.getTable(KEY);
var encryptTable = tables[0];
var decryptTable = tables[1];

function inetNtoa(buf) {
    return buf[0] + '.' + buf[1] + '.' + buf[2] + '.' + buf[3];
}

function inetAton(ipStr) {
    var parts = ipStr.split('.');
    if (parts.length != 4) {
        return null;
    } else {
        var buf = new Buffer(4);
        for (var i = 0; i < 4; i++)
            buf[i] = +parts[i];
        return buf;
    }
}

var server = net.createServer(function (connection) { //'connection' listener
    console.log('server connected');
    console.log('concurrent connections: ' + server.connections);

    var stage = 0, headerLength = 0, remote = null, cachedPieces = [],
        addrLen = 0, remoteAddr = null, remotePort = null, addrToSend = '';
    connection.on('data', function (data) {
//        encrypt.encrypt(decryptTable, data);
        if (stage == 5) {
            // pipe sockets
            encrypt.encrypt(encryptTable, data);
            if (!remote.write(data)) {
                connection.pause();
            }
            return;
        }
        if (stage == 0) { // note this must be if, not else if!
            try {
                var request = data.toString('binary').split('\n');
                var requestToSend = '';
                var host = null;
                for (var i = 0; i < request.length - 1; i++) {
                    if (i ==0 ) {
                        var php = request[i].split(' ');
                        if (request[i].indexOf('CONNECT') == 0) {
                            connection.end('HTTP/1.1 405 Method not supported\r\n\r\nMethod not supported');
                            return;
                        }
                    }
                    var kv = request[i].trim().split(': ');
                    if (kv.length == 2) {
                        if (kv[0] == 'Host') {
                            host = kv[1];
                        }
                    }
                    if (kv[0].indexOf('Proxy') != 0 && kv[0].indexOf('Connection') != 0) {
                        requestToSend += request[i] + '\n';
                    }
                    if (i == 0) {
                        requestToSend += 'Connection: close\r\n';
                    }
                }
                requestToSend += request[request.length - 1];
                // make sure no data is lost
                var buf = new Buffer(requestToSend, 'binary');
                cachedPieces.push(buf);
                buf = null;
                if (host == null) {
                    connection.end('HTTP/1.1 400 Bad request\r\n\r\n');
                    return;
                }
                var hp = host.split(':');
                host = hp[0];
                if (host.length > 254) {
                    connection.end('HTTP/1.1 400 Bad request\r\n\r\n');
                    return;
                }
                var port = 80;
                if (hp.length == 2) {
                    port = +hp[1];
                    if (port < 1 || port > 65535) {
                        connection.end('HTTP/1.1 400 Bad request\r\n\r\n');
                        return;
                    }
                }
                addrToSend = '\x03' +
                    String.fromCharCode(Buffer.byteLength(host, 'binary')) +
                    host + String.fromCharCode(Math.floor(port / 256)) +
                    String.fromCharCode(port % 256);

                // connect remote server
                remote = net.connect(REMOTE_PORT, SERVER, function () {
                    console.log('connecting ' + host + ':' + port);

                    var addrToSendBuf = new Buffer(addrToSend, 'binary');
                    console.log(addrToSendBuf);
                    encrypt.encrypt(encryptTable, addrToSendBuf);
                    remote.write(addrToSendBuf);
//                    encrypt.encrypt(encryptTable, buf);
                    for (var i = 0; i < cachedPieces.length; i++) {
                        var piece = cachedPieces[i];
                        console.log(piece.toString('binary'));
                        encrypt.encrypt(encryptTable, piece);
                        remote.write(piece);
                    }
                    cachedPieces = null; // save memory
                    stage = 5;
                });
                remote.on('data', function (data) {
                    encrypt.encrypt(decryptTable, data);
                    if (!connection.write(data)) {
                        remote.pause();
                    }
                });
                remote.on('end', function () {
                    console.log('remote disconnected');
                    connection.end();
                    console.log('concurrent connections: ' + server.connections);
                });
                remote.on('error', function () {
                    if (stage == 4) {
                        console.warn('remote connection refused');
                        connection.destroy();
                        return;
                    }
                    console.warn('remote error');
                    connection.end();
                    console.log('concurrent connections: ' + server.connections);
                });
                remote.on('drain', function () {
                    connection.resume();
                });
                remote.setTimeout(timeout, function () {
                    connection.end();
                    remote.destroy();
                });

            } catch (e) {
                // may encouter index out of range
                console.warn(e);
                connection.destroy();
                if (remote) {
                    remote.destroy();
                }
            }
            stage = 4;
        } else if (stage == 4) { // note this must be else if, not if!
            // remote server not connected
            // cache received buffers
            // make sure no data is lost
            cachedPieces.push(data);
        }
    });
    connection.on('end', function () {
        console.log('server disconnected');
        if (remote) {
            remote.destroy();
        }
        console.log('concurrent connections: ' + server.connections);
    });
    connection.on('error', function () {
        console.warn('server error');
        if (remote) {
            remote.destroy();
        }
        console.log('concurrent connections: ' + server.connections);
    });
    connection.on('drain', function () {
        // calling resume() when remote not is connected will crash node.js
        if (remote && stage == 5) {
            remote.resume();
        }
    });
    connection.setTimeout(timeout, function () {
        if (remote) {
            remote.destroy();
        }
        connection.destroy();
    })
});
server.listen(PORT, function () {
    console.log('server listening at port ' + PORT);
});
server.on('error', function (e) {
    if (e.code == 'EADDRINUSE') {
        console.warn('Address in use, aborting');
    }
});

