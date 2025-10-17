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

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TokenPool} from "../lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";

/**
 * @title Rebase Token
 * @author Atul Thakre
 * @notice This is Rebase Token
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    ////////////////////////////////////////////////////////////
    ////////////////////////// Errors //////////////////////////
    ////////////////////////////////////////////////////////////
    error ReabaseToken__InterestCanOnlyBeDecrease(uint256 newRate, uint256 oldRate);

    ////////////////////////////////////////////////////////////
    ///////////////////// State Variables //////////////////////
    ////////////////////////////////////////////////////////////
    uint256 private constant PRICISION_FACTOR = 1e18;
    bytes32 private constant MINT_BURN_ACCESS = keccak256("MINT_BURN_ACCESS");
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    ////////////////////////////////////////////////////////////
    ////////////////////////// Events //////////////////////////
    ////////////////////////////////////////////////////////////
    event InterestRateSet(uint256 indexed newInterestRate);

    ////////////////////////////////////////////////////////////
    //////////////////////// Functions /////////////////////////
    ////////////////////////////////////////////////////////////

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnAccess(address _account) public onlyOwner {
        _grantRole(MINT_BURN_ACCESS, _account);
    }

    function setInterestRate(uint256 _newInterestRate) public onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert ReabaseToken__InterestCanOnlyBeDecrease(_newInterestRate, s_interestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_BURN_ACCESS) {
        _mintAccuredInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(MINT_BURN_ACCESS) {
        // if (_amount == type(uint256).max) {
        //     _amount = balanceOf(_from);
        //     console.log("inside amount", _amount);
        // }
        _mintAccuredInterest(_from);
        _burn(_from, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestsSinceLastUpdated(_user)) / PRICISION_FACTOR;
    }

    /**
     * @notice Transfers tokens from the caller to a recipient.
     * Accrued interest for both sender and recipient is minted before the transfer.
     * If the recipient is new, they inherit the sender's interest rate.
     * @param _recipient The address to transfer tokens to.
     * @param _amount The amount of tokens to transfer. Can be type(uint256).max to transfer full balance.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(msg.sender);
        _mintAccuredInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        // We use balanceOf here to check the effective balance including any just-minted interest.
        // If _mintAccruedInterest made their balance non-zero, but they had 0 principle, this still means they are "new" for rate setting.
        // A more robust check for "newness" for rate setting might be super.balanceOf(_recipient) == 0 before any interest minting for the recipient.
        // However, the current logic is: if their *effective* balance is 0 before the main transfer part, they get the sender's rate.
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfers tokens from one address to another, on behalf of the sender,
     * provided an allowance is in place.
     * Accrued interest for both sender and recipient is minted before the transfer.
     * If the recipient is new, they inherit the sender's interest rate.
     * @param _sender The address to transfer tokens from.
     * @param _recipient The address to transfer tokens to.
     * @param _amount The amount of tokens to transfer. Can be type(uint256).max to transfer full balance.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(_sender);
        _mintAccuredInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Gets the principle balance of a user (tokens actually minted to them), excluding any accrued interest.
     * @param _user The address of the user.
     * @return The principle balance of the user.
     */
    function principleBalanceOf(address _user) public view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @param _user The address of user whose interest is minting.
     * @dev This function is going to mint the Accured Interest.
     * @dev calculate rebase token -> principle amount, then calculate total balance with interest and get
     * interest of user and mint rebase token from interest.
     */
    function _mintAccuredInterest(address _user) internal {
        // Previous Balance
        uint256 previousBalance = super.balanceOf(_user);
        // Balance Including the Interest
        uint256 balanceIncludingInterest = balanceOf(_user);

        uint256 interestTokenToMint = balanceIncludingInterest - previousBalance;
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, interestTokenToMint);
    }

    /**
     *
     * @param _user The address of user
     * @notice So we set s_interestRate = 5e10 as we not deal with decimals so if divide it with 1e18, will gate
     * $0.00000005 -> in percents $0.000005
     * (principle amount * interest rate * timeElapsed) /
     */
    function _calculateUserAccumulatedInterestsSinceLastUpdated(address _user)
        internal
        view
        returns (uint256 lineraInterest)
    {
        // If user has never been updated, no interest has accrued
        // if (s_userLastUpdatedTimestamp[_user] == 0) {
        //     return PRICISION_FACTOR;
        // }
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        lineraInterest = PRICISION_FACTOR + (timeElapsed * s_userInterestRate[_user]);
    }

    ////////////////////////////////////////////////////////////
    ///////////////////////// Getters //////////////////////////
    ////////////////////////////////////////////////////////////

    function getUserInterestRate(address _user) public view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /**
     * @notice Gets the current global interest rate for the token.
     * @return The current global interest rate.
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
