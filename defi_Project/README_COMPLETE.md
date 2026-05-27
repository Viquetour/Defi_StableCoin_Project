# Decentralized Stablecoin Protocol (DSC)

A decentralized, algorithmic stablecoin system built with Solidity that maintains a 1:1 peg with the US Dollar through overcollateralization and liquidation mechanics.

## Project Overview

### What is DSC?

**DSC** is an Exogenous, Decentralized, Anchored (Pegged) stablecoin system that:

- **Maintains a $1 USD peg** through Chainlink price feeds
- **Requires 200% overcollateralization** (users need $200 in collateral to mint $100 in DSC)
- **Accepts crypto collateral**: wETH and wBTC
- **Enables liquidations** to protect protocol solvency
- **Operates algorithmically** with no centralized governance

### Key Features

1. **Deposit Collateral**: Users lock wETH or wBTC as collateral
2. **Mint Stablecoin**: Users mint DSC proportional to their collateral value
3. **Redeem Collateral**: Users can withdraw collateral by burning DSC
4. **Liquidations**: Undercollateralized positions can be liquidated
5. **Health Factor**: Tracks position safety (must stay ≥ 1.0)

## System Architecture

### Smart Contracts

#### 1. **StableCoin.sol**
- ERC20 token implementation of the DSC token
- Only the `DecentralizedProtocol` contract can mint/burn tokens
- Owner-controlled (initially set to deployer, then transferred to protocol)

```solidity
// Key functions
function mint(address _to, uint256 _amount) external onlyOwner
function burn(uint256 _amount) public override onlyOwner
```

#### 2. **DecentralizedProtocol.sol**
- Core engine managing collateral deposits, minting, and liquidations
- Tracks user collateral and minted DSC balances
- Uses Chainlink price feeds to calculate USD values
- Enforces health factor constraints

```solidity
// Core functions
function depositCollateral(address tokenCollateralAddress, uint256 colAmount)
function mintSC(uint256 amountSCToMint)
function depositCollateralAndMintSC(address token, uint256 colAmount, uint256 amountToMint)
function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
function redeemCollateralForSC(address tokenCollateral, uint256 amountCollateral, uint256 amountSCToBurn)
function burnSC(uint256 amount)
function liquidate(address user, address tokenCollateral, uint256 debtToCover)
```

### Configuration

#### **HelperConfig.s.sol**
Manages network-specific configurations:
- **Sepolia**: Uses real Chainlink price feeds and token addresses
- **Anvil/Local**: Deploys mock price feeds and test tokens

#### **DeployDC.s.sol**
Deployment script that:
- Sets up network configuration
- Deploys StableCoin contract
- Deploys DecentralizedProtocol contract
- Transfers ownership to the protocol

## Health Factor & Liquidation

### Health Factor Formula

```
Health Factor = (Collateral Value in USD * Liquidation Threshold) / Total DSC Minted

Where:
- Liquidation Threshold = 50% (LIQUIDATION_THRESHOLD)
- Minimum Health Factor = 1.0 (MIN_HEALTH_FACTOR)
```

### Example

**Scenario**: User deposits $150 worth of ETH

- **Minting $100 DSC**:
  - Adjusted Collateral = ($150 × 50%) / $100 = 0.75
  - Health Factor = 0.75 < 1.0 ❌ **REVERTED** (insufficient collateral)

- **Minting $75 DSC**:
  - Adjusted Collateral = ($150 × 50%) / $75 = 1.0
  - Health Factor = 1.0 ≥ 1.0 ✅ **ALLOWED** (minimum safe position)

- **Minting $50 DSC**:
  - Adjusted Collateral = ($150 × 50%) / $50 = 1.5
  - Health Factor = 1.5 ≥ 1.0 ✅ **ALLOWED** (good position)

If collateral value drops below required minimum, liquidators can liquidate the position and receive a 10% bonus.

## Installation & Setup

### Prerequisites

- **Foundry** (forge, cast, anvil)
- **Node.js** 18+
- Environment variables:
  - `PRIVATE_KEY` (for Sepolia deployment)
  - `SEPOLIA_RPC_URL` (optional)

### Install Dependencies

```bash
cd defi_Project
forge install
```

### Compile

```bash
forge build
```

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test file
forge test --match-path test/DSCEngineTest.t.sol

