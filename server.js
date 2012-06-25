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

var PORT = 8388;
var KEY = 'barfoo!';
var timeout = 60000;

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
        addrLen = 0, remoteAddr = null, remotePort = null;
    connection.on('data', function (data) {
        encrypt.encrypt(decryptTable, data);
        if (stage == 5) {
            // pipe sockets
            if (!remote.write(data)) {
                connection.pause();
            }
            return;
        }
        if (stage == 0) {
            try {
                var addrtype = data[0];
                if (addrtype == 3) {
                    addrLen = data[1];
                } else if (addrtype != 1) {
                    console.warn('unsupported addrtype: ' + addrtype);
                    connection.end();
                    return;
                }
                // read address and port
                if (addrtype == 1) {
                    remoteAddr = inetNtoa(data.slice(1, 5));
                    remotePort = data.readUInt16BE(5);
                    headerLength = 7;
                } else {
                    remoteAddr = data.slice(2, 2 + addrLen).toString('binary');
                    remotePort = data.readUInt16BE(2 + addrLen);
                    headerLength = 2 + addrLen + 2;
                }
                console.log(remoteAddr);
                // connect remote server
                remote = net.connect(remotePort, remoteAddr, function () {
                    console.log('connecting ' + remoteAddr);
                    for (var i = 0; i < cachedPieces.length; i++) {
                        var piece = cachedPieces[i];
                        remote.write(piece);
                    }
                    cachedPieces = null; // save memory
                    stage = 5;
                });
                remote.on('data', function (data) {
                    encrypt.encrypt(encryptTable, data);
                    if (!connection.write(data)) {
                        remote.pause();
                    }
                });
                remote.on('end', function () {
                    console.log('remote disconnected');
                    console.log('concurrent connections: ' + server.connections);
                    connection.end();
                });
                remote.on('error', function () {
                    if (stage == 4) {
                        console.warn('remote connection refused');
                        connection.end();
                        return;
                    }
                    console.warn('remote error');
                    connection.end();
                    console.log('concurrent connections: ' + server.connections);
                });
                remote.on('drain', function () {
                    connection.resume();
                });
                remote.setTimeout(timeout, function() {
                    connection.end();
                    remote.destroy();
                });
                if (data.length > headerLength) {
                    // make sure no data is lost
                    var buf = new Buffer(data.length - headerLength);
                    data.copy(buf, 0, headerLength);
//                    console.log('data/header: ' + data.length + '/' + headerLength);
//                    console.log(buf.toString('binary'));
                    cachedPieces.push(buf);
                    buf = null;
                }
                stage = 4;
            } catch (e) {
                // may encouter index out of range
                console.warn(e);
                connection.destroy();
                if (remote) {
                    remote.destroy();
                }
            }
        } else if (stage == 4) { // note this must be else if, not if!
//            console.log(4);
//            console.log(data.toString('binary'));
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
        if (remote) {
            remote.resume();
        }
    });
    connection.setTimeout(timeout, function() {
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

console.log(server.maxConnections);

