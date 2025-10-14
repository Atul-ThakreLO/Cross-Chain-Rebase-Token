// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// Core Requirements:
// 1. Store the address of the RebaseToken contract (passed in constructor).
// 2. Implement a deposit function:
//    - Accepts ETH from the user.
//    - Mints RebaseTokens to the user, equivalent to the ETH sent (1:1 peg initially).
// 3. Implement a redeem function:
//    - Burns the user's RebaseTokens.
//    - Sends the corresponding amount of ETH back to the user.
// 4. Implement a mechanism to add ETH rewards to the vault.

pragma solidity ^0.8.19;

// import {RebaseToken} from "./RebaseToke.sol";
import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract Vault {
    ////////////////////////////////////////////////////////////
    ////////////////////////// Error ///////////////////////////
    ////////////////////////////////////////////////////////////

    error Vault__AmountNeedToBeMoreThanZero();
    error Vault__RedeemFailed();

    ////////////////////////////////////////////////////////////
    ///////////////////// State Varibales //////////////////////
    ////////////////////////////////////////////////////////////

    IRebaseToken private immutable i_rebaseToken;

    ////////////////////////////////////////////////////////////
    ////////////////////////// Events //////////////////////////
    ////////////////////////////////////////////////////////////

    event Deposit(address indexed user, uint256 indexed amount);
    event Redeemed(address indexed user, uint256 indexed amount);

    constructor(IRebaseToken _rebaseTokenAddress) {
        i_rebaseToken = _rebaseTokenAddress;
    }

    /**
     * @notice Fallback function to accept ETH rewards sent directly to the contract.
     */
    receive() external payable {}

    /**
     * @notice Allow a user to deposite ETH and recieve an equivalent amount of RebaseToken
     *  @dev The amount of ETH sent with transaction (msg.value) determines the amount of tokens minted.
     * Assumes 1:1 peg for ETH to RebaseToken for simplicity in this version.
     */
    function deposit() public payable {
        // The amount of ETH sent is msg.value
        // The user making the call is msg.sender
        uint256 amountValue = msg.value;
        if (amountValue == 0) {
            revert Vault__AmountNeedToBeMoreThanZero();
        }

        uint256 interestRate = i_rebaseToken.getInterestRate();

        i_rebaseToken.mint(msg.sender, amountValue, interestRate);

        emit Deposit(msg.sender, amountValue);
    }

    /**
     * @notice Alllow user to burn their RebaseToken an recieve corresponding amount of ETH.
     * @param _amount The amount of token need to burn.
     * @dev Follow CEI (Check-Effect-Interaction), uses low level .call for ETH transfer.
     */
    function redeem(uint256 _amount) public {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // Effects
        i_rebaseToken.burn(msg.sender, _amount);

        // Interaction
        (bool success,) = payable(msg.sender).call{value: _amount}("");

        // Checks
        if (!success) {
            revert Vault__RedeemFailed();
        }

        emit Redeemed(msg.sender, _amount);
    }

    /**
     * @notice Gets the address of the RebaseToken contract accosiated with this valut.
     * @return The address of the RebaseToken.
     */
    function getRebaseTokenAddress() public view returns (address) {
        return address(i_rebaseToken);
    }
}
