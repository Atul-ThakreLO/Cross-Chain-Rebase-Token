// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
// import {CCIPLocalSimulatorFork} from "chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {CCIPLocalSimulatorFork, Register} from "chainlink-local/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CrossChainTest is Test {
    ////////////////////////////////////////////////////////////
    ///////////////////// State Variables //////////////////////
    ////////////////////////////////////////////////////////////
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;
    Vault vault;

    RebaseTokenPool sepoliaTokenPool;
    RebaseTokenPool arbSepoliaTokenPool;
    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    uint256 constant SEND_AMOUNT = 1e5;

    ////////////////////////////////////////////////////////////
    ///////////////////// SetUp Functions //////////////////////
    ////////////////////////////////////////////////////////////
    function setUp() public {
        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

        sepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();

        // This is crucial so both the Sepolia and Arbitrum Sepolia forks
        // can interact with the *same* instance of the simulator.
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // 1. Deploy token on sepolia.
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaTokenPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            new address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        sepoliaToken.grantMintAndBurnAccess(address(sepoliaTokenPool));
        sepoliaToken.grantMintAndBurnAccess(address(vault));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(sepoliaToken)
        );
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(sepoliaToken), address(sepoliaTokenPool)
        );
        vm.stopPrank();

        // 2. Deploy on arbitrum.
        vm.selectFork(arbSepoliaFork);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken();
        arbSepoliaTokenPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)),
            new address[](0),
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress
        );
        arbSepoliaToken.grantMintAndBurnAccess(address(arbSepoliaTokenPool));
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(arbSepoliaToken)
        );
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(arbSepoliaToken), address(arbSepoliaTokenPool)
        );

        configureTokenPool(
            sepoliaFork,
            address(sepoliaTokenPool),
            arbSepoliaNetworkDetails.chainSelector,
            address(arbSepoliaTokenPool),
            address(arbSepoliaToken)
        );
        configureTokenPool(
            arbSepoliaFork,
            address(arbSepoliaTokenPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaTokenPool),
            address(sepoliaToken)
        );
        vm.stopPrank();
    }

    function configureTokenPool(
        uint256 forkId,
        address localPoolAddress,
        uint64 remoteChainSelector,
        address remotePoolAddress,
        address remoteTokenAddress
    ) public {
        vm.selectFork(forkId);
        vm.startPrank(owner);
        uint64[] memory remoteChainSelectorToRemove = new uint64[](0);

        TokenPool.ChainUpdate[] memory chainToAdd = new TokenPool.ChainUpdate[](1);

        bytes[] memory remotePoolAddressesBytesArray = new bytes[](1);
        remotePoolAddressesBytesArray[0] = abi.encode(remotePoolAddress);

        chainToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: remotePoolAddressesBytesArray,
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });

        TokenPool(localPoolAddress).applyChainUpdates(remoteChainSelectorToRemove, chainToAdd);
        vm.stopPrank();
    }

    function bridgeToken(
        uint256 amountTobridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory loaclNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        RebaseToken loaclToken,
        RebaseToken remoteToken
    ) public {
        vm.selectFork(localFork);

        // 1. Initialize tokenAmounts array
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(loaclToken), amount: amountTobridge});

        // 2. Construct the EVM2AnyMessage
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: loaclNetworkDetails.linkAddress, // LInk Token address use, address(0) for native token.
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV2({gasLimit: 200_000, allowOutOfOrderExecution: false}) // This will set default gass limit
            )
        });

        // 3. Get the CCIP fee
        uint256 fees =
            IRouterClient(loaclNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message);

        // 4. Fund the user with LINK (for testing via CCIPLocalSimulatorFork)
        // This step is specific to the local simulator
        ccipLocalSimulatorFork.requestLinkFromFaucet(user, fees);

        // 5. Approve LINK for the Router
        vm.prank(user);
        IERC20(loaclNetworkDetails.linkAddress).approve(loaclNetworkDetails.routerAddress, fees);

        // 6. Approve the actual token to be bridged
        vm.prank(user);
        IERC20(address(loaclToken)).approve(loaclNetworkDetails.routerAddress, amountTobridge);

        // 7. Get user's balance on the local chain BEFORE sending
        uint256 localBalanceBefore = loaclToken.balanceOf(user);

        // 8. Send the CCIP message
        /// @notice Here we haven't use {msg.value} because we are using Link token, if we are using native token to pay the we must use {msg.value}
        vm.prank(user);
        IRouterClient(loaclNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message);

        // 9. Get the user's balance on the local change After sending and assert
        uint256 localBalanceAfter = loaclToken.balanceOf(user);
        assertEq(localBalanceAfter, localBalanceBefore - amountTobridge);

        // Change Fork
        vm.selectFork(remoteFork);

        // 10. Simulate message propagation to the remote chain
        vm.warp(block.timestamp + 20 minutes);

        // 11. Get the user's balance on the remote chain Before messag processing
        uint256 remoteBalanceBefore = remoteToken.balanceOf(user);

        vm.selectFork(localFork);

        // 12. Proccess the message on the remote chain
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);

        // 13. Get the user's balance on remote chain After message processing
        uint256 remoteBlanaceAfter = remoteToken.balanceOf(user);

        assertEq(remoteBlanaceAfter, remoteBalanceBefore + amountTobridge);

        // 14. Check interest rates (specific to RebaseToken logic)
        vm.selectFork(localFork);
        uint256 localUserInterestRate = loaclToken.getUserInterestRate(user);

        vm.selectFork(remoteFork);
        uint256 remoteUserInterestRate = remoteToken.getUserInterestRate(user);

        assertEq(localUserInterestRate, remoteUserInterestRate);
    }

    ////////////////////////////////////////////////////////////
    ////////////////////////// Tests ///////////////////////////
    ////////////////////////////////////////////////////////////

    function testBridgeAllToken() public {
        vm.selectFork(sepoliaFork);
        vm.deal(user, SEND_AMOUNT);
        vm.prank(user);
        Vault(payable(address(vault))).deposit{value: SEND_AMOUNT}();
        assertEq(sepoliaToken.balanceOf(user), SEND_AMOUNT);
        bridgeToken(
            SEND_AMOUNT,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaToken,
            arbSepoliaToken
        );

        vm.selectFork(arbSepoliaFork);
        vm.warp(block.timestamp + 20 minutes);
        uint256 balanceOnArb = arbSepoliaToken.balanceOf(user);
        bridgeToken(
            balanceOnArb,
            arbSepoliaFork,
            sepoliaFork,
            arbSepoliaNetworkDetails,
            sepoliaNetworkDetails,
            arbSepoliaToken,
            sepoliaToken
        );
    }
}
