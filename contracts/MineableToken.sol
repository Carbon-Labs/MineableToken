pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Gas Limited / Controllable contract
// Mineable ERC20 (ERC918) Token using Proof Of Work
//
// Based off the original mineable contract developed for '0xBitcoin Token'
//
// Developed by Liberation Online - http://liberation.online
// Creators of the KIWI Token - http://thekiwi.online
//
// For more information: https://github.com/liberation-online/MineableToken
//
// Provided as is. Use at your own risk.
//
// ----------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

interface EIP918Interface  {

    //function mint(uint256 nonce, bytes32 challenge_digest) external returns (bool success);
    function getChallengeNumber() external constant returns (bytes32);
    function getMiningDifficulty() external constant returns (uint);
    function getMiningTarget() external constant returns (uint);
    function getMiningReward() external constant returns (uint);

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

/**
 * Pausable is Ownable
 * StandardToken is ERC20, BasicToken
 * ERC20 is ERC20Basic
 * BasicToken is ERC20Basic
 */
contract MineableToken is Pausable, StandardToken, EIP918Interface {

  using ExtendedMath for uint;

  // Events
  event GasPriceSet(uint8 _gasPrice);
  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
  event Debug(uint256 txGas, uint256 curGasPriceLimit); //TODO - remove this once contract finalised

  // Variables
  // ERC20 Standard
  string public name;               //Token name for display
  string public symbol;             //Token symbol for display
  uint8 public decimals;            //Number of decimal places
  uint public _totalSupply;

  // Owner Controls
  uint public gasPriceLimit;                     //Gas Price Limit

  // Mineable Related
  address public lastRewardTo;
  bytes32 public challengeNumber;
  uint public miningTarget;
  uint public latestDifficultyPeriodStarted;
  uint public epochCount;                       //number of 'blocks' mined
  uint public _blocks_per_adjustment;
  uint public _min_target;
  uint public _max_target;
  uint public rewardEra;
  uint public maxSupplyForEra;
  uint public lastRewardAmount;
  uint public lastRewardEthBlockNumber;
  uint public tokensMinted;
  uint startingMiningReward;                      //this is not public, as mining reward will change over time

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  //Constructor
  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    _blocks_per_adjustment = 512;                // TODO: set in constructor
    startingMiningReward = 50;                    // TODO: set in constructor
    totalSupply_ = 1000000 * 10**uint(decimals);  // TODO: read from constructor

    //default values - don't change unless you know what you are doing
    _min_target = 2**16;
    _max_target = 2**234;
    rewardEra = 1;
    tokensMinted = 0;
    maxSupplyForEra = totalSupply_.div(2);
    latestDifficultyPeriodStarted = block.number;
    challengeNumber = block.blockhash(block.number - 1);

    //these are default values that will be overwritten by the contract automatically or
    //can be changed by the contract owner calling a function
    miningTarget = _max_target;
    gasPriceLimit = 999;

    //original contract called _startNewMiningEpoch();
    //this is not really needed - we have already set all the values

  }

  //modifier used for checking that the txn.gasPrice is lower than the limit set
  modifier checkGasPrice(uint txnGasPrice) {
    require(txnGasPrice <= gasPriceLimit * 1000000000);
    _;
  }

  // dont receive ether via fallback method (by not having 'payable' modifier on this function).
  function () public { }

  /**
   * @dev transfer out any accidently sent ERC20 tokens
   * @param tokenAddress The contract address of the token
   * @param tokens The amount of tokens to transfer
   */
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return StandardToken(tokenAddress).transfer(owner, tokens);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) whenNotPaused public returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * @dev
   * @param _gasPrice The gas price in Gwei to set
   */
   function setGasPriceLimit(uint8 _gasPrice) onlyOwner
    //checkGasPrice(_gasPrice)
    public {
      require(_gasPrice > 0);
     gasPriceLimit = _gasPrice;

     emit GasPriceSet(_gasPrice); //emit event
   }

   /**
    * Mining related functions
    */
    //function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
    function getMiningDifficulty() public constant returns (uint) {
      return _max_target.div(miningTarget);
    }

    //reward is cut in half every reward era (as tokens are mined)
    function getMiningReward() public constant returns (uint) {
      if(rewardEra == 1) {
        return startingMiningReward * 10**uint(decimals);
      } else {

        return (startingMiningReward * 10**uint(decimals) ).div( 2**(rewardEra-1) );
      }
    }

    // TODO
    function mint() checkGasPrice(tx.gasprice) public returns (bool success) {

      emit Debug(tx.gasprice, gasPriceLimit);
    }

    // TODO
    function _startNewMiningEpoch() internal {}

    // Calculates the difficulty target at the end of every epoch
    function _adjustDifficulty() internal {

      uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
      uint epochsMined = _blocks_per_adjustment;
      uint targetEthBlocksPerDiffPeriod = epochsMined * 12; //TODO - calculate this with a variable should be 12 times slower than ethereum

      // less eth blocks mined than expected
      if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod ) {

        uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );
        uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

        //make it harder
        miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %

      } else {

        uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );
        uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

        //make it easier
        miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
      }

      latestDifficultyPeriodStarted = block.number;

      if(miningTarget < _min_target) //very difficult
      {
          miningTarget = _min_target;
      }

      if(miningTarget > _max_target) //very easy
      {
        miningTarget = _max_target;
      }
    }

    //Useful for debugging miners
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {
      bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
      return digest;
    }

    //Useful for debugging miners
    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
      bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
      if(uint256(digest) > testTarget) revert();

      return (digest == challenge_digest);
    }

}
