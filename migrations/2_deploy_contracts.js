var MineableToken = artifacts.require("./MineableToken.sol");

module.exports = function(deployer, network, accounts) {
  if (network === 'development') {

    const [owner, miner] = accounts;
    const _name = "TOKEN NAME";
    const _symbol = "SYM";
    const _decimals = 18;

    deployer.deploy(UTO, owner, "TOKEN NAME", "SYM"); // <-- dummy params
  } else if (network === 'test') {
    // Do not deploy contracts, each test should deploy them by itself
    console.log(accounts[0]);
  }
};
