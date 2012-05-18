var crypto = require('crypto');

var int32Max = Math.pow(2, 32);
// do a mod for large number
// since js only support 2^53
// div must be a very small number
// function modInt64(high, low, div) {
//     return ((high % div) * int32Max + low) % div;
// }
//
// function pseudoRandomCompare(x, y, i, ah, al) {
//     return modInt64(ah, al, x + i) - modInt64(ah, al, y + i);
// }

exports.getTable = function (key) {
    var table = new Buffer(256);
    var decrypt_table = new Buffer(256);
    var md5sum = crypto.createHash('md5');
    md5sum.update(key);
    var hash = new Buffer(md5sum.digest(), 'binary');
    // js doesn't support int64, so we have to break into 2 int32
    var al = hash.readUInt32LE(0);
    var ah = hash.readUInt32LE(4);
    for (var i = 0; i < 256; i++) {
        table[i] = i;
    }
    for (var i = 1; i < 1024; i++) {
        for (var k = 256 - 2; k >= 0; --k) {
            for (var j = 0; j <= k; ++j) {
                var x = table[j], y = table[j + 1];
                // if (pseudoRandomCompare(table[j], table[j + 1], i, ah, al) > 0) {
                // inline this calculation to make it 40% faster
                if (((ah % (x + i)) * int32Max + al) % (x + i) -
                    ((ah % (y + i)) * int32Max + al) % (y + i) > 0) {
                    var t = table[j];
                    table[j] = table[j + 1];
                    table[j + 1] = t;
                }
            }
        }
    }
    for (i = 0; i < 256; ++i) {
        // gen decrypt table from encrypt table
        decrypt_table[table[i]] = i;
    }
    return [table, decrypt_table];
}

exports.encrypt = function (table, buf) {
    for (var i = 0; i < buf.length; i++) {
        buf[i] = table[buf[i]];
    }
    return buf;
}
