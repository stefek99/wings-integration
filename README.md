# Wings Crowdsale Integration

Wings is platform for evaluating and do ICO. Based on Ethereum smart contracts and IPFS.

With Wings any ICO can pass evaluating procedure and launch ICO via Wings ICO constructor
or by writing own crowdsale contract integrated with Wings.

To get more details read our [whitepaper](https://wingsfoundation.ch/docs/WINGS_Whitepaper_V1.1.2_en.pdf), visit [site](https://wings.ai), or join our [chat](https://telegram.me/wingschat) to talk.

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

For more detailed requirements, see the [custom crowdsale review checklist](https://github.com/WingsDao/3rd-party-integration/blob/master/custom-crowdsale-review-checklist.txt):

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
**token**
```cs
function token() public returns(address);
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

##ß Step By Step

## Tests

To launch tests put:

    npm test

## Contributors

+ [Artem Gorbachev](mailto:artem@wings.ai)
+ [Boris Povod](mailto:boris@wings.ai)

## License

[GPL v3.0 License](LICENSE).

Copyright 2018 © Wings Stiftung. All rights reserved.