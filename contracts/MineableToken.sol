pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

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

  // Events
  event GasPriceSet(uint8 _gasPrice);
  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
  event Debug(uint256 txGas, uint256 curGasPriceLimit);

  // Variables
  // ERC20
  string public name;               //Token name for display
  string public symbol;             //Token symbol for display
  uint8 public decimals;            //Number of decimal places
  uint public _totalSupply;

  // Controls
  uint public gasPriceLimit;                     //Gas Price Limit

  // Mineable
  address public lastRewardTo;
  bytes32 public challengeNumber;
  uint public miningTarget;
  uint public latestDifficultyPeriodStarted;
  uint public epochCount;                       //number of 'blocks' mined
  uint public blocks_per_readjustment;
  uint public  _min_target;
  uint public  _max_target;
  uint public rewardEra;
  uint public maxSupplyForEra;
  uint public lastRewardAmount;
  uint public lastRewardEthBlockNumber;
  uint public tokensMinted;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  //Constructor
  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    gasPriceLimit = 999;
    _min_target = 2**16;
    _max_target = 2**234;
    blocks_per_readjustment = 512;
  }

  modifier checkGasPrice(uint gasPrice) {
    require(gasPrice > 0);
    _;
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
    checkGasPrice(_gasPrice)
    public {

     gasPriceLimit = _gasPrice;

     emit GasPriceSet(_gasPrice); //emit event
   }

   /**
    * Mining related functions
    */
    //function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
    //function getMiningReward() public constant returns (uint);

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
      //every reward era, the reward amount halves.
      return (5000 * 10**uint(decimals) ).div( 2**rewardEra ) ; // TODO: remove hardcoded 5000 here.
    }

    function mint() public returns (bool success) {
      //emit Debug(tx.gasprice, gasPriceLimit * 1000000000);
      require(tx.gasprice <= gasPriceLimit * 1000000000);
      emit Debug(tx.gasprice, gasPriceLimit);
    }
}
