// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TokenPool} from "ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract ConfigurePool is Script {
    function run(
        address localPool,
        uint64 remoteChainSelector,
        address remotePool,
        address remoteToken,
        bool isEnabledOutboundRateLimiter,
        uint128 outboundRateLimiterCapacity,
        uint128 outboundRateLimiterRate,
        bool isEnabledInboundRateLimiter,
        uint128 inboundRateLimiterCapacity,
        uint128 inboundRateLimiterRate
    ) public {
        bytes[] memory remotePoolAddresses = new bytes[](0);

        RateLimiter.Config memory outboundRateLimiterConfig = RateLimiter.Config({
            isEnabled: isEnabledOutboundRateLimiter,
            capacity: outboundRateLimiterCapacity,
            rate: outboundRateLimiterRate
        });

        RateLimiter.Config memory inboundRateLimiterConfig = RateLimiter.Config({
            isEnabled: isEnabledInboundRateLimiter,
            capacity: inboundRateLimiterCapacity,
            rate: inboundRateLimiterRate
        });

        remotePoolAddresses[0] = abi.encode(remotePool);
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);

        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig: outboundRateLimiterConfig,
            inboundRateLimiterConfig: inboundRateLimiterConfig
        });

        TokenPool(localPool).applyChainUpdates(new uint64[](0), chainsToAdd);
    }
}

// struct ChainUpdate {
//     uint64 remoteChainSelector; // Remote chain selector
//     bytes[] remotePoolAddresses; // Address of the remote pool, ABI encoded in the case of a remote EVM chain.
//     bytes remoteTokenAddress; // Address of the remote token, ABI encoded in the case of a remote EVM chain.
//     RateLimiter.Config outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
//     RateLimiter.Config inboundRateLimiterConfig; // Inbound rate limited config, meaning the rate limits for all of the offRamps for the given chain
//}
