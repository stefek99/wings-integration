### Intro

In this tutorial we will integrate WINGS forecasting into OpenZeppelin crowdsale.

You may want to check [first tutorial](https://github.com/stefek99/wings-integration/blob/master/tutorial/) from this series, integrating WINGS into the crowdsale.

It explains many fundamental concepts, here we proceed directly to slightly more advanced stuff. So if you are in doubt I invite you to check [part one](https://github.com/stefek99/wings-integration/blob/master/tutorial/) first.

Some of the code here is based great tutorial on how to deploy [ICO with Open Zeppelin](https://blog.zeppelin.solutions/how-to-create-token-and-initial-coin-offering-contracts-using-truffle-openzeppelin-1b7a5dae99b6). Full credit to Gustavo (Gus) Guimaraes who created great tutorial and keeps updating it as `OpenZeppelin` releases new version of their framework. We will not reinvent the wheel, we will base some of our code on top of his tutorial. 


### Note about OpenZeppelin

Description from their website:

> OpenZeppelin is an open framework of reusable and secure smart contracts in the Solidity language.

They have fantastic developer commufnity and many smart contracts are using their code.

Their code is well tested, frequently updated, neatly organized and the ICO contract out-of-the-box supports many common use cases. In other words - cannot recommend OpenZeppelin highly enough. That is why we are using their code internally at WINGS, that is this tutorial is using `OpenZeppelin` too.


### Downloading WINGS integration code

There are a few ways of getting WINGS code in place, personally I prefer copy-paste directly from GitHub repository as there are currently only 2 files:

* [`ICrowdsaleProcessor.sol`](https://github.com/WingsDao/wings-integration/blob/master/contracts/interfaces/ICrowdsaleProcessor.sol)
* [`BasicCrowdsale.sol`](https://github.com/WingsDao/wings-integration/blob/master/contracts/BasicCrowdsale.sol) 

Another options is to:

1. Clone GitHub repository: https://github.com/WingsDao/wings-integration

`git clone https://github.com/WingsDao/wings-integration`

2. Install from `npm`: https://www.npmjs.com/package/wings-integration

`npm i wings-integration`

It's just a matter of preference and convenience. No enforcement here, whatever works for you best.


### Tool we will use

In the [previous tutorial](https://github.com/stefek99/wings-integration/blob/master/tutorial/) we didn't use Truffle. Instead we were deploying directly from RemixIDE.

This time around we will use Truffle as well as [`ganache-cli`](https://github.com/trufflesuite/ganache-cli) successor of the `testrpc`/



```
npm install -g ganache-cli
npm install -g truffle
```

The `-g` paramenter means to install the package globally, so that the newly installed packages are available from the command line.  

Let's start with initialising empty `Truffle` project.

```
mkdir wings-openzeppelin
cd wings-openzeppelin
truffle init
```

Then we will add `OpenZeppelin` and `WingsIntegration` npm modules:

`npm install zeppelin-solidity@1.7.0 wings-integration`

From here we can proceed to create our token in `contracts/OurCoin.sol`:

```
pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/PausableToken.sol';

contract OurCoin is MintableToken, PausableToken {
    string public name = "OUR COIN";
    string public symbol = "OUR";
    uint8 public decimals = 18;
}
```

Note that we are using some `OpenZeppelin` conventions that will make our integration smooth.

Now we have a token, lets now can create `contracts/OurCrowdsale.sol`:

```
pragma solidity ^0.4.19;

import './OurCoin.sol';
import 'zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol';
import 'wings-integration/contracts/BasicCrowdsale.sol';


contract OurCrowdsale is MintedCrowdsale, BasicCrowdsale {

  event SELL(uint256 start, uint256 end, uint256 now, uint256 tokens);

  mapping(address => uint256) participants; // keeping in track in case refund is needed
  OurCoin ourCoin;

    function OurCrowdsale(uint256 _minimalGoal, uint256 _hardCap, uint256 _rate, address _wallet, OurCoin _ourCoin)
        public Crowdsale(_rate, _wallet, _ourCoin) BasicCrowdsale(msg.sender, msg.sender) {
        minimalGoal = _minimalGoal;
        hardCap = _hardCap;
        ourCoin = _ourCoin;
        }

  function getToken() public returns(address) {
    return address(ourCoin);
  }

  // called by CrowdsaleController to transfer reward part of
  // tokens sold by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process.
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager()  {
    ourCoin.mint(_contract, _amount); // crowdsale token is mintable in this example, tokens are created here
  }

  // transfers crowdsale token from mintable to transferrable state
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful() {
    ourCoin.unpause();
  }

  // DEFAULT FUNCTION - allows for ETH transfers to the contract
  function () external payable {
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
    uint256 tokensSold = _value * rate;

    SELL(startTimestamp, endTimestamp, now, tokensSold);

    // create new tokens for this buyer
    ourCoin.mint(_recepient, tokensSold);

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
```

We are deriving our code from [`BasicCrowdsale.sol`](https://github.com/WingsDao/wings-integration/blob/master/contracts/BasicCrowdsale.sol) that in turns derives from [`ICrowdsaleProcessor.sol`](https://github.com/WingsDao/wings-integration/blob/master/contracts/interfaces/ICrowdsaleProcessor.sol) - we are implementing all the required methods.



### Deployment

We need to configure `truffle.js` file:

```
module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        }
    }
};
```

Because we are using `Truffle` we also need to specify the `migrations/2_deploy_contracts.js`:


```
const OurCrowdsale = artifacts.require('./OurCrowdsale.sol');
const OurCoin = artifacts.require('./OurCoin.sol');

module.exports = function(deployer, network, accounts) {
    let openingTime;
    if (network === "ropsten") { // when deploying to Ropsten: Web3ProviderEngine does not support synchronous requests
        openingTime = Math.ceil(new Date() / 1000); // using JavaScript timestamp, removing milliseconds and converting to integer
    } else {
        openingTime = web3.eth.getBlock('latest').timestamp;
    }

    const closingTime = openingTime + 86400 * 20; // 20 days    

    const rate = new web3.BigNumber(1000);
    const minimalGoal = new web3.BigNumber(web3.toWei(10, "ether"));
    const hardCap  = new web3.BigNumber(web3.toWei(100 , "ether"));
    const wallet = accounts[0];

    return deployer
        .then(() => {
            return deployer.deploy(OurCoin);
        })
        .then(() => {
            return deployer.deploy(
                OurCrowdsale,
                minimalGoal,
                hardCap,
                rate,
                wallet,
                OurCoin.address
            );
        }).then(() => {

            // TODO: transfer ownerhship of the token to the crowdsale for minting
            // Currently doing that in the UI

        });
};
```


If you were paying close attention to the `Crowdsale` code, you'd notice that every time we send ETH we mint new tokens `crowdsaleToken.mint(_recepient, tokensSold);`

That function has `onlyOwner` modifier, [here](https://ethereum.stackexchange.com/questions/34184/transfer-ownership-of-a-token-contract) and [here](https://ethereum.stackexchange.com/questions/44148/ive-transferred-ownership-of-my-token-to-my-crowdsale-how-do-i-transfer-it-bac) are two StackOverflow questions explaining why transfer of the owner is required.

### General word of caution

With crowdsale contracts there is usually serious money on the line.

Hire professional code auditors - not only you'll save yourself sleepless nights but also show to your potential investors that you are serious about security

#### Extra caution

In the Ethereum world we are working with accounts, contracts, adresses. You need to know what all these mean:

* `onlyOwner`
* `onlyManager`
* `contribution wallet`

Just be aware of the differences, in some cases it will be the same address, in some cases don't.

#### Overriding `OpenZeppelin` 

We are overriding some of the functions derived from `OpenZeppelin` - again be extra cautious here. 

Ensure everything works as expected.

This is an early version of this tutorial and there might be some glitches here or there. 


### Testing

Automated tests are very important to prove that code works as desired. 

Let's start with some basic tests in place, let's put the following code to `test/OurCrowdsale.test.js`:

```
var OurCrowdsale = artifacts.require("./OurCrowdsale.sol");
var OurCoin = artifacts.require("./OurCoin.sol");

contract('OurCrowdsale (default constructor)', function(accounts) {

    it('owner should be assigned to the first account', async function () {
      var crowdsale = await OurCrowdsale.deployed();
      var owner = await crowdsale.owner();
      assert.equal(owner, accounts[0]);
    })    

    it('manager should be assigned to the first account', async function () {
      var crowdsale = await OurCrowdsale.deployed();
      var manager = await crowdsale.manager();
      assert.equal(manager, accounts[0]);
    })
 
});
```

In order to run it: `truffle test`

That should be a success, we made sure that `owner` and `manager` is set up properly.

Solidity, Truffle, Ethereum ecosystem in general is still in early days and there are many rough endges here or there. In order to provide parameters to the constructor we can use the following syntax:

```
contract('OurCrowdsale (custom constructor)', function(accounts) {

    const openingTime = 1522697922;
    const closingTime = 1722697922;

    const rate = new web3.BigNumber(1000);
    const minimalGoal = new web3.BigNumber(web3.toWei(10, "ether"));
    const hardCap  = new web3.BigNumber(web3.toWei(100 , "ether"));
    const wallet = "0x315f80C7cAaCBE7Fb1c14E65A634db89A33A9637";

  beforeEach(async function () {
    this.token = await OurCoin.new();
    this.crowdsale = await OurCrowdsale.new(minimalGoal, hardCap, rate, wallet, this.token.address);
    this.token.transferOwnership(this.crowdsale.address);
  });

  it('owner should be assigned to the first account', async function () {
      var owner = await this.crowdsale.owner();
      assert.equal(owner, accounts[0]);
    });

    it('should be able to get token address', async function () {
      var tokenAddress = await this.crowdsale.getToken.call(); // https://ethereum.stackexchange.com/questions/16796/truffle-console-how-can-i-get-and-print-the-value-returned-by-a-contract-funct
      assert.equal(this.token.address, tokenAddress);
    });

    // https://ethereum.stackexchange.com/questions/9103/how-can-you-handle-an-expected-throw-in-a-contract-test-using-truffle-and-ethere
    // https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/test/helpers/expectThrow.js
    it('initially it should NOT be possible to send funds', async function() {
      try {
        await this.crowdsale.sendTransaction({ value: 1e+18, from: accounts[1] });
        assert.fail('Expected throw');
      } catch (error) {

      }
    })    

    it('after calling START it is possible to send funds', async function() {

      var start = web3.eth.getBlock('latest').timestamp
      var end = start + (5 * 24 * 60 * 60);

      await this.crowdsale.start(start, end, accounts[0])
      var isActive = await this.crowdsale.isActive.call();
      assert.equal(isActive, true);


      await this.crowdsale.sendTransaction({ value: 1e+18, from: accounts[1] });
      var balance = await this.token.balanceOf.call(accounts[1]);
      assert.equal(balance.toNumber(), 1000 * 1e+18); // it's a BigNumber (need to convert it) also Wei decimals
    });

});
```

### Debugging tests

This is a great [Stack Overflow resource](https://ethereum.stackexchange.com/questions/41094/debugging-js-unit-tests-with-truffle-framework-in-vs-code/43633#43633) showing how to interactively debug your tests.

It's very similar to JavaScript and node.JS debugging.

```
npm install truffle-core
node --inspect-brk ./node_modules/truffle-core/cli.js test test/OurCrowdsale.test.js
```

Initially I've experienced troubles findind my test files in the debbugger window so put `debugger` statement in the code to trigger a breakpoint.

![](https://raw.githubusercontent.com/stefek99/wings-integration/master/tutorial-zeppelin/images/truffle-debugger.png?raw=true)

In that way I was able to pause the execution fo the tests and observe what's going on.


### Deployment to Ropsten (testnet)

Normally you would have install `geth` and synchronize your node. Luckily there are some options here, namely `--fast --light --warp` options or just skipping the install entirely. Ability to get up and running quickly is essential to adoption. I travel often *(slow WiFi
)* and my SSD storage is limited - in this tutorial we will use Infura.

No do not need to have full node - we can use [Infura](https://infura.io). Infura is backend for Metamastk.

* https://ethereum.stackexchange.com/questions/13362/to-which-remote-ethereum-nodes-does-metamask-plugin-send-signed-transactions-an
* http://truffleframework.com/tutorials/using-infura-custom-provider
* https://github.com/trufflesuite/truffle-hdwallet-provider


```npm install truffle-hdwallet-provider```

Now we should update out `truffle.js` file:

```
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = require("./truffle-mnemonic");

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        ropsten: {
        provider: function() {
            return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/IbQH5ooOmgXLEhyn35yR", 1) // second one
        },
        network_id: 3,
        gas: 4700000
      }   
    }
};
```

Once we have that we can run:

`truffle migrate --network ropsten`


#### Note about private keys in code

This is tutorial. Using `testnet`. It means that this Ether has absolutely no value and is here for testing purposes.

![](https://raw.githubusercontent.com/stefek99/wings-integration/master/tutorial-zeppelin/images/truffle-warning.png?raw=true)

*(helpful warning from `Truffle` code)*


If you committed file locally, it's not too late, see this Github aricle on [removing sensitive data from a repository](https://help.github.com/articles/removing-sensitive-data-from-a-repository/). If you pushed to the internet it's most likely too late and you better stay on the safe side and treat the private key as compromised.

In order to avoid comitting sensitive data to the code, create `.gitignore` file we add it so that our private keys are not exposed to the world:

```
node-modules
truffle-mnemonic.js
```

Here is my `trufle-mnemonic.js` file. It contains the 12 words mnemonic:

`module.exports = "satoshi _____ _____ _____ _____ ______ love"`




#### What the hell are Truffle migrations

When you look at the Etherscan transaction log you'll notice many contracts being deployed.

https://medium.com/@blockchain101/demystifying-truffle-migrate-21afbcdf3264

![](https://raw.githubusercontent.com/stefek99/wings-integration/master/tutorial-zeppelin/images/openzeppelin-truffle-migrations.png?raw=true)


### Verification on Etherscan

Copy all the files into a single file.

There is a great tool called `truffle-flattener` *(`npm install -g` it)* that concatenas project files. It's handy when working with Remix *(online IDE used in previous tutorial)* as well as Etherscan verification.


### WINGS user interface

Refer to [previous tutorial](https://github.com/stefek99/wings-integration/tree/master/tutorial)


### WINGS best practices

After forecasting period ends you have 45 days to initiate the crowdsale. You can learn more on our wiki:
* [Project Creator Guide](https://wiki.wings.ai/display/WIKI/Tips+to+attract+more+users)
* [Tips to attract more users](https://wiki.wings.ai/display/WIKI/Tips+to+attract+more+users)

### Summary

`OpenZeppelin` is powerful and well established set of smart contract that faciliates development. We've added `WingsIntegration` and then used `Truffle` to write some tests and finally deploy the contract using `Infura` node - that's a lot of new technologies in a single tutorial.

If there are any discrepancies, rough edges, areas to improve - go ahead and [open an issue on Github](https://github.com/WingsDao/wings-integration/issues), join our community [Telegram chat](https://telegram.me/wingschat), tweet me [@michalstefanow](https://twitter.com/michalstefanow) or contact me directly michal@wings.ai or call `+44 758 629 4279` *(my phone number is already public anyway)*
