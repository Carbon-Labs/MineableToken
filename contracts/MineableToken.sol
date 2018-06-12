pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

/**
 * Pausable is Ownable
 * StandardToken is ERC20, BasicToken
 * ERC20 is ERC20Basic
 * BasicToken is ERC20Basic
 */
contract MineableToken is Pausable, StandardToken {

  // Events

  // Variables
  string public name;             //Token name for display
  string public symbol;           //Token symbol for display
  uint8 public decimals;          //Number of decimal places

  //Constructor
  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
