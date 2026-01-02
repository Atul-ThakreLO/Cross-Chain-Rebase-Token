// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract BridgeToken is Script {
    /**
     * 
     * @param routerAddress Router address of chain on ccip
     * @param remoteChainSelector Chain selector of chain on ccip
     * @param recieverAddress The address of reciever (EOA mainly).
     * @param tokenToSendAddress Token address.
     * @param amountToSend Amount to send 
     * @param linkTokenAddress Link token address for chains on ccip
     * 
     * @notice We don't need to provide the token pool address explicitly.
     * Token pools are registered in the CCIP Router when configured. The router looks internally for it.
     * Refer Deployer.s.sol and ConfigurePools.s.sol
     */
    function run(
        address routerAddress,
        uint64 remoteChainSelector,
        address recieverAddress,
        address tokenToSendAddress,
        uint256 amountToSend,
        address linkTokenAddress
    ) public {
        vm.startBroadcast();
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSendAddress, amount: amountToSend});
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(recieverAddress),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });
        uint256 ccipFee = IRouterClient(routerAddress).getFee(remoteChainSelector, message);
        IERC20(linkTokenAddress).approve(routerAddress, ccipFee);
        IERC20(tokenToSendAddress).approve(routerAddress, amountToSend);
        /**
         * @notice When ccipSend get call on routerAddress with remote chain selector, router fetch all the required
         * configured data
         */
        IRouterClient(routerAddress).ccipSend(remoteChainSelector, message);
        vm.stopBroadcast();
    }
}
