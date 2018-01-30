# Custom Crowdsale Contract Creation Guide

### Overview

Project owner should provide 2 contracts:
+ Token contract that complies to ERC20 specification and does exactly what it’s intended for;
+ Custom `Crowdsale` contract which derives from `BasicCrowdsale` contract (see [BasicCrowdsale.sol](https://github.com/WingsDao/3rd-party-integration/blob/master/BasicCrowdsale.sol))

Example contracts (see [example](https://github.com/WingsDao/3rd-party-integration/tree/master/example) directory):
+ [Custom crowdsale contract](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomCrowdsale.sol);
+ [Token example with minting funciton](https://github.com/WingsDao/3rd-party-integration/blob/master/example/CustomTokenExample.sol)

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

### Dependencies

+ [zeppelin-solidity](https://github.com/OpenZeppelin/zeppelin-solidity), also available via `npm`:

    `npm install zeppelin-solidity`

### License

Apache v2 license.

Copyright 2017 © Wings Stiftung. All rights reserved.
