const EVMThrow = 'revert';
const EVMInvalid = 'invalid opcode';
const BigNumber = web3.BigNumber;
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should()

module.exports = { should, EVMThrow, EVMInvalid }
