# Wings Crowdsale Integration

Wings is platform for evaluating and do ICO. Based on Ethereum smart contracts and IPFS.

With Wings any ICO can pass evaluating procedure and launch ICO via Wings ICO constructor
or by writing own crowdsale contract integrated with Wings.

## Overview

## Motivation

## Security

Need to understand, that this is work in progress. Remember that you still work with real money, and any issue can lead to financial losses.
We strongly recommend to cover with tests your integration and implementation of crowdsale contract.

We take no responsibility for your implementation decisions and any security problem you might experience during integration,
even security issues in our smart contracts.

If you reached security issues or any other issues, please, contact us by issues or sending us email: [support@wings.ai](mailto:support@wings.ai), we have generous bounties, read more [here](https://blog.wings.ai).

## Help

## Installation
    

## Getting Started 

Project owner should provide 2 contracts:
+ Token contract that complies to ERC20 specification and does exactly what it’s intended for. Also note that during the crowdfunding process token values should be somewhat produced ("minted" as in the example) or transferred ("sold") to the buyer's account from some special account;
+ Custom `Crowdsale` contract which derives from `BasicCrowdsale` contract (see [BasicCrowdsale.sol](https://github.com/WingsDao/3rd-party-integration/blob/master/BasicCrowdsale.sol))

Example contracts (see [example](https://github.com/WingsDao/3rd-party-integration/tree/master/example) directory):
+ [Custom crowdsale contract](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomCrowdsale.sol);
+ [Token example with minting funciton](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomTokenExample.sol)
+ [Token example which is compatible to Bancor's smart token interface](https://github.com/WingsDao/3rd-party-integration/blob/master/example/BancorCompatibleTokenExample.sol), see specifications for [Bancor protocol](https://github.com/bancorprotocol/contracts#the-smart-token-standard)

During its lifetime, `Crowdsale` contract may reside in the following states:
+ Initial state: crowdsale is not yet started;
+ Active state: when everyone is able to buy project’s tokens;
+ Successful state: when crowdsale succeeded either by achieving hard cap or after crowdsale period ends, but collected value is equal to minimal goal or above;
+ Failed state: when crowdsale period finishes, but minimal goal is not reached *OR* if the project's owner didn't manage to start crowdfunding process during 7 days period after forecasting finished;
+ Stopped by owner: when project’s owners cancels crowdsale for some reason

`Crowdsale` instance is managed by `CrowdsaleController` instance, which is a part of Wings contracts infrastructure.

It’s necessary for custom crowdsale contract to keep in actual state all public fields of [ICrowdsaleProcessor](https://github.com/WingsDao/3rd-party-integration/blob/master/interfaces/ICrowdsaleProcessor.sol) observing the following rules:
+ `totalCollected` and `totalSold` increase during active state;
+ `minimalGoal` and `hardCap` can be changed any number of times before `start()` is called, but not after that;
+ `duration` and timestamps (`startTimestamp` and `endTimestamp`) are set in `start()` function.

For more detailed requirements, see the [custom crowdsale review checklist](https://github.com/WingsDao/3rd-party-integration/blob/master/custom-crowdsale-review-checklist.txt)

## Custom Crowdsale contract specification

Custom crowdsale contract **must** be derived from `BasicCrowdsale` contract which, in turn, is derived from `ICrowdsaleProcessor` which, in turn, is derived from `Ownable` (from zeppelin-solidity library) and `HasManager` contracts.

**Difference between owner and manager:** Owner is typically the address of contract creator's account, manager is the address of the contract to which some acrtions are delegated. So effectively crowdsale contracts have 2 owners with different access rights.

`BasicCrowdsale` ([see src](https://github.com/WingsDao/3rd-party-integration/blob/master/BasicCrowdsale.sol)) implements default behavior of custom crowdsale, but BasicCrowdsale.start(...) and BasicCrowdsale.stop() functions **must** be called (via `super` mechanism) if appropriate methods are overriden in derived contracts.

### Ownable fields

**owner**
```cs
address public owner;
```
Owner's address. Allows to make certain methods callbable by owner only (via `onlyOwner` modifier)
<br>
<br>
<br>

### HasManager fields

**manager**
```cs
address public manager;
```
Manager's address. Allows to make certain methods callbable by manager only (via `onlyManager` modifier)
<br>
<br>
<br>

### ICrowdsaleProcessor fields

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

### Ownable methods

**transferOwnership**
```cs
function transferOwnership(address newOwner) public onlyOwner;
```
Allows the current owner to transfer control of the contract to a newOwner.
<br>
<br>
<br>

### HasManager methods

**transferManager**
```cs
function transferManager(address _newManager) public onlyManager();
```
New manager transfers its functions to new address.
<br>
<br>
<br>

### ICrowdsaleProcessor methods

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

## Examples

## Developers

+ [Artem Gorbachev](mailto:artem@wings.ai)
+ [Boris Povod](mailto:boris@wings.ai)

## License

[GPL v3.0 License](LICENSE).

Copyright 2018 © Wings Stiftung. All rights reserved.