pragma solidity ^0.4.18;
import "../BasicCrowdsale.sol";
import "./CustomTokenExample.sol";

// Custom crowdsale example
contract CustomCrowdsale is BasicCrowdsale {
  // Crowdsale participants
  mapping(address => uint256) participants;

  // tokens per ETH fixed price
  uint256 tokensPerEthPrice;

  // Crowdsale token
  CustomTokenExample crowdsaleToken;

  // Ctor. In this example, minimalGoal, hardCap, and price are not changeable.
  // In more complex cases, those parameters may be changed until start() is called.
  function CustomCrowdsale(
    uint256 _minimalGoal,
    uint256 _hardCap,
    uint256 _tokensPerEthPrice,
    address _token
  )
    public
    // simplest case where manager==owner. See onlyOwner() and onlyManager() modifiers
    // before functions to figure out the cases in which those addresses should differ
    BasicCrowdsale(msg.sender, msg.sender)
  {
    // just setup them once...
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    tokensPerEthPrice = _tokensPerEthPrice;
    crowdsaleToken = CustomTokenExample(_token);
  }

// Here goes ICrowdsaleProcessor implementation

  // returns address of crowdsale token. The token must be ERC20-compliant
  function getToken()
    public
    returns(address)
  {
    return address(crowdsaleToken);
  }

  // called by CrowdsaleController to transfer reward part of
  // tokens sold by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process.
  function mintTokenRewards(
    address _contract,  // Forecasting contract
    uint256 _amount     // agreed part of totalSold which is intended for rewards
  )
    public
    onlyManager() // manager is CrowdsaleController instance
  {
    // crowdsale token is mintable in this example, tokens are created here
    crowdsaleToken.issue(_contract, _amount);
  }

  // transfers crowdsale token from mintable to transferrable state
  function releaseTokens()
    public
    onlyManager()             // manager is CrowdsaleController instance
    hasntStopped()            // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale was successful
  {
    // see token example
    crowdsaleToken.release();
  }

// Here go crowdsale process itself and token manipulations

  // default function allows for ETH transfers to the contract
  function () payable public {
    require(msg.value > 0);

    // and it sells the token
    sellTokens(msg.sender, msg.value);
  }

  // sels the project's token to buyers
  function sellTokens(address _recepient, uint256 _value)
    internal
    hasBeenStarted()     // crowdsale started
    hasntStopped()       // wasn't cancelled by owner
    whenCrowdsaleAlive() // in active state
  {
    uint256 newTotalCollected = totalCollected + _value;

    if (hardCap < newTotalCollected) {
      // don't sell anything above the hard cap

      uint256 refund = newTotalCollected - hardCap;
      uint256 diff = _value - refund;

      // send the ETH part which exceeds the hard cap back to the buyer
      _recepient.transfer(refund);
      _value = diff;
    }

    // token amount as per price (fixed in this example)
    uint256 tokensSold = _value * tokensPerEthPrice;

    // create new tokens for this buyer
    crowdsaleToken.issue(_recepient, tokensSold);

    // remember the buyer so he/she/it may refund its ETH if crowdsale failed
    participants[_recepient] += _value;

    // update total ETH collected
    totalCollected += _value;

    // update totel tokens sold
    totalSold += tokensSold;
  }

  // project's owner withdraws ETH funds to the funding address upon successful crowdsale
  function withdraw(
    uint256 _amount // can be done partially
  )
    public
    onlyOwner() // project's owner
    hasntStopped()  // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
  {
    require(_amount <= this.balance);
    fundingAddress.transfer(_amount);
  }

  // backers refund their ETH if the crowdsale was cancelled or has failed
  function refund()
    public
  {
    // either cancelled or failed
    require(stopped || isFailed());

    uint256 amount = participants[msg.sender];

    // prevent from doing it twice
    require(amount > 0);
    participants[msg.sender] = 0;

    msg.sender.transfer(amount);
  }
}
