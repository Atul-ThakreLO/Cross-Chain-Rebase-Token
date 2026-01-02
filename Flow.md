# Complete CCIP Token Bridge Setup Flow

## Prerequisites
```
Before Starting:
├─ Your rebase token deployed on Ethereum
├─ Your rebase token deployed on Arbitrum
├─ Admin access to both token contracts
├─ LINK tokens for fees on both chains
├─ CCIP Router addresses for both chains
├─ RMN Proxy addresses for both chains
└─ Token Admin Registry addresses
```

---

## Setup Flow

### 1. Deploy Token Pools
```
Deploy BurnMintTokenPool on each chain:

├─ Ethereum: Deploy BurnMintTokenPool
│  ├─ Input: Ethereum Token Address
│  ├─ Input: CCIP Router (Ethereum)
│  ├─ Input: RMN Proxy (Ethereum)
│  └─ Output: Ethereum Pool Address
│
└─ Arbitrum: Deploy BurnMintTokenPool
   ├─ Input: Arbitrum Token Address
   ├─ Input: CCIP Router (Arbitrum)
   ├─ Input: RMN Proxy (Arbitrum)
   └─ Output: Arbitrum Pool Address
```

### 2. Grant Token Permissions
```
Allow pools to mint/burn tokens:

├─ Ethereum Token → Grant roles to Ethereum Pool
│  ├─ Grant MINTER_ROLE
│  └─ Grant BURNER_ROLE
│
└─ Arbitrum Token → Grant roles to Arbitrum Pool
   ├─ Grant MINTER_ROLE
   └─ Grant BURNER_ROLE
```

### 3. Register with Token Admin Registry
```
Make tokens officially recognized by CCIP:

├─ Register Ethereum Token
│  ├─ Call: registerAdministrator()
│  │        1. registerAdminViaOwner / registerAdminViaGetCCIPAdmin
│  │        2. acceptAdminRole
│  │        3. setPool
│  ├─ Input: Ethereum Token Address
│  └─ Input: Admin Address
│
└─ Register Arbitrum Token
   ├─ Call: registerAdministrator()
   │        1. registerAdminViaOwner / registerAdminViaGetCCIPAdmin
   │        2. acceptAdminRole
   │        3. setPool
   ├─ Input: Arbitrum Token Address
   └─ Input: Admin Address
```

### 4. Configure Rate Limits
```
Set bridging limits for security:

├─ Ethereum Pool → Set rate limits for Arbitrum
│  ├─ Outbound limit: Max tokens per timeframe
│  └─ Inbound limit: Max tokens per timeframe
│
└─ Arbitrum Pool → Set rate limits for Ethereum
   ├─ Outbound limit: Max tokens per timeframe
   └─ Inbound limit: Max tokens per timeframe
```

### 5. Configure Cross-Chain Mappings
```
Link pools to each other:

├─ Ethereum Pool → Point to Arbitrum Pool
│  ├─ Call: applyChainUpdates()
│  ├─ Input: Arbitrum Chain Selector
│  ├─ Input: Arbitrum Pool Address
│  └─ Input: Token Address on Arbitrum
│
└─ Arbitrum Pool → Point to Ethereum Pool
   ├─ Call: applyChainUpdates()
   ├─ Input: Ethereum Chain Selector
   ├─ Input: Ethereum Pool Address
   └─ Input: Token Address on Ethereum
```


### 6. Link Pools to Router (If Required)
```
Ensure routers know about pools:

├─ Ethereum Router → Register Ethereum Pool
│  └─ Link token address to pool address
│
└─ Arbitrum Router → Register Arbitrum Pool
   └─ Link token address to pool address
```

### 7. Testing
```
Verify setup with small test bridge:

├─ Approve tokens and LINK
├─ Call ccipSend() on Ethereum Router
├─ Monitor CCIP Explorer for message
└─ Verify tokens minted on Arbitrum
```

---

## Complete Architecture

```
ETHEREUM                          ARBITRUM
────────                          ────────

Rebase Token                      Rebase Token
    ↕ (mint/burn)                     ↕ (mint/burn)
Token Pool ←──────────────────────→ Token Pool
    ↕                                  ↕
CCIP Router ←─── CCIP Message ────→ CCIP Router
    ↕                                  ↕
  User                               User
```

---

## Key Relationships

```
1. Token ←→ Pool
   └─ Pool has MINTER_ROLE and BURNER_ROLE

2. Pool ←→ Remote Pool
   └─ Configured via applyChainUpdates()

3. Pool ←→ Router
   └─ Router knows which pool handles which token

4. Token ←→ Registry
   └─ Token registered with admin in Token Admin Registry
```

---

## Execution Order Summary

```
Step 1: Deploy pools on both chains
Step 2: Grant mint/burn permissions on both chains
Step 3: Configure cross-chain mappings (bidirectional)
Step 4: Set rate limits on both chains
Step 5: Register tokens in admin registry
Step 6: Link pools to routers (if needed)
Step 7: Test bridge transaction
```