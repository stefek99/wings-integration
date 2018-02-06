# Wings Crowdsale Integration

Wings is platform for evaluating and do ICO. Based on Ethereum smart contracts and IPFS.

With Wings any ICO can pass evaluating procedure and launch ICO via Wings ICO constructor
or by writing own crowdsale contract integrated with Wings.

To get more details read our [whitepaper](https://wingsfoundation.ch/docs/WINGS_Whitepaper_V1.1.2_en.pdf), visit [site](https://wings.ai), or join our [chat](https://telegram.me/wingschat) to talk.

## Content

- [Security](#security)
- [Help](#help)
- [Overview](#overview)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Integration](#integration)
- [Specification](#specification)
- [Step By Step Guide](#step-by-step)
- [Tests](#tests)
- [Contributors](#contributors)
- [License](#license)

## Security

Need to understand, that this is work in progress. Remember that you still work with real money, and any issue can lead to financial losses.
We strongly recommend to cover with tests your integration and implementation of crowdsale contract.

We take no responsibility for your implementation decisions and any security problem you might experience during integration,
even security issues in our smart contracts.

If you reached security issues or any other issues, please, contact us by issues or sending us email: [support@wings.ai](mailto:support@wings.ai), we have generous bounties, read more [here](https://blog.wings.ai).

## Help

If during integration you need help, we strongly recommend to contact us by email [support@wings.ai](mailto:support@wings.ai) or [telegram chat](https://telegram.me/wingschat), or directly contact [contributors](#contributors).

## Overview

To be able to participate in Wings ecosystem project that going to create his own crowdsale smart contract
should use current documentation as start point of integration to Wings rewards contracts.

Integration can be splitted in few steps:

1. Development of crowdsale smart contract
2. Integration of Wings smart contracts
3. Creation of a project with custom crowdsale contract on [Wings Platform](https://testnet.wings.ai) (via UI or manually)
4. After forecasting successful done, start of custom crowdsale contract and crowdsale on [Wings Platform](https://testnet.wings.ai) (via UI or manually)

This documentation describing only 1 step (indeed integration), about other parts read our blog [post](https://blog.wings.ai).

During integration developer of smart contract should follow rules described in current document, and understand dependencies
that he has to implement to be sure that his smart contract works fine and can be integrated at all.

If developer doesn't follow rules it can produce bugs and issues, include financial losses.

## Requirements

- Node.js v8
- truffle 4.0.6
- testrpc

## Getting Started

To get started install our package using npm:

    npm install wings-integration --save

Once package installed, you can import our BasicCrowdsale.sol contract to your smart contract.

Like:

```cs
import 'wings-integration/contracts/BasicCrowdsale.sol';
```

And then starting inheritance of BasicCrowdsale to your contract:

```cs
contract MyCrowdsale is BasicCrowdsale {
    ...
}
```

Now read [specification](#integration) before start implementation of your crowdsale smart contract.

If specification is not enough, we offer [step by step](#step-by-step) guide in additional.

## Integration

Project owner should provide 2 contracts:
+ Token contract that complies to ERC20 specification and does exactly what it’s intended for. Also note that during the crowdfunding process token values should be somewhat produced ("minted" as in the example) or transferred ("sold") to the buyer's account from some special account;
+ Custom `Crowdsale` contract which derives from `BasicCrowdsale` contract (see [BasicCrowdsale.sol](https://github.com/WingsDao/3rd-party-integration/blob/master/BasicCrowdsale.sol))

Example contracts (see [example](https://github.com/WingsDao/3rd-party-integration/tree/master/example) directory):
+ [Custom crowdsale contract](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomCrowdsale.sol);
+ [Token example with minting funciton](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomTokenExample.sol)
+ [Token example which is compatible to Bancor's smart token interface](https://github.com/WingsDao/3rd-party-integration/blob/master/example/BancorCompatibleTokenExample.sol), see specifications for [Bancor protocol](https://github.com/bancorprotocol/contracts#the-smart-token-standard)

During its lifetime, `Crowdsale` contract may reside in the following states:
+ Initial state: crowdsale is not yet started;
+ Active state: when everyone is able to buy project’s tokens (after crowdsale started);
+ Successful state: when crowdsale succeeded either by achieving hard cap or after crowdsale period ends, but collected value is equal to minimal goal or above;
+ Failed state: when crowdsale period finishes, but minimal goal is not reached *OR* if the project's owner didn't manage to start crowdfunding process during 7 days period after forecasting finished;
+ Stopped by owner: when project’s owners cancels crowdsale for some reason

`Crowdsale` instance is managed by `CrowdsaleController` instance, which is a part of Wings contracts infrastructure.

It’s necessary for custom crowdsale contract to keep in actual state all public fields of [ICrowdsaleProcessor](https://github.com/WingsDao/3rd-party-integration/blob/master/interfaces/ICrowdsaleProcessor.sol) observing the following rules:
+ `totalCollected` and `totalSold` increase during active state;
+ `minimalGoal` and `hardCap` can be changed any number of times before `start()` is called, but not after that;
+ `duration` and timestamps (`startTimestamp` and `endTimestamp`) are set in `start()` function.

In additional should be sure, that:
+ Crowdsale contract should be started in 30 days after forecasting completed
+ Crowdsale contract should have minimal goal and hard cap
+ Crowdsale contract could be stopped by crowdsale contract creator
+ Crowdsale contract should be able to distribute rewards after crowdsale successful over (see **mintETHRewards** and **mintTokensRewards** functions)

For more detailed requirements, see the custom crowdsale review checklist:

    While writing or reviewing custom Crowdsale contracts, please meet the following requirements:

    1. The contract has to be written in Solidity language and derive directly from BasicCrowdsale;
    2. If stop() is overriden by derived contract then super.stop(...) (i.e BasicCrowdsale.stop()) must be called inside;
    3. If start() is overriden by derived contract then super.start(...) (i.e BasicCrowdsale.start()) must be called inside;
    4. Timestamps, as well as minimal goal and hard cap cannot be modified after BasicCrowdsale.start() is called;
    5. totalCollected and totalSold fields increase during every token sale for right amounts;
    6. Contract cannot sell tokens before startTimestamp, after endTimestamp;
    7. Contract cannot sell tokens above hard cap;
    8. Project owner must be able to withdraw collected ETH only after the crowdsale completed successfully and only to the fundingAddress provided in start();
    9. If the crowdsale failed or cancelled, all participants should have an ability to refund their ETH;


### Specification

Custom crowdsale contract **must** be derived from `BasicCrowdsale` contract which, in turn, is derived from `ICrowdsaleProcessor` which, in turn, is derived from `Ownable` (from zeppelin-solidity library) and `HasManager` contracts.

**Difference between owner and manager:** Owner is typically the address of contract creator's account, manager is the address of the contract to which some acrtions are delegated. So effectively crowdsale contracts have 2 owners with different access rights.

`BasicCrowdsale` ([see src](https://github.com/WingsDao/3rd-party-integration/blob/master/BasicCrowdsale.sol)) implements default behavior of custom crowdsale, but BasicCrowdsale.start(...) and BasicCrowdsale.stop() functions **must** be called (via `super` mechanism) if appropriate methods are overriden in derived contracts.

#### Ownable fields

**owner**
```cs
address public owner;
```
Owner's address. Allows to make certain methods callbable by owner only (via `onlyOwner` modifier)
<br>
<br>
<br>

#### HasManager fields

**manager**
```cs
address public manager;
```
Manager's address. Allows to make certain methods callbable by manager only (via `onlyManager` modifier)
<br>
<br>
<br>

#### ICrowdsaleProcessor fields

**started**
```cs
bool public started;
```
Becomes true when timeframe is assigned
<br>
<br>
<br>
**stopped**
```cs
bool public stopped;
```
Becomes true if cancelled by owner
<br>
<br>
<br>
**totalCollected**
```cs
uint256 public totalCollected;
```
Total collected Ethereum: must be updated every time tokens has been sold
<br>
<br>
<br>
**totalSold**
```cs
uint256 public totalSold;
```
Total amount of project's token sold: must be updated every time tokens has been sold
<br>
<br>
<br>
**minimalGoal**
```cs
uint256 public minimalGoal;
```
Crowdsale minimal goal, must be greater or equal to Forecasting min amount
<br>
<br>
<br>
**hardCap**
```cs
uint256 public hardCap;
```
Crowdsale hard cap, must be less or equal to Forecasting max amount
<br>
<br>
<br>
**duration**
```cs
uint256 public duration;
```
Crowdsale duration in seconds. Accepted range is `MIN_CROWDSALE_TIME..MAX_CROWDSALE_TIME`.
<br>
<br>
<br>
**startTimestamp**
```cs
uint256 public startTimestamp;
```
Start timestamp of crowdsale, absolute UTC time
<br>
<br>
<br>
**endTimestamp**
```cs
uint256 public endTimestamp;
```
End timestamp of crowdsale, absolute UTC time
<br>
<br>
<br>

#### Ownable methods

**transferOwnership**
```cs
function transferOwnership(address newOwner) public onlyOwner;
```
Allows the current owner to transfer control of the contract to a newOwner.
<br>
<br>
<br>

#### HasManager methods

**transferManager**
```cs
function transferManager(address _newManager) public onlyManager();
```
New manager transfers its functions to new address.
<br>
<br>
<br>

#### ICrowdsaleProcessor methods

**deposit**
```cs
function deposit() public payable;
```
Allows to transfer some ETH into the contract without selling tokens.
<br>
<br>
<br>
**getToken**
```cs
function getToken() public returns(address);
```
Returns address of crowdsale token.
<br>
<br>
<br>
**mintETHRewards**
```cs
function mintETHRewards(address _contract, uint256 _amount) public onlyManager();
```
Transfers ETH rewards amount (if ETH rewards is configured) to Forecasting contract.
<br>
<br>
<br>
**mintTokenRewards**
```cs
function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();
```
Mints token Rewards to Forecasting contract
<br>
<br>
<br>
**releaseTokens**
```cs
function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();
```
Releases tokens (transfers crowdsale token from mintable to transferrable state).
<br>
<br>
<br>
**stop**
```cs
function stop() public onlyManager() hasntStopped();
```
Stops crowdsale. Called by CrowdsaleController, the latter is called by project's owner. Crowdsale may be stopped any time before it finishes.
<br>
<br>
<br>
**start**
```cs
function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress) public onlyManager() hasntStarted() hasntStopped();
```
Validates parameters and starts crowdsale.
<br>
<br>
<br>
**isFailed**
```cs
function isFailed() public constant returns (bool);
```
Is crowdsale failed (completed, but minimal goal wasn't reached).
<br>
<br>
<br>
**isActive**
```cs
function isActive() public constant returns (bool);
```
Is crowdsale active (i.e. the token can be sold).
<br>
<br>
<br>
**isSuccessful**
```cs
function isSuccessful() public constant returns (bool);
```
Is crowdsale completed successfully.
<br>
<br>
<br>

In case you don't feel provided functional enough, you can override functions, for example,
overriding of isFailed/isActive/isSuccessful could be good idea in case you have another
standards of states of your ICO.

But for such complex things we strongly recommending to cover project with tests,
and contact Wings team for [help](#help).

## Step By Step

Let's do custom crowdsale contract step by step and integrate it to Wings.

We will do Crowdsale contract that works only with whitelisted addresses (or addresses
passed KYC), as Wings by default doesn't support such functional "from the box".

First let's just prepare contract that will contains all whitelisted addresses added by contract
owner.

So we create another [truffle](https://github.com/trufflesuite/truffle) project, adding there
`wings-integration` and [zeppelin-solidity](https://github.com/OpenZeppelin/zeppelin-solidity).

```cs
npm i wings-integration --save
npm i zeppelin-solidity --save
```

So now let's code whitelist contract.

```cs
pragma solidity 0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract Whitelist is Ownable {
  event APPROVE(address indexed approved);
  event DECLINE(address indexed declined);

  mapping(address => bool) list;

  function Whitelist() {
    owner = msg.sender;
  }

  function addAddress(address _participant) public onlyOwner {
    require(!list[_participant]);

    list[_participant] = true;
    APPROVE(_participant);
  }

  function declineAddress(address _participant) public onlyOwner {
    require(list[_participant]);

    list[_participant] = false;
    DECLINE(_participant);
  }

  function isApproved(address _participant) public view returns (bool) {
    return list[_participant];
  }
}
```

And we make a token contract, that can issue new tokens.
Let's take one from example directory:

```cs
pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

// Minimal crowdsale token for custom contracts
contract Token is Ownable, StandardToken {
    // ERC20 requirements
    string public name;
    string public symbol;
    uint8 public decimals;

    // how many tokens was created (i.e. minted)
    uint256 public totalSupply;

    // here are 2 states: mintable (initial) and transferrable
    bool public releasedForTransfer;

    // Ctor. Hardcodes names in this example
    function Token() public {
        name = "CustomTokenExample";
        symbol = "CTE";
        decimals = 18;
    }

// override these 2 functions to prevent from transferring tokens before it was released

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(releasedForTransfer);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(releasedForTransfer);
        return super.transferFrom(_from, _to, _value);
    }

    // transfer the state from intable to transferrable
    function release() public
        onlyOwner() // only owner can do it
    {
        releasedForTransfer = true;
    }

    // creates new amount of the token from a thin air
    function issue(address _recepient, uint256 _amount) public
        onlyOwner() // only owner can do it
    {
        // the owner can mint until released
        require (!releasedForTransfer);

        // total token supply increases here.
        // Note that the recepient is not able to transfer anything until release() is called
        balances[_recepient] += _amount;
        totalSupply += _amount;
    }
}
```

So we have 18 decimals, `issue` function that allows to issue new tokens, `release` function that
allows to move tokens after crowdsale.

And now let's start doing our crowdsale contract, we will have fixed price, 100 tokens per 1 ETH,
and 100 ETH minimal goal, 1000 ETH hard cap, means our crowdsale is successful if we collect 100 ETH.
If we collect 1000 ETH, crowdsale closed by hard cap.

```cs
pragma solidity 0.4.18;

import 'wings-integration/contracts/BasicCrowdsale.sol';
import './Whitelist.sol';
import './Token.sol';

contract Crowdsale is BasicCrowdsale {
    ...
}
```

Let's add token and whitelist instances:


```cs
Whitelist public whitelist; // initialize whitelist
Token public crowdsaleToken; // initial token

uint256 public price = 100; // price for one ETH

mapping(address => uint256) participants; // list of participants
```

And make constructor:

```cs
function Crowdsale(address _whitelist, address _fundingAddress) BasicCrowdsale(msg.sender, msg.sender) {
    minimalGoal = 100 ether; // minimal goal
    hardCap = 1000 ether; // hard cap

    whitelist = Whitelist(_whitelist); // initialize whitelist by address
    crowdsaleToken = new Token(); // create token

    fundingAddress = _fundingAddress; // address where to withdraw ETH
}
```

So as you see we initialize whitelist by address, because whitelist can be deployed in the past,
and managed not by our crowdsale contract.

In same time token issued by Crowdsale contract, so Crowdsale contract is able to issue new tokens for
participants.

Don't forget about funding address, where you can withdraw ETH later.

Let's do functions that allow to exchange sent ETH to contract to tokens:

```cs
// accept ETH by this contract
function() payable {
    require(msg.value > 0);
    participate(msg.value, msg.sender); // issue tokens
}

function participate(uint256 _value, address _recepient) internal
    hasBeenStarted() hasntStopped() whenCrowdsaleAlive()  // check crowdsale started, hasnt stopped and alive
{
    require(whitelist.isApproved(_recepient)); // check whitelist

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
   uint256 tokensSold = _value * price;

   // create new tokens for this buyer
   crowdsaleToken.issue(_recepient, tokensSold);

   // remember the buyer so he/she/it may refund its ETH if crowdsale failed
   participants[_recepient] += _value;

   // update total ETH collected
   totalCollected += _value;

   // update totel tokens sold
   totalSold += tokensSold;
}
```

See how we added check is participant address whitelisted or no, and in same time see
how important to follow tokensSold, totalCollected to be updated.

In same time it's important to keep state of contracts right, it's possible to participate in
 crowdsale only if crowdsale started, hasnt stopped, and alive (see modifiers for participate function).

And now we miss only few latest functions, indeed:

- Function that allows to get token addfress
- Mint of token rewards to token contracts
- Release token after crowdsale

```cs
// returns address of crowdsale token. The token must be ERC20-compliant
function getToken() public returns(address)
{
    return crowdsaleToken;
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
```

Previous functions more technical and allows to mint token rewards for forecasters, get token
address and allow to release tokens and make them transferable.

**What is important**, is to keep collected ETH on crowfunding contract, to make it possible
to withdraw forecasters rewards (this is done automatically), but even if developer prefer to keep
ETH on another address, and transfer ETH once contract receive it, still possible to deposit contract
with ETH via `deposit` function.

Last few things - withdraw ETH (in case of our contract) and refund (in case of failed crowdsale):

```cs
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
```

In nutshell, we transfer collected ETH to funding address by call `withdraw` function,
in same time.

Refund implemented by `refund` function, that anyone can call if crowdsale stopped or failed.

After all, we are getting integrated crowdsale contract, that can work with Wings smart contracts
ecosystem fine.

Latest thing that we have to do is:

- Deploy crowdsale
- Create project on [Wings Platform](https://wings.ai) and provide address of crowdsale contract
- After forecasting period transfer manager from account you used to deploy crowdsale contract
to DAO contract address (that created by [Wings Platform](https://wings.ai))

More detailed instruction about creation project and other iterations with Platform/UI see on our [blog](https://blog.wings.ai).

## Tests

// TODO: move part of test to current repository

## Contributors

+ [Artem Gorbachev](mailto:artem@wings.ai)
+ [Boris Povod](mailto:boris@wings.ai)

## License

[GPL v3.0 License](LICENSE).

Copyright 2018 © Wings Stiftung. All rights reserved.
