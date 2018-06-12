const { should, EVMThrow, EVMInvalid } = require('./helpers');

const promisify = (inner) => new Promise((resolve, reject) => inner((err, res) => err ? reject(err) : resolve(res)));
const getBalance = (addr) => promisify((cb) => web3.eth.getBalance(addr, cb))
const getTransaction = (txHash) => promisify((cb) => web3.eth.getTransaction(txHash, cb))

const computeCost = async (receipt) => {
  let { gasPrice } = await getTransaction(receipt.transactionHash);
  return gasPrice.times(receipt.gasUsed);
}

// Time for the real work
contract('Token Tests', function(accounts) {

  //Base contract tests
  it("should have an address", async function () {

    web3.isAddress(contract.address).should.be.true;
  });

  it("should have the correct token name", async function() {

    (await contract.name()).should.equal(_name);
  });

  it("should have the correct token symbol", async function() {

    (await contract.symbol()).should.equal(_symbol);
  });

  it("should have the correct number of decimals", async function() {

    let decimals = await (contract.decimals());
    decimals.should.bignumber.equal(_decimals);
  });

  it("should set owner on contract creation when Ownable", async function() {

    (await contract.owner()).should.equal(owner);
  });

});
