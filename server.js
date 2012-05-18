var PORT = 8499;
var KEY = 'foobar!';

var net = require('net');
var encrypt = require('./encrypt.js');
var tables = encrypt.getTable(KEY);
var encryptTable = tables[0];
var decryptTable = tables[1];

function appendBuffer(left, right) {
    if (buf == null) {
        return right;
    }
    var buf = new Buffer(left.length + right.length);
    left.copy(buf, 0);
    right.copy(buf, left.length);
    return buf;
}

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

    var stage = 0, headerBuf = null, receivedBytes = 0, headerLength = 0, mode = 0,
        addrtype = 0, addrLen = 0, remoteAddr = null, remotePort = null,
        remote = null;
    var cachedPieces = [];

    connection.on('data', function (data) {
        if (stage == 5) {
            console.log(5);
            // pipe sockets
            encrypt.encrypt(decryptTable, data);
            remote.write(data);
            return;
        }
        headerBuf = appendBuffer(headerBuf, data);
        receivedBytes += data.length;
        console.log('receivedByptes: ' + receivedBytes);
        if (stage == 0) {
            console.log(0);
            if (receivedBytes < 262) {
                return;
            } else {
                var tempBuf = new Buffer(2);
                tempBuf.write('\x05\x00', 0);
                encrypt.encrypt(encryptTable, tempBuf);
                connection.write(tempBuf);
                stage = 1;
            }
        }
        if (stage == 1) { // note this must be if, not else if!
            console.log(1);
            // mode and addrtype
            if (receivedBytes < 267) {
                return;
            } else {
                mode = headerBuf[264];
                addrtype = headerBuf[266];
                if (addrtype == 3) {
                    addrLen = headerBuf[266];
                } else if (addrtype != 1) {
                    connection.end();
                    return;
                }
                stage = 2;
            }
        }
        if (stage == 2) { // note this must be if, not else if!
            console.log(2);
            // read address and port
            if (addrtype == 1) {
                if (receivedBytes < 273) {
                    return;
                } else {
                    remoteAddr = inetNtoa(headerBuf.slice(267, 267 + 4));
                    remotePort = headerBuf.readUInt16BE(271);
                    headerLength = 273;
                    stage = 3;
                }
            } else {
                if (receivedBytes < 267 + addrLen + 2) {
                    return;
                } else {
                    remoteAddr = headerBuf.slice(267, 267 + addrLen).toString();
                    remotePort = headerBuf.readUInt16BE(267 + addrLen);
                    headerLength = 267 + addrLen + 2;
                    stage = 3;
                }
            }
        }
        if (stage == 3) { // note this must be if, not else if!
            console.log(3);
            // connect remote server
            remote = net.connect(remotePort, remoteAddr, function () { //'connect' listener
                console.log('remote connected');
                var ipBuf = inetAton(remote.remoteAddress);
                if (ipBuf == null) {
                    connection.end();
                    return;
                }
                var buf = new Buffer(10);
                buf.write(0, '\x05\x00\x00\x01', 'binary');
                ipBuf.copy(buf, 4);
                buf.writeInt16BE(remote.remotePort, 8);
                encrypt.encrypt(encryptTable, buf);
                connection.write(buf);
                for (var i = 0; i < cachedPieces.length; i++) {
                    var piece = cachedPieces[i];
                    encrypt.encrypt(decryptTable, piece);
                    remote.write(piece);
                }
                cachedPieces = null; // save memory
                stage = 5;
            });
            remote.on('data', function (data) {
                encrypt.encrypt(encryptTable, data);
                connection.write(data);
            });
            remote.on('end', function () {
                console.log('remote disconnected');
                connection.end();
            });
            remote.on('error', function () {
                console.log('remote error');
                connection.end();
            });
            if (headerBuf.length > headerLength) {
                // make sure no data is lost
                var buf = new Buffer(headerBuf.length - headerLength);
                headerBuf.copy(buf, 0, headerLength);
                cachedPieces.push(buf);
            }
            stage = 4;
        } else if (stage == 4) { // note this must be else if, not if!
            console.log(4);
            // remote server not connected
            // cache received buffers
            // make sure no data is lost
            cachedPieces.push(data);
        }
    });
    connection.on('end', function () {
        console.log('server disconnected');
        if (remote) {
            remote.end();
        }
    });
    connection.on('error', function () {
        console.log('server error');
        if (remote) {
            remote.end();
        }
    });
});
server.listen(PORT, function () { //'listening' listener
    console.log('server bound');
});

