const CustomCrowdsale = artifacts.require('./contracts/example/CustomCrowdsale.sol')
const CustomTokenExample = artifacts.require('./contracts/example/CustomTokenExample.sol')

module.exports = async (deployer) => {
  if (process.env.CROWDSALE) {
    await deployer.deploy(CustomTokenExample)
    const token = await CustomTokenExample.deployed()

    /*
     Params for custom crowdsale:
     uint256 _minimalGoal,
     uint256 _hardCap,
     uint256 _tokensPerEthPrice,
     address _token
     */
    await deployer.deploy(CustomCrowdsale, web3.toWei(1000, 'ether'), web3.toWei(50000, 'ether'), 1000, token.address)
    const crowdsale = await CustomCrowdsale.deployed()

    await token.transferOwnership(crowdsale.address)

    console.log(`===== Contracts ====`)
    console.log(`Crowdsale: ${crowdsale.address}`)
    console.log(`Token: ${token.address}`)
    console.log(`====================`)
  }
};
