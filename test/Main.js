const {
  should,
  EVMThrow,
  EVMInvalid
} = require('./helpers');

const promisify = (inner) => new Promise((resolve, reject) => inner((err, res) => err ? reject(err) : resolve(res)));
const getBalance = (addr) => promisify((cb) => web3.eth.getBalance(addr, cb))
const getTransaction = (txHash) => promisify((cb) => web3.eth.getTransaction(txHash, cb))

const computeCost = async (receipt) => {
  let {
    gasPrice
  } = await getTransaction(receipt.transactionHash);
  return gasPrice.times(receipt.gasUsed);
}

const C = artifacts.require("./MineableToken.sol");

// Time for the real work
contract('Token Tests', function(accounts) {

  /**
   * owner        - address that should be assigned as owner of deployed contract
   * miner        - address that mines Tokens
   * _name        - the name of the Token
   * _symbol      - the symbol for the Token
   * _decimals    - number of decimal places that token uses
   */
  const [owner, miner] = accounts;
  const _name = "TOKEN NAME";
  const _symbol = "SYM";
  const _decimals = 18;
  let c;

  /**
   * Runs once at start of test suite
   */
  before(async function() {

    // deploy contract with parameters for testing
    contract = await C.new(_name, _symbol, _decimals);
  });

  /**
   * Runs before each test
   */
  beforeEach(async function() {

    //ensure contract is unpaused
    let isPaused = await contract.paused();
    if (isPaused) {
      await contract.unpause({
        from: accounts[0]
      });
    }

    //reset contract owner
    let currentOwner = await contract.owner();
    await contract.transferOwnership(owner, {
      from: currentOwner
    });

  });

  //Base Contract Tests
  it("should have an address", async function() {
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

  it("should not be paused on contract creation when Pausable", async function() {
    (await contract.paused()).should.be.false;
  });

  //Ownership Tests
  it("should allow transfer of ownership by owner when Ownable", async function() {

    let newOwner = accounts[9];

    await contract.transferOwnership(newOwner, {
      from: owner
    });
    (await contract.owner()).should.equal(newOwner);
  });

  it("should not allow transfer of ownership by non-owner when Ownable", async function() {

    let newOwner = accounts[8];

    await contract.transferOwnership(newOwner, {
      from: accounts[7]
    }).should.be.rejectedWith(EVMThrow);
  });

  //Pausable Tests
  it("should be able to be paused and unpaused by owner when Pausable", async function() {

    await contract.pause({
      from: owner
    });
    (await contract.paused()).should.be.true;
    await contract.unpause({from: owner});
    (await contract.paused()).should.be.false;
  });

  it("should not allow pause by non-owner when Pausable", async function() {

    await contract.pause({
      from: accounts[1]
    }).should.be.rejectedWith(EVMThrow);
  });

  it("should not allow unpause by non-owner if paused when Pausable", async function() {

    await contract.pause({
      from: owner
    });
    (await contract.paused()).should.be.true;
    await contract.unpause({
      from: accounts[1]
    }).should.be.rejectedWith(EVMThrow);
  });

  //Token Function Tests
  it("should allow approve() and allowance() when unpaused", async function() {

    (await contract.paused()).should.be.false;

    let xferAmt = 1000;

    let { logs } = await contract.approve(accounts[1], xferAmt, {from: accounts[0]});
    let { event, args } = logs[0];
    event.should.equal('Approval');
    args.should.deep.equal({
      owner: accounts[0],
      spender: accounts[1],
      value: web3.toBigNumber(xferAmt)
    });

    let allowance = await contract.allowance(accounts[0], accounts[1]);
    allowance.should.deep.equal(web3.toBigNumber(xferAmt));

    await contract.approve(accounts[1], 0, {from: accounts[0]}); //reset
  });

  it("should not allow approve() when paused", async function() {

    await contract.pause({from: owner});
    (await contract.paused()).should.be.true;

    await (contract.approve(accounts[1], 0, {
      from: accounts[0]}))
      .should.be.rejectedWith(EVMThrow);
  });

  it("should not allow transfer() when paused", async function() {

    await contract.pause({from: owner});
    (await contract.paused()).should.be.true;

    let xferAmt = 1000;

    await contract.transfer(
      accounts[1],
      xferAmt,
      { from: accounts[0] })
      .should.be.rejectedWith(EVMThrow);
  });

  it("should not allow transferFrom() when paused", async function() {

    let xferAmt = 1000;

    // need to approve some tokens first
    let { logs } = await contract.approve(accounts[1], xferAmt, {from: accounts[0]});
    let { event, args } = logs[0];
    event.should.equal('Approval');

    //pause the contract
    await contract.pause({from: accounts[0]});

    //check that transferFrom fails.
    await contract.transferFrom(
      accounts[0],
      null,
      xferAmt,
      { from: accounts[1] }).should.be.rejectedWith(EVMThrow);
  });

  it("should not allow transfer() when _to is null", async function() {

    (await contract.paused()).should.be.false;
    let xferAmt = 1000;

    await contract.transfer(
      null,
      xferAmt,
      { from: accounts[0] })
      .should.be.rejectedWith(EVMThrow);
  });

  it("should not allow transfer() when _to is 0x0000000000000000000000000000000000000000", async function() {

    (await contract.paused()).should.be.false;
    let xferAmt = 1000;

    await contract.transfer(
      '0x0000000000000000000000000000000000000000',
      xferAmt,
      { from: accounts[0] })
      .should.be.rejectedWith(EVMThrow);
  });

  it("should not allow transferFrom() when _to is null", async function() {

    (await contract.paused()).should.be.false;
    let xferAmt = 1000;

    let { logs } = await contract.approve(accounts[1], xferAmt, {from: accounts[0]});
    let { event, args } = logs[0];
    event.should.equal('Approval');

    await contract.transferFrom(
      accounts[0],
      null,
      xferAmt,
      { from: accounts[1] }).should.be.rejectedWith(EVMThrow);

    await contract.approve(accounts[1], 0, {from: accounts[0]}); //reset
  });

  it("should not allow transferFrom() when _to is 0x0000000000000000000000000000000000000000", async function() {

    (await contract.paused()).should.be.false;
    let xferAmt = 1000;

    let { logs } = await contract.approve(accounts[1], xferAmt, {from: accounts[0]});
    let { event, args } = logs[0];
    event.should.equal('Approval');


    await contract.transferFrom(
      accounts[0],
      '0x0000000000000000000000000000000000000000',
      xferAmt,
      { from: accounts[1] }).should.be.rejectedWith(EVMThrow);

    await contract.approve(accounts[1], 0, {from: accounts[0]}); //reset
  });

  it("should allow transferFrom() when properly approved and unpaused", async function() {
    throw new Error("test not written yet")
  });

  it("should allow transfer() of Tokens by address owner when unpaused", async function() {
    throw new Error("test not written yet")
  });

  //Gas Limit Functions
  it("should allow setting of gas price by owner when unpaused", async function() {
    throw new Error("test not written yet")
  });

  it("should not allow setting of gas price by owner when paused", async function() {
    throw new Error("test not written yet")
  });

  it("should only allow setting of gas price by owner", async function() {
    throw new Error("test not written yet")
  });

  it("should not allow setting of gas price to 0", async function() {
    throw new Error("test not written yet")
  });

  //Mineable Functions
  it("should reject mining solution if txn gas price is higher than gas price limit", async function() {
    throw new Error("test not written yet")
  });

  it("should accept mining solution if txn gas price is lower than gas price limit", async function() {
    throw new Error("test not written yet")
  });

});
