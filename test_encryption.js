var encrypt = require('./encrypt.js');

var tables = encrypt.getTable('foobar!');
console.log(tables);
console.assert(tables[0][0] == 60);
console.assert(tables[0][1] == 53);
console.assert(tables[0][2] == 84);

console.assert(tables[1][0] == 151);
console.assert(tables[1][1] == 205);
console.assert(tables[1][2] == 99);

console.log('test passed');