//var crypto = require('crypto');
//
//var shasum = crypto.createHash('md5');
//
//shasum.update('test');
//console.log(JSON.stringify(shasum.digest('binary')));
var encryptTable =new Buffer(256);
for (var i=0;i<256;i++) {
    encryptTable[i] = 255 - i;
}

var buf = new Buffer(1024 * 1024 * 20);

for(var i=0;i<buf.length;i++) {
    buf[i] = encryptTable[i];
}
console.log(buf);
console.log(buf[257]);
console.log(buf.readUInt32LE(0));