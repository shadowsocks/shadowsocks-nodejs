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
var REMOTE_PORT = 8499;
var PORT = 1080;
var KEY = 'foobar!';

var net = require('net');
var encrypt = require('./encrypt.js');
console.log('calculating ciphers');
var tables = encrypt.getTable(KEY);
var encryptTable = tables[0];
var decryptTable = tables[1];

var server = net.createServer(function(connection) {
    console.log('server connected');

    var remote = net.connect(REMOTE_PORT, SERVER, function() {
        console.log('remote connected');
    });
    remote.on('data', function(data) {
        encrypt.encrypt(decryptTable, data);
        if (!connection.write(data)) {
            remote.pause();
        }
    });
    remote.on('drain', function(data) {
        connection.resume();
    });
    remote.on('end', function() {
        console.log('remote disconnected');
        connection.end();
    });
    remote.on('error', function() {
        console.warn('remote error');
        connection.end();
    });
    connection.on('end', function() {
        console.log('server disconnected');
        remote.end();
    });
    connection.on('data', function(data) {
        encrypt.encrypt(encryptTable, data);
        if (!remote.write(data)) {
            connection.pause();
        }
    });
    connection.on('drain', function(data) {
        remote.resume();
    });
    connection.on('error', function() {
        console.warn('server error');
        remote.end();
    });
});
server.listen(PORT, function() {
    console.log('server listening at port ' + PORT);
});
server.on('error', function (e) {
  if (e.code == 'EADDRINUSE') {
    console.warn('Address in use, aborting');
  }
});
