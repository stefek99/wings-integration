pragma solidity ^0.4.18;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract HasManager {
  address public manager;

  function HasManager() public {
    manager = msg.sender;
  }

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

  function transferManager(address newManager) public onlyManager() {
    require(newManager != address(0));
    manager = newManager;
  }
}

// Crowdsale contracts interface
contract ICrowdsaleProcessor is Ownable, HasManager {
  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }

  // Minimal acceptable hard cap
  uint256 constant public MIN_HARD_CAP = 1 ether;

  // Minimal acceptable duration of crowdsale
  uint256 constant public MIN_CROWDSALE_TIME = 3 days;

  // Maximal acceptable duration of crowdsale
  uint256 constant public MAX_CROWDSALE_TIME = 50 days;

  // Becomes true when timeframe is assigned
  bool public started;

  // Becomes true if cancelled by owner
  bool public stopped;

  // Total collected Ethereum: must be updated every time tokens has been sold
  uint256 public totalCollected;

  // Total amount of project's token sold: must be updated every time tokens has been sold
  uint256 public totalSold;

  // Crowdsale minimal goal, must be greater or equal to Forecasting min amount
  uint256 public minimalGoal;

  // Crowdsale hard cap, must be less or equal to Forecasting max amount
  uint256 public hardCap;

  // Crowdsale duration in seconds.
  // Accepted range is MIN_CROWDSALE_TIME..MAX_CROWDSALE_TIME.
  uint256 public duration;

  // Start timestamp of crowdsale, absolute UTC time
  uint256 public startTimestamp;

  // End timestamp of crowdsale, absolute UTC time
  uint256 public endTimestamp;

  // Allows to transfer some ETH into the contract without selling tokens
  function deposit() public payable {}

  // Returns address of crowdsale token, must be ERC20 compilant
  function getToken() public returns(address);

  // Transfers ETH rewards amount (if ETH rewards is configured) to Forecasting contract
  function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

  // Mints token Rewards to Forecasting contract
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

  // Releases tokens (transfers crowdsale token from mintable to transferrable state)
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();

  // Stops crowdsale. Called by CrowdsaleController, the latter is called by owner.
  // Crowdsale may be stopped any time before it finishes.
  function stop() public onlyManager() hasntStopped();

  // Validates parameters and starts crowdsale
  function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress)
    public onlyManager() hasntStarted() hasntStopped();

  // Is crowdsale failed (completed, but minimal goal wasn't reached)
  function isFailed() public constant returns (bool);

  // Is crowdsale active (i.e. the token can be sold)
  function isActive() public constant returns (bool);

  // Is crowdsale completed successfully
  function isSuccessful() public constant returns (bool);
}


