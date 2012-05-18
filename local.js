var SERVER = '127.0.0.1';
var REMOTE_PORT = 8499;
var PORT = 1080;
var KEY = 'foobar!';

var net = require('net');
var encrypt = require('./encrypt.js');
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
        console.log('remote error');
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
        console.log('server error');
        remote.end();
    });
});
server.listen(PORT, function() {
    console.log('server bound');
});

