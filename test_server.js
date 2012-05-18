// pipe client and baidu

function safe(func) {
    return function() {
        try {
            func.apply(this, arguments);
        } catch(e) {
            console.log(e);
        }
    }
}

var net = require('net');
var server = net.createServer(safe(function(c) { //'connection' listener
    console.log('server connected');
    
    var client = net.connect(80, 'www.google.com', safe(function() { //'connect' listener
        console.log('client connected');
    }));
    client.on('data', safe(function(data) {
//        console.log(data.toString());
        c.write(data);
    }));
    client.on('end', safe(function() {
        console.log('client disconnected');
        c.end();
    }));
    client.on('error', safe(function() {
        console.log('client error');
        c.end();
    }));
    c.on('end', safe(function() {
        console.log('server disconnected');
        client.end();
    }));
    c.on('data', safe(function(data) {
//        console.log(data.toString());
        client.write(data);
    }));
    c.on('error', safe(function() {
        console.log('server error');
        client.end();
    }));

}));
server.listen(8124, function() { //'listening' listener
    console.log('server bound');
});