// Basic crowdsale implementation both for regualt and 3rdparty Crowdsale contracts
contract BasicCrowdsale is ICrowdsaleProcessor {
  event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

  // Where to transfer collected ETH
  address public fundingAddress;

  // Ctor.
  function BasicCrowdsale(
    address _owner,
    address _manager
  )
    public
  {
    owner = _owner;
    manager = _manager;
  }

  // called by CrowdsaleController to transfer reward part of ETH
  // collected by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process
  // iff agreed ETH reward part is not zero
  function mintETHRewards(
    address _contract,  // Forecasting contract
    uint256 _amount     // agreed part of totalCollected which is intended for rewards
  )
    public
    onlyManager() // manager is CrowdsaleController instance
  {
    require(_contract.call.value(_amount)());
  }

  // cancels crowdsale
  function stop() public onlyManager() hasntStopped()  {
    // we can stop only not started and not completed crowdsale
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

  // called by CrowdsaleController to setup start and end time of crowdfunding process
  // as well as funding address (where to transfer ETH upon successful crowdsale)
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    onlyManager()   // manager is CrowdsaleController instance
    hasntStarted()  // not yet started
    hasntStopped()  // crowdsale wasn't cancelled
  {
    require(_fundingAddress != address(0));

    // start time must not be earlier than current time
    require(_startTimestamp >= block.timestamp);

    // range must be sane
    require(_endTimestamp > _startTimestamp);
    duration = _endTimestamp - _startTimestamp;

    // duration must fit constraints
    require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

    // now crowdsale is considered started, even if the current time is before startTimestamp
    started = true;

    CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

  // must return true if crowdsale is over, but it failed
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
      // it was started
      started &&

      // crowdsale period has finished
      block.timestamp >= endTimestamp &&

      // but collected ETH is below the required minimum
      totalCollected < minimalGoal
    );
  }

  // must return true if crowdsale is active (i.e. the token can be bought)
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
      // it was started
      started &&

      // hard cap wasn't reached yet
      totalCollected < hardCap &&

      // and current time is within the crowdfunding period
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

  // must return true if crowdsale completed successfully
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
      // either the hard cap is collected
      totalCollected >= hardCap ||

      // ...or the crowdfunding period is over, but the minimum has been reached
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {

  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }  

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract MyToken is ERC20, Ownable {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  bool public releasedForTransfer;


  function MyToken() public {
    name = "MyTokenExample";
    symbol = "MTE";
    decimals = 18;
  }

  // override
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(releasedForTransfer);
    return super.transfer(_to, _value);
  }

  // override 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(releasedForTransfer);
    return super.transferFrom(_from, _to, _value);
  }

  function release() public onlyOwner() {
    releasedForTransfer = true;
  }
    
  function mint(address _recepient, uint256 _amount) public onlyOwner() {
    require (!releasedForTransfer);
    balances[_recepient] += _amount;
    totalSupply += _amount;
  }
}

contract MyCrowdsale is BasicCrowdsale {
  mapping(address => uint256) participants;

  uint256 tokensPerEthPrice;
  MyToken crowdsaleToken;

  // Ctor. In this example, minimalGoal, hardCap, and price are not changeable.
  // In more complex cases, those parameters may be changed until start() is called.
  // simplest case where manager==owner. See onlyOwner() and onlyManager() modifiers
  // before functions to figure out the cases in which those addresses should differ
  function MyCrowdsale(uint256 _minimalGoal, uint256 _hardCap, uint256 _tokensPerEthPrice, address _token) public BasicCrowdsale(msg.sender, msg.sender) {
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    tokensPerEthPrice = _tokensPerEthPrice;
    crowdsaleToken = MyToken(_token);
  }

  function getToken() public returns(address) {
    return address(crowdsaleToken);
  }

  // called by CrowdsaleController to transfer reward part of
  // tokens sold by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process.
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager()  {
    crowdsaleToken.mint(_contract, _amount); // crowdsale token is mintable in this example, tokens are created here
  }

  // transfers crowdsale token from mintable to transferrable state
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful() {
    crowdsaleToken.release();
  }

  // DEFAULT FUNCTION - allows for ETH transfers to the contract
  function () payable public {
    require(msg.value > 0);
    sellTokens(msg.sender, msg.value);
  }

  function sellTokens(address _recepient, uint256 _value) internal hasBeenStarted() hasntStopped() whenCrowdsaleAlive() {
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
    crowdsaleToken.mint(_recepient, tokensSold);

    // remember the buyer so he/she/it may refund its ETH if crowdsale failed
    participants[_recepient] += _value;

    // update total ETH collected
    totalCollected += _value;

    // update totel tokens sold
    totalSold += tokensSold;
  }

  // project's owner withdraws ETH funds to the funding address upon successful crowdsale
  function withdraw(uint256 _amount) public onlyOwner() hasntStopped() whenCrowdsaleSuccessful() {
    require(_amount <= this.balance);
    fundingAddress.transfer(_amount);
  }

  // backers refund their ETH if the crowdsale was cancelled or has failed
  function refund() public {
    require(stopped || isFailed()); // either cancelled or failed
    uint256 amount = participants[msg.sender];
    require(amount > 0); // prevent from doing it twice
    participants[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}