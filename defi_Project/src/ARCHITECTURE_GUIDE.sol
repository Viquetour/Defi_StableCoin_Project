// SPDX-License-Identifier: MIT
// This is a comprehensive inline documentation file explaining the entire project architecture

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║          DECENTRALIZED STABLECOIN PROTOCOL (DSC) - ARCHITECTURE GUIDE        ║
╚══════════════════════════════════════════════════════════════════════════════╝

PROJECT OBJECTIVE
═════════════════════════════════════════════════════════════════════════════════
Create a decentralized algorithmic stablecoin that maintains a $1 USD peg through:
- Overcollateralization (200% minimum)
- Chainlink price feeds
- Liquidation mechanics
- Algorithmic minting/burning


SYSTEM DESIGN
═════════════════════════════════════════════════════════════════════════════════

1. COLLATERAL TYPES
   ├─ wETH (Wrapped Ether)
   ├─ wBTC (Wrapped Bitcoin)
   └─ Extensible to other ERC20 tokens

2. ORACLE INTEGRATION
   ├─ Chainlink Price Feeds
   ├─ ETH/USD Feed
   ├─ BTC/USD Feed
   └─ Real-time USD Value Calculation

3. STABILITY MECHANISMS
   ├─ Minimum Health Factor = 1.0 (enforced)
   ├─ Liquidation Threshold = 50%
   ├─ Liquidator Bonus = 10%
   └─ Requires 200% collateralization


CONTRACT INTERACTIONS
═════════════════════════════════════════════════════════════════════════════════

User wants to mint DSC:
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ 1. User deposits wETH/wBTC as collateral                                   │
│    └─ Calls: depositCollateral() or depositCollateralAndMintSC()           │
│    └─ State Changed: s_collateralDeposited[user][token] += amount          │
│    └─ Event: CollateralDeposited(user, token, amount)                      │
│                                                                              │
│ 2. System calculates USD value of collateral                               │
│    └─ Function: getUsdValue(token, amount)                                 │
│    └─ Uses: Chainlink latestRoundData()                                    │
│    └─ Formula: (price × PRICE_FEED_PRECISION × amount) / SC_PRECISION      │
│                                                                              │
│ 3. User can mint DSC if health factor ≥ 1.0                                │
│    └─ Calls: mintSC(amount)                                                 │
│    └─ State Changed: s_SCMinted[user] += amount                             │
│    └─ Checked: revertIfBelowHealthFactor(user)                              │
│    └─ Result: DSC tokens minted to user                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

User's collateral drops in value:
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ 1. Health factor falls below 1.0                                           │
│    └─ Due to: Collateral price drop                                         │
│    └─ Example: ETH drops from $2000 to $1000                               │
│                                                                              │
│ 2. Liquidators can liquidate the position                                  │
│    └─ Calls: liquidate(user, tokenCollateral, debtToCover)                │
│    └─ Liquidator sends DSC to cover debt                                   │
│    └─ Liquidator receives: collateral + 10% bonus                          │
│    └─ User's health factor improves                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

User wants to withdraw collateral:
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│ 1. User burns DSC to free up collateral                                    │
│    └─ Calls: redeemCollateralForSC(token, amount, dscToBurn)               │
│    └─ User approves DSC to contract                                        │
│    └─ State Changed: s_SCMinted[user] -= dscToBurn                         │
│                                                                              │
│ 2. User redeems collateral                                                 │
│    └─ Calls: redeemCollateral(token, amount)                                │
│    └─ Collateral transferred back to user                                  │
│    └─ Health factor checked (must not go below 1.0)                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘


HEALTH FACTOR CALCULATION
═════════════════════════════════════════════════════════════════════════════════

Health Factor = (Adjusted Collateral Value) / (Total DSC Minted)

Where Adjusted Collateral Value = (Collateral USD Value × Liquidation Threshold)

Step-by-Step Example:
─────────────────────
User deposits: 10 ETH @ $2000/ETH = $20,000 collateral

Step 1: Calculate Collateral in USD
  collateralValueInUsd = getAccountCollateralValue(user)
  Result: $20,000

Step 2: Apply Liquidation Threshold (50%)
  collateralAdjustedForThreshold = ($20,000 × 50) / 100 = $10,000

Step 3: Divide by Total DSC Minted
  User mints 5,000 DSC:
  healthFactor = ($10,000 × 1e18) / 5,000 = 2e18 (2.0)
  ✅ Valid (≥ 1.0)

  User mints 10,000 DSC:
  healthFactor = ($10,000 × 1e18) / 10,000 = 1e18 (1.0)
  ✅ Valid (≥ 1.0)

  User mints 11,000 DSC:
  healthFactor = ($10,000 × 1e18) / 11,000 = 0.909e18 (0.909)
  ❌ Invalid (< 1.0) - TRANSACTION REVERTED


PRICE CALCULATION PRECISION
═════════════════════════════════════════════════════════════════════════════════

Constants:
  PRICE_FEED_PRECISION = 1e10  (Chainlink feeds return 8 decimals, we normalize to 18)
  SC_PRECISION = 1e18          (DSC uses 18 decimals, standard for ERC20)

Formula: USD_Value = (Price × PRICE_FEED_PRECISION × Amount) / SC_PRECISION

Example:
  ETH Price = 2000e8 (Chainlink returns prices with 8 decimals)
  Amount = 1e18 (1 ETH in wei)

  USD_Value = (2000e8 × 1e10 × 1e18) / 1e18
            = 2000e8 × 1e10
            = 2000 × 1e18
            = $2000 in wei


STATE VARIABLES REFERENCE
═════════════════════════════════════════════════════════════════════════════════