# Run specific test
forge test --match-test testMintDsc
```

### Test Files

1. **DSCEngineTest.t.sol** - Tests for DecentralizedProtocol.sol
   - Deposit collateral
   - Mint DSC
   - Health factor calculations
   - Liquidations
   - Burn DSC
   - Redeem collateral

2. **StableCoinTest.t.sol** - Tests for StableCoin.sol
   - Token mint/burn
   - Owner-only functions
   - Input validation

## Deployment

### Local Deployment (Anvil)

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy to local testnet
forge script script/deployDC.s.sol:DeployDC --rpc-url http://localhost:8545 --broadcast
```

### Sepolia Testnet Deployment

```bash
# Set your private key
export PRIVATE_KEY=your_private_key_here

# Deploy to Sepolia
forge script script/deployDC.s.sol:DeployDC --rpc-url https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY --broadcast --verify
```

## Usage Guide

### Mint DSC

```solidity
// 1. Approve collateral transfer
IERC20(weth).approve(address(dscEngine), 10 ether);

// 2. Deposit collateral and mint DSC
dscEngine.depositCollateralAndMintSC(
    weth,           // Token address
    10 ether,       // Collateral amount (10 WETH)
    5 ether         // DSC to mint (5 DSC)
);
```

### Redeem and Burn

```solidity
// 1. Approve DSC burn
dsc.approve(address(dscEngine), 5 ether);

// 2. Burn DSC and redeem collateral
dscEngine.redeemCollateralForSC(
    weth,           // Collateral token
    10 ether,       // Collateral to redeem
    5 ether         // DSC to burn
);
```

### Liquidate Undercollateralized Position

```solidity
// Check if position is liquidatable
uint256 healthFactor = dscEngine.getHealthFactor(userAddress);
if (healthFactor < 1e18) {
    // Liquidate the position
    dscEngine.liquidate(
        userAddress,            // User to liquidate
        weth,                   // Collateral to seize
        debtAmountToCover       // DSC to burn and cover
    );
}
```

## Key Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `LIQUIDATION_THRESHOLD` | 50% | Collateral safety margin |
| `MIN_HEALTH_FACTOR` | 1e18 | Minimum health factor required |
| `LIQUIDATION_PRECISION` | 100 | Precision denominator |
| `LIQUIDATOR_BONUS` | 10% | Bonus for liquidating positions |

## Security Considerations

### Implemented Protections

- ✅ **ReentrancyGuard** on functions that transfer assets
- ✅ **Access Control** - Only owner can mint/burn DSC
- ✅ **Health Factor Enforcement** - Min 200% collateralization
- ✅ **Price Feed Validation** - Uses Chainlink oracles
- ✅ **Input Validation** - Non-zero checks, address validation

### Considerations for Production

1. **Price Feed Security**: Monitor oracle health and add staleness checks
2. **Liquidation Incentives**: Adjust the 10% bonus based on market conditions
3. **Circuit Breakers**: Consider adding pause/shutdown mechanisms
4. **Multi-sig Governance**: Add governance for critical parameters
5. **Comprehensive Audits**: Get professional security audits before mainnet

## Project Structure

```
defi_Project/
├── src/
│   ├── StableCoin.sol           # DSC ERC20 token
│   └── DecentralizedProtocol.sol # Core protocol engine
├── script/
│   ├── deployDC.s.sol           # Deployment script
│   └── HelperConfig.s.sol       # Network configuration
├── test/
│   ├── DSCEngineTest.t.sol       # Protocol tests
│   └── StableCoinTest.t.sol      # Token tests
└── foundry.toml                 # Foundry configuration
```

## Future Enhancements

- [ ] Governance token for protocol decisions
- [ ] Oracle price feed aggregation
- [ ] Multi-collateral support expansion
- [ ] Yield mechanisms for stakers
- [ ] Cross-chain bridge integration
- [ ] Stability fees mechanism
- [ ] Dynamic collateralization ratios

## License

MIT

## Author

Viquetour

---

## Support & Resources

- **Chainlink Docs**: https://docs.chain.link/
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Foundry Book**: https://book.getfoundry.sh/
- **Solidity Docs**: https://docs.soliditylang.org/

## Disclaimer

This is an educational project. Use at your own risk. Ensure comprehensive security audits before deploying to mainnet or dealing with real funds.
