// SPDX-Licnese-Identifier: MIT

pragma solidity ^0.8.19;

contract HelperConfig {

    error HelperConfig__ChainNotSupported();

    uint256 internal CHAIN_ID;

    struct NetworkConfig {
        address routerAddress;
        address linkTokenAddress;
        address rmnProxyAddress;
        address tokenAdminRegistryAddress;
        address registryModuleOwnerCustomAddress;
        uint64 chainSelector;
    }

    // Ethereum Sepolia
    uint256 constant public SEPOLIA_CHAIN_ID = 11155111;
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    // Arbitrum Sepolia
    uint256 constant public ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint64 constant ARBITRUM_SEPOLIA_CHAIN_SELECTOR = 3478487238524512106;

    // Base Sepolia
    uint256 constant public BASE_SEPOLIA_CHAIN_ID = 84532;
    uint64 constant BASE_SEPOLIA_CHAIN_SELECTOR = 10344971235874465080;


    constructor() {
        CHAIN_ID = block.chainid;
    }


    function getConfig() public view returns(NetworkConfig memory) {
        if(CHAIN_ID == SEPOLIA_CHAIN_ID) {
            return getSepoliaNetworkConfig();
        } else if (CHAIN_ID == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return getArbitrumNetworkConfig();
        } else if (CHAIN_ID == BASE_SEPOLIA_CHAIN_ID) {
            return getBaseNetworkConfig();
        } else {
            revert HelperConfig__ChainNotSupported();
        }
    }


    function getArbitrumNetworkConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
            linkTokenAddress: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            rmnProxyAddress: 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
            tokenAdminRegistryAddress: 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f,
            registryModuleOwnerCustomAddress: 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69,
            chainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR
        });
    }

    function getSepoliaNetworkConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            rmnProxyAddress: 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
            tokenAdminRegistryAddress: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
            registryModuleOwnerCustomAddress: 0x62e731218d0D47305aba2BE3751E7EE9E5520790,
            chainSelector: SEPOLIA_CHAIN_SELECTOR
        });
    }

    function getBaseNetworkConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            linkTokenAddress:0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            rmnProxyAddress: 0x99360767a4705f68CcCb9533195B761648d6d807,
            tokenAdminRegistryAddress: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
            registryModuleOwnerCustomAddress: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe,
            chainSelector: BASE_SEPOLIA_CHAIN_SELECTOR
        });
    }
}