mapping(address token => address priceFeed) s_priceFeeds
  └─ Maps collateral token addresses to Chainlink price feed addresses
  └─ Example: s_priceFeeds[weth] = 0x694AA1769357215DE4FAC081bf1f309aDC325306

mapping(address user => mapping(address token => uint256 amount)) s_collateralDeposited
  └─ Tracks how much collateral each user has deposited for each token
  └─ Example: s_collateralDeposited[0xAlice][weth] = 10e18 (10 wETH)

mapping(address user => uint256 amountOfSCMinted) s_SCMinted
  └─ Tracks how much DSC each user has minted
  └─ Example: s_SCMinted[0xAlice] = 5e18 (5 DSC)

address[] s_collateralTokens
  └─ Array of all accepted collateral token addresses
  └─ Used to iterate through all collateral types when calculating total value


LIQUIDATION PROCESS DETAILED
═════════════════════════════════════════════════════════════════════════════════

Precondition: User's health factor < 1.0

Liquidator calls: liquidate(user, tokenCollateral, debtToCover)

Steps executed:
1. Check Starting Health Factor
   startingUserHealthFactor = _healthFactor(user)
   if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) revert

2. Calculate Collateral to Seize
   tokenAmountFromDebtCovered = getTokenAmountFromUsd(tokenCollateral, debtToCover)
   bonusCollateral = (tokenAmountFromDebtCovered × 10) / 100
   totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral

3. Transfer Collateral to Liquidator
   _redeemCollateral(user, liquidator, tokenCollateral, totalCollateralToRedeem)

4. Burn DSC (Liquidator pays for it)
   _burnSC(debtToCover, user, liquidator)

5. Verify Improvement
   endingUserHealthFactor = _healthFactor(user)
   if (endingUserHealthFactor <= startingUserHealthFactor) revert

6. Emit Event
   UserLiquidated(liquidator, user, debtCovered, collateralSeized)


TESTING STRATEGY
═════════════════════════════════════════════════════════════════════════════════

DSCEngineTest.t.sol covers:
├─ Constructor (getCollateralTokens)
├─ Deposit Collateral
│  ├─ Success cases
│  ├─ Zero amount revert
│  └─ Unallowed token revert
├─ Mint DSC
│  ├─ Success cases
│  ├─ Health factor violation revert
│  └─ Zero amount revert
├─ Health Factor
│  ├─ Proper reporting
│  └─ Below 1.0 scenarios
├─ Liquidation
│  └─ Cannot liquidate good health factor
├─ Burn DSC
│  └─ Successful burn
├─ Redeem Collateral
│  ├─ Basic redemption
│  └─ Redemption with DSC burn
├─ Account Information
│  └─ Correct calculation
└─ USD Value Calculations
   ├─ getUsdValue()
   └─ getTokenAmountFromUsd()

StableCoinTest.t.sol covers:
├─ Token metadata
├─ Mint function
├─ Burn function
├─ Access control (owner-only)
└─ Input validation


DEPLOYMENT SEQUENCE
═════════════════════════════════════════════════════════════════════════════════

DeployDC.s.sol execution flow:

1. Get network configuration
   HelperConfig config = new HelperConfig()
   - Sepolia: Real token addresses & Chainlink feeds
   - Anvil: Mocks deployed on the fly

2. Create token arrays
   tokenAddresses = [weth, wbtc]
   priceFeedAddresses = [wethUsdFeed, wbtcUsdFeed]

3. Deploy StableCoin
   StableCoin sc = new StableCoin()

4. Deploy DecentralizedProtocol (passes StableCoin address)
   DecentralizedProtocol engine = new DecentralizedProtocol(
     tokenAddresses,
     priceFeedAddresses,
     address(sc)
   )

5. Transfer ownership
   sc.transferOwnership(address(engine))
   └─ Now only the engine can mint/burn DSC

6. Return both contracts
   return (sc, engine)


FURTHER DEVELOPMENT IDEAS
═════════════════════════════════════════════════════════════════════════════════

Phase 2:
├─ Governance token (DAO voting on parameters)
├─ Dynamic liquidation threshold
├─ Stability fees (% charged on minted DSC)
└─ Yield mechanisms

Phase 3:
├─ Cross-chain bridging
├─ Additional collateral types
├─ Flash loan protection
└─ Emergency shutdown mechanism

Phase 4:
├─ Automated liquidation bots
├─ Insurance pool
├─ Secondary markets
└─ Synthetic asset creation


SECURITY NOTES
═════════════════════════════════════════════════════════════════════════════════

✅ Implemented:
  ├─ ReentrancyGuard on critical functions
  ├─ Access control (onlyOwner for minting/burning)
  ├─ Health factor enforcement
  └─ Input validation

⚠️  To Add Before Mainnet:
  ├─ Oracle staleness checks
  ├─ Circuit breaker for trading halts
  ├─ Multi-sig governance
  ├─ Professional security audit
  ├─ Pause/shutdown functions
  └─ Emergency token recovery


DEBUGGING GUIDE
═════════════════════════════════════════════════════════════════════════════════

Common Issues:

1. "Transfer failed" in depositCollateral
   └─ Solution: Ensure user approved tokens: token.approve(engine, amount)

2. "SC_HealthFactorBroken" when minting
   └─ Solution: Deposit more collateral or mint less DSC
   └─ Calculate max mint: (collateralUSD × 50) / 100

3. "Token not allowed" when depositing
   └─ Solution: Ensure token is in s_priceFeeds (check constructor)
   └─ For local testing: Use tokens from HelperConfig

4. Division by zero in getUsdValue
   └─ Solution: Chainlink feed may be down
   └─ Check: priceFeed.latestRoundData() returns non-zero price

*/

pragma solidity ^0.8.19;

// This file is for documentation only - not a real contract
// Delete before deployment or mark as unreachable code
