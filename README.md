# Cross-Chain Rebase Token

A Solidity-based rebase token with cross-chain capabilities using Chainlink CCIP (Cross-Chain Interoperability Protocol). This project implements an interest-bearing token that automatically accrues value over time and can be transferred across different blockchain networks.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Smart Contracts](#smart-contracts)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security Considerations](#security-considerations)
- [License](#license)

## 🎯 Overview

The Cross-Chain Rebase Token is a decentralized, crypto-collateralized token that automatically increases in value over time through a linear interest mechanism. Built with Foundry and leveraging Chainlink's CCIP technology, it enables seamless cross-chain transfers while preserving user-specific interest rates.

**Token Characteristics:**

- **Type**: Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized
- **Volatility**: Low
- **Collateral**: ETH (1:1 peg)
- **Interest Model**: Linear time-based accrual

## ✨ Features

### Core Functionality

- **Linear Interest Accrual**: Tokens automatically increase in value based on time elapsed and user-specific interest rates
- **ETH-Backed Vault**: Deposit ETH to mint tokens and redeem tokens for ETH
- **Dynamic Interest Rates**: Owner can adjust global interest rates (can only decrease for stability)
- **User-Specific Rates**: Each user maintains their own interest rate, inherited on first transfer
- **Access Control**: Role-based minting and burning permissions

### Cross-Chain Capabilities

- **Chainlink CCIP Integration**: Secure cross-chain token transfers
- **Interest Rate Preservation**: User interest rates are maintained across chains
- **Token Pool Architecture**: Custom pool implementation for lock/burn and release/mint mechanisms

### Security Features

- **OpenZeppelin Contracts**: Built on battle-tested ERC20, Ownable, and AccessControl implementations
- **Principle Balance Tracking**: Separate tracking of base balance vs. accrued interest
- **Comprehensive Testing**: Fuzz testing with Foundry

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Chain A                                  │
│  ┌─────────────┐      ┌──────────────┐                     │
│  │   Vault     │──────│ RebaseToken  │                     │
│  └─────────────┘      └──────────────┘                     │
│         │                     │                             │
│         │                     │                             │
│         └─────────────────────┴─────────────────┐          │
│                                                   │          │
│                                    ┌──────────────┴────────┐│
│                                    │ RebaseTokenPool       ││
│                                    │ (CCIP Integration)    ││
│                                    └──────────────┬────────┘│
└───────────────────────────────────────────────────┼─────────┘
                                                    │
                                         Chainlink CCIP
                                                    │
┌───────────────────────────────────────────────────┼─────────┐
│                     Chain B                       │          │
│                                    ┌──────────────┴────────┐│
│                                    │ RebaseTokenPool       ││
│                                    │ (CCIP Integration)    ││
│                                    └──────────────┬────────┘│
│                                                   │          │
│  ┌─────────────┐      ┌──────────────┐          │          │
│  │   Vault     │──────│ RebaseToken  │──────────┘          │
│  └─────────────┘      └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Smart Contracts

### 1. RebaseToken.sol

The core ERC20 token with rebase functionality.

**Key Functions:**

- `deposit()`: Mint tokens by depositing ETH
- `redeem(uint256 amount)`: Burn tokens and withdraw ETH
- `transfer()` / `transferFrom()`: Transfer tokens with automatic interest calculation
- `setInterestRate(uint256 rate)`: Adjust global interest rate (owner only)
- `balanceOf(address user)`: Returns balance including accrued interest
- `principleBalanceOf(address user)`: Returns base balance excluding interest

**State Variables:**

- `s_interestRate`: Global interest rate (default: 5e10 = 0.000005%)
- `s_userInterestRate`: User-specific interest rates
- `s_userLastUpdatedTimestamp`: Last update timestamp for interest calculation

### 2. Vault.sol

ETH collateral management contract.

**Key Functions:**

- `deposit()`: Accept ETH and mint RebaseTokens (1:1 peg)
- `redeem(uint256 amount)`: Burn tokens and return ETH to user
- `receive()`: Accept ETH rewards to increase vault backing

### 3. RebaseTokenPool.sol

Chainlink CCIP integration for cross-chain transfers.

**Key Functions:**

- `lockOrBurn()`: Handles outgoing cross-chain transfers
- `releaseOrMint()`: Handles incoming cross-chain transfers
- Preserves user interest rates across chains through `destPoolData`

### 4. Interfaces

- `IRebaseToken.sol`: Interface for RebaseToken interactions

## 🚀 Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/Atul-ThakreLO/Cross-Chain-Rebase-Token.git
cd Cross-Chain-Rebase-Token

# Install dependencies
forge install

# Build the project
forge build
```

### Dependencies

- OpenZeppelin Contracts v5.x
- Chainlink CCIP Contracts
- Forge Standard Library

## 💻 Usage

### Build

```bash
forge build
```

### Test

Run all tests:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvv
```

Run specific test:

```bash
forge test --match-test testDepositeLinear
```

Run fuzz tests with custom runs:

```bash
forge test --fuzz-runs 1000
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Local Development

Start a local Anvil node:

```bash
anvil
```

## 🧪 Testing

The project includes comprehensive test coverage with fuzz testing:

### Test Suites

**RebaseTokenTest.t.sol** includes:

- `testDepositeLinear`: Validates linear interest accrual over time
- `testRedeemStraightAway`: Tests immediate redemption after deposit
- `testRedeemAfterSomeTimePassed`: Tests redemption with accrued interest
- `testTransfer`: Validates token transfers and interest rate inheritance
- `testCannotSetInterestRate`: Security test for unauthorized access
- `testCannotCallMintAndBurn`: Security test for role-based permissions
- `testGetPrincipleAmount`: Validates principle balance tracking
- `testInterestRateCanOnlyDecrease`: Validates interest rate constraints

**CrossChain.t.sol** includes cross-chain transfer tests.

### Running Tests

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/RebaseTokenTest.t.sol

# Run with coverage
forge coverage
```

## 🚢 Deployment

### Deployment Scripts

**BridgeToken.s.sol**: Deployment script for token bridging setup
**ConfigurePool.s.sol**: Configuration script for CCIP pools
**Deployer.s.sol**: Main deployment script

### Deploy to Testnet

```bash
# Deploy to Sepolia
forge script script/Deployer.s.sol:Deployer \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to Arbitrum Sepolia
forge script script/Deployer.s.sol:Deployer \
  --rpc-url $ARB_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY
```

### Environment Variables

Create a `.env` file:

```bash
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ARB_SEPOLIA_RPC_URL=your_arbitrum_sepolia_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
ARBISCAN_API_KEY=your_arbiscan_api_key
```

## 🔒 Security Considerations

### Access Control

- **Owner Role**: Can set interest rates and grant mint/burn permissions
- **MINT_BURN_ACCESS Role**: Required for minting and burning tokens
- Only the Vault contract should have mint/burn access in production

### Interest Rate Constraints

- Interest rates can only be decreased (never increased) to prevent inflation attacks
- Users inherit interest rates from senders on first transfer

### Reentrancy Protection

- Follows Checks-Effects-Interactions (CEI) pattern
- Uses low-level `.call()` for ETH transfers with proper error handling

### Precision

- Uses `PRECISION_FACTOR = 1e18` for accurate interest calculations
- Test assertions use `assertApproxEqAbs` with 1 wei delta for rounding tolerance

### Auditing

⚠️ **This code has not been audited. Use at your own risk in production environments.**

## 🛠️ Tech Stack

- **Solidity**: ^0.8.19
- **Foundry**: Smart contract development framework
- **OpenZeppelin**: Security-audited contract libraries
- **Chainlink CCIP**: Cross-chain interoperability
- **Forge Std**: Testing utilities

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Atul Thakre**

- GitHub: [@Atul-ThakreLO](https://github.com/Atul-ThakreLO)
- Repository: [Cross-Chain-Rebase-Token](https://github.com/Atul-ThakreLO/Cross-Chain-Rebase-Token)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Atul-ThakreLO/Cross-Chain-Rebase-Token/issues).

## 📚 Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Chainlink CCIP Documentation](https://docs.chain.link/ccip)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

---

**Note**: This is a demonstration project. Ensure thorough testing and security audits before deploying to mainnet.
