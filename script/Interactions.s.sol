// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

contract Deposit is Script {
    function deposit(address vaultAddress, uint256 amountToDeposit) public payable {
        Vault(payable(vaultAddress)).deposit{value: amountToDeposit}();
    }

    function run(address vaultAddress, uint256 amountToDeposit) external payable {
        vm.startBroadcast();
        deposit(vaultAddress, amountToDeposit);
        vm.stopBroadcast();
    }
}

contract Redeem is Script {
    function redeem(address vaultAddress, uint256 amountToRedeem) public {
        Vault(payable(vaultAddress)).redeem(amountToRedeem);
    }

    function run(address vaultAddress, uint256 amountToRedeem) public {
        vm.startBroadcast();
        redeem(vaultAddress, amountToRedeem);
        vm.stopBroadcast();
    }
}
