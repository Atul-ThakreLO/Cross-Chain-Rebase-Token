// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IRebaseToken {
    /**
     * @notice Mints the token
     * @param _to Address to mint token.
     * @param _amount Amount of token to mint.
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns the token from specified address.
     * @param _from The Address from burn token
     * @param _amount Amount of token to burn.
     */
    function burn(address _from, uint256 _amount) external;

    function balanceOf(address _user)  external view returns (uint256);
}