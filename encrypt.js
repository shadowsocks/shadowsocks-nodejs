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

var crypto = require('crypto');
var merge_sort = require('./merge_sort.js').merge_sort;

var int32Max = Math.pow(2, 32);

exports.getTable = function (key) {
    var table = new Array(256);
    var decrypt_table = new Array(256);
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
        table = merge_sort(table, function(x, y) {
 			return ((ah % (x + i)) * int32Max + al) % (x + i) -
                     ((ah % (y + i)) * int32Max + al) % (y + i);
 		});
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
