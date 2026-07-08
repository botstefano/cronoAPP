const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('Cliente123!', 10);
console.log(hash);
