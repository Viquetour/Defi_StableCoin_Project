# Decentralized Stablecoin Protocol (DSC)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)](https://book.getfoundry.sh/)

> **An exogenously collateralized, algorithmically stable, dollar-pegged decentralized stablecoin protocol.**  
> Inspired by MakerDAO's DSS system — but simpler: no governance, no fees, and backed exclusively by WETH and WBTC.

---

## Table of Contents

- [Overview](#overview)
- [Core Features](#core-features)
- [How It Works](#how-it-works)
- [Project Architecture](#project-architecture)
- [Smart Contracts](#smart-contracts)
  - [DecentralizedProtocol](#decentralizedprotocol)
  - [StableCoin (DSC)](#stablecoin-dsc)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Build](#build)
  - [Run Tests](#run-tests)
- [Usage Guide](#usage-guide)
  - [Deposit Collateral & Mint DSC](#1-deposit-collateral--mint-dsc)
  - [Burn DSC to Unlock Collateral](#2-burn-dsc-to-unlock-collateral)
  - [Redeem Collateral](#3-redeem-collateral)
  - [Liquidations](#4-liquidations)
- [Deployment](#deployment)
  - [Local (Anvil)](#local-anvil)
  - [Testnet (Sepolia)](#testnet-sepolia)
- [Health Factor & Risk Parameters](#health-factor--risk-parameters)
- [Testing](#testing)
- [Security](#security)
- [License](#license)

---

## Overview

The **Decentralized Stablecoin Protocol (DSC)** is a fully on-chain, overcollateralized stablecoin system. Users deposit **WETH** and **WBTC** as collateral and mint **STC (StableCoin)** — a stablecoin soft-pegged to **1 USD**.

The protocol maintains stability through:

- **Overcollateralization** — Every DSC minted is backed by more than $1 worth of crypto collateral
- **Algorithmic enforcement** — Health factor constraints ensure positions remain solvent
- **Incentivized liquidations** — Liquidators earn a 10% bonus for closing underwater positions
- **No governance, no fees** — Pure DeFi, no admin keys or protocol fees on minting

| Property | Value |
|---|---|
| **Peg** | 1 STC ≈ 1 USD |
| **Collateral Type** | Exogenous (WETH, WBTC) |
| **Stability Mechanism** | Algorithmic (overcollateralization + liquidation) |
| **Governance** | None |
| **Protocol Fees** | None |
| **Oracles** | Chainlink Price Feeds |
| **Minimum Collateralization** | 200% (50% liquidation threshold) |

---

## Core Features

- **🔒 Overcollateralized Minting** — Mint DSC only when your collateral value sufficiently exceeds your debt
- **📊 Real-Time Health Factor** — Track your position's health at any time; positions below 1.0 become eligible for liquidation
- **💸 Permissionless Liquidations** — Anyone can liquidate an underwater position and earn a 10% bonus on seized collateral
- **🧹 Dust Sweep** — Special mechanism to clear dust positions too small for profitable liquidation
- **⚡ Gas-Optimized** — Built with Foundry, compiled with Shanghai EVM, and follows CEI (Checks-Effects-Interactions) pattern
- **🛡️ Reentrancy Protected** — All critical functions use OpenZeppelin's `ReentrancyGuard`
- **🔗 Chainlink Oracle Integration** — Price data secured by industry-standard oracles with staleness checks

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                         DSC Protocol                            │
│                                                                 │
│   ┌─────────────┐    Deposit Collateral     ┌───────────────┐  │
│   │   User      │ ─────────────────────────► │  DSC Engine   │  │
│   │ (Wallet)    │                            │  (Protocol)    │  │
│   │             │ ◄───────────────────────── │               │  │
│   │  WETH/WBTC  │     Mint DSC (STC)         │  Chainlink    │  │
│   │             │                            │  Price Feeds  │  │
│   └─────────────┘                            └───────┬───────┘  │
│                                                       │          │
│                                                       ▼          │
│                                              ┌───────────────┐  │
│                                              │  StableCoin   │  │
│                                              │  (STC ERC20)  │  │
│                                              └───────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Flow Summary

1. **Deposit** WETH or WBTC as collateral into the protocol
2. **Mint** DSC (STC) up to the safe limit determined by your health factor
3. **Use** DSC however you like — trade, provide liquidity, or simply hold
4. **Repay** DSC by burning it through the protocol
5. **Withdraw** your collateral once debt is repaid or reduced enough

If your health factor falls below **1.0**, your position becomes eligible for **liquidation**, where liquidators can seize your collateral (plus a 10% bonus) in exchange for covering your debt.

---

## Project Architecture

```
src/
├── DecentralizedProtocol.sol    # Core engine — deposit, mint, liquidate, redeem
├── StableCoin.sol               # ERC20 stablecoin token (STC)
└── ARCHITECTURE_GUIDE.sol       # In-depth documentation (inline comments)

script/
├── deployDC.s.sol               # Deployment script
└── HelperConfig.s.sol           # Network configuration (Sepolia / Anvil)

test/
├── DSCEngineTest.t.sol          # Core protocol tests
├── StableCoinTest.t.sol         # Token tests
└── DecimalsHandlingTest.t.sol   # Decimal precision edge case tests
```

---

## Smart Contracts

### DecentralizedProtocol

The core engine contract handling all protocol logic. It is the brain of the system.

**Key Responsibilities:**
- Manage collateral deposits and redemptions (WETH, WBTC)
- Mint and burn DSC tokens
- Enforce health factor constraints
- Process liquidations and dust sweeps
- Interface with Chainlink price feeds for USD pricing

**Key Constants:**

| Constant | Value | Description |
|---|---|---|
| `LIQUIDATION_THRESHOLD` | 50 | 50% — collateral value adjusted by this for health factor |
| `MIN_HEALTH_FACTOR` | 1.0 (1e18) | Minimum health factor before liquidation |
| `LIQUIDATION_PRECISION` | 100 | Denominator for threshold percentage |
| `MINIMUM_LIQUIDATION_AMOUNT` | 1e18 ($1) | Minimum debt that can be liquidated (anti-dust) |
| `PRICE_FEED_TIMEOUT` | 1 hour | Maximum age allowed for oracle price data |

**Core Functions:**

| Function | Access | Description |
|---|---|---|
| `depositCollateral(token, amount)` | Public | Deposit WETH/WBTC as collateral |
| `depositCollateralAndMintSC(token, colAmount, mintAmount)` | Public | Combined deposit + mint |
| `mintSC(amount)` | Public | Mint DSC against deposited collateral |
| `burnSC(amount)` | Public | Burn DSC to reduce debt |
| `redeemCollateral(token, amount)` | Public | Redeem deposited collateral |
| `redeemCollateralForSC(token, amount, dscToBurn)` | Public | Burn DSC + redeem in one call |
| `liquidate(user, token, debtToCover)` | Public | Liquidate an underwater position |
| `sweep(user, token)` | Public | Write off dust debt (< $1) |

**View Functions:**

| Function | Returns | Description |
|---|---|---|
| `getHealthFactor(user)` | `uint256` | Current health factor for a user |
| `getUsdValue(token, amount)` | `uint256` | Convert token amount to USD value |
| `getTokenAmountFromUsd(token, usdAmount)` | `uint256` | Convert USD to token amount |
| `getAccountCollateralValue(user)` | `uint256` | Total USD value of user's collateral |
| `getAccountInformation(user)` | `(uint256, uint256)` | Total DSC minted + collateral value |
| `getCollateralDeposited(user, token)` | `uint256` | User's deposited balance for a token |
| `getSCMinted(user)` | `uint256` | User's minted DSC balance |
| `getCollateralTokens()` | `address[]` | List of all supported collateral tokens |
| `getPriceFeed(token)` | `address` | Chainlink price feed for a token |
| `getStableCoin()` | `address` | Address of the DSC token contract |

### StableCoin (DSC)

An ERC20 token with mint/burn capabilities restricted to the protocol owner.

**Token Details:**

| Property | Value |
|---|---|
| **Name** | StableCoin |
| **Symbol** | STC |
| **Decimals** | 18 |
| **Standard** | ERC20Burnable + Ownable |

**Access Control:**
- `mint(to, amount)` — Only the owner (DSC Engine) can mint
- `burn(amount)` — Only the owner (DSC Engine) can burn (after pulling tokens via `transferFrom`)

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) — Ethereum development framework
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/Viquetour/Defi_StableCoin_Project.git
cd Defi_StableCoin_Project

# Install dependencies
git submodule update --init --recursive
```

### Build

```bash
forge build
```

### Run Tests

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run a specific test
forge test --match-test testDepositCollateralSucceeds -vvv

# Run tests with gas reporting
forge test --gas-report
```

---

## Usage Guide

### 1. Deposit Collateral & Mint DSC

```solidity
// 1. Approve the protocol to spend your WETH
weth.approve(address(dscEngine), 10 ether);

// 2. Deposit 10 WETH as collateral
dscEngine.depositCollateral(weth, 10 ether);

// 3. Mint 5,000 DSC (position is 2x overcollateralized at $2000/ETH)
dscEngine.mintSC(5000 ether);
```

**Or do it in one transaction:**

```solidity
weth.approve(address(dscEngine), 10 ether);
dscEngine.depositCollateralAndMintSC(weth, 10 ether, 5000 ether);
```

### 2. Burn DSC to Unlock Collateral

```solidity
// 1. Approve DSC for the protocol
dsc.approve(address(dscEngine), 5000 ether);

// 2. Burn DSC to reduce debt
dscEngine.burnSC(5000 ether);
```

### 3. Redeem Collateral

```solidity
// Burn DSC and redeem collateral in one call
dsc.approve(address(dscEngine), 5000 ether);
dscEngine.redeemCollateralForSC(weth, 5 ether, 5000 ether);

// Or redeem directly if you have no debt
dscEngine.redeemCollateral(weth, 5 ether);
```

### 4. Liquidations

```solidity
// When a user's health factor drops below 1.0, liquidate them
// Cover 1000 DSC of their debt, seize WETH collateral + 10% bonus
dsc.approve(address(dscEngine), 1000 ether);
dscEngine.liquidate(underwaterUser, weth, 1000 ether);
```

---

## Deployment

### Local (Anvil)

```bash
# Start a local Anvil node
anvil

# In a new terminal, run the deploy script
forge script script/deployDC.s.sol:DeployDC --rpc-url http://localhost:8545 --broadcast
```

The `HelperConfig` will automatically deploy mock tokens and price feeds for local testing.

### Testnet (Sepolia)

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id

# Deploy to Sepolia
forge script script/deployDC.s.sol:DeployDC \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

**Sepolia Addresses (for reference):**

| Contract | Address |
|---|---|
| WETH | `0xdd13E55209Fd76AfE204dBda4007C227904f0a81` |
| WBTC | `0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063` |
| ETH/USD Feed | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| BTC/USD Feed | `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` |

---

## Health Factor & Risk Parameters

The health factor determines how safe a position is from liquidation.

### Calculation

```
Health Factor = (Collateral USD Value × Liquidation Threshold) / Total DSC Minted

Where:
  Liquidation Threshold = 50%
  Minimum Health Factor = 1.0
```

### Examples

| Scenario | Collateral | DSC Minted | Health Factor | Status |
|---|---|---|---|---|
| Safe | $20,000 | $5,000 | 2.0 | ✅ |
| At Risk | $20,000 | $10,000 | 1.0 | ⚠️ Edge |
| Underwater | $20,000 | $11,000 | 0.91 | ❌ Liquidatable |

### Liquidation Process

When a position becomes underwater (health factor < 1.0):

1. **Anyone** can call `liquidate()`
2. The liquidator covers the user's DSC debt
3. The liquidator receives the equivalent collateral **plus a 10% bonus**
4. The user's remaining position improves (health factor must increase)

### Dust Sweep Mechanism

For debt amounts below **$1** that are unprofitable for regular liquidators:
- `sweep()` forgives the dust debt directly
- Available collateral is seized as compensation
- No DSC transfer required from the caller

---

## Testing

The test suite covers the full protocol lifecycle:

| Test File | Coverage |
|---|---|
| `DSCEngineTest.t.sol` | Deposit, mint, burn, redeem, liquidation, health factor, USD valuations, edge cases |
| `StableCoinTest.t.sol` | Token metadata, mint/burn access control, input validation |
| `DecimalsHandlingTest.t.sol` | Precision edge cases across different token/feed decimals |

**Run with coverage:**

```bash
# Generate coverage report
forge coverage

# Generate coverage in lcov format
forge coverage --report lcov
```

---

## Security

### Implemented Safeguards

- ✅ **ReentrancyGuard** — All state-changing external functions protected against reentrancy
- ✅ **CEI Pattern** — Checks-Effects-Interactions followed throughout
- ✅ **Input Validation** — Zero amounts, zero addresses, and invalid tokens all revert
- ✅ **Oracle Staleness Checks** — Price data older than 1 hour is rejected
- ✅ **Health Factor Enforcement** — All operations that could reduce health factor are validated
- ✅ **Access Control** — StableCoin minting/burning restricted to DSC Engine only
- ✅ **Overflow Protection** — Solidity 0.8.x built-in checked math
- ✅ **Insufficient Balance Checks** — Explicit underflow protection in collateral redemptions

### Recommended Before Mainnet

- ⬜ Professional third-party security audit
- ⬜ Multi-sig governance for emergency parameters
- ⬜ Circuit breaker / pause mechanism
- ⬜ Emergency shutdown procedure
- ⬜ Additional oracle redundancy (e.g., Tellor or RedStone as fallback)
- ⬜ Flash loan attack vector analysis
- ⬜ Formal verification of core invariants

---

## Tech Stack

| Technology | Purpose |
|---|---|
| [Solidity 0.8.20](https://soliditylang.org/) | Smart contract language |
| [Foundry](https://book.getfoundry.sh/) | Development, testing, and deployment |
| [Forge](https://book.getfoundry.sh/forge/) | Testing framework |
| [OpenZeppelin](https://www.openzeppelin.com/contracts) | ERC20, Ownable, ReentrancyGuard |
| [Chainlink](https://chain.link/) | Price oracles |
| [Anvil](https://book.getfoundry.sh/anvil/) | Local Ethereum node |

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/Viquetour">Viquetour</a>
</p>