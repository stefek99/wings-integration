pragma solidity ^0.4.18;
import "./CustomTokenExample.sol";

// Bancor's ISmartToken compatible token example
// See the specs at https://github.com/bancorprotocol/contracts#the-smart-token-standard
contract BancorCompatibleTokenExample is CustomTokenExample {
    // Triggered when a smart token is deployed.
    event NewSmartToken(address _token);

    // Triggered when the total supply is increased.
    event Issuance(uint256 _amount);

    // Triggered when the total supply is decreased.
    event Destruction(uint256 _amount);

    // Ctor.
    function BancorCompatibleTokenExample() public {
        NewSmartToken(address(this));
    }

    // Increases the token supply and sends the new tokens to an account.
    function issue(address _to, uint256 _amount) public {
        super.issue(_to, _amount);
        Issuance(_amount);
    }

    // Removes tokens from an account and decreases the token supply.
    function destroy(address /*_from*/, uint256 /*_amount*/) public {
        // this functionality is not supported by this token
        revert();
    }

    // Disables transfer/transferFrom functionality.
    function disableTransfers(bool _disable) public {
        // in this example, only switching on transfers is acceptable
        // as soon as crowdsale finishes
        require(!_disable);
        super.release();
    }
}
