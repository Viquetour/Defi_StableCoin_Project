forge# DSC Protocol - Quick Reference Guide

## Function Reference

### Deposit & Mint Operations

#### `depositCollateral(address tokenCollateral, uint256 amount)`
Deposit collateral without minting DSC immediately.

```solidity
// User approves token transfer first
IERC20(weth).approve(address(engine), 10 ether);

// Deposit 10 wETH
engine.depositCollateral(weth, 10 ether);
```

**Requirements:**
- Amount > 0
- Token must be in allowed list (weth or wbtc)
- Caller must approve tokens

**State Changes:**
- `s_collateralDeposited[msg.sender][weth] += 10 ether`

---

#### `mintSC(uint256 amountSCToMint)`
Mint DSC using already deposited collateral.

```solidity
// After depositing collateral, mint 5 DSC
engine.mintSC(5 ether);
```

**Requirements:**
- Amount > 0
- Resulting health factor must be ≥ 1.0
- User must have sufficient collateral

**State Changes:**
- `s_SCMinted[msg.sender] += 5 ether`
- DSC tokens sent to user

---

#### `depositCollateralAndMintSC(address token, uint256 colAmount, uint256 amountSCToMint)`
Combine deposit and mint in one transaction.

```solidity
// Approve first
IERC20(weth).approve(address(engine), 10 ether);

// Deposit 10 wETH and mint 5 DSC in one call
engine.depositCollateralAndMintSC(weth, 10 ether, 5 ether);
```

---

### Redeem & Burn Operations

#### `burnSC(uint256 amount)`
Burn your DSC tokens (reduces your minted amount).

```solidity
// Approve DSC for burning
dsc.approve(address(engine), 5 ether);

// Burn 5 DSC
engine.burnSC(5 ether);
```

**State Changes:**
- `s_SCMinted[msg.sender] -= 5 ether`
- DSC tokens destroyed

---

#### `redeemCollateral(address tokenCollateral, uint256 amount)`
Withdraw collateral (requires sufficient health factor).

```solidity
// Withdraw 5 wETH
engine.redeemCollateral(weth, 5 ether);
```

**Requirements:**
- After redemption, health factor must still be ≥ 1.0
- User must have at least `amount` collateral

**State Changes:**
- `s_collateralDeposited[msg.sender][weth] -= 5 ether`
- wETH returned to user

---

#### `redeemCollateralForSC(address tokenCollateral, uint256 amountCollateral, uint256 amountSCToBurn)`
Burn DSC and redeem collateral in one transaction.

```solidity
// Approve DSC
dsc.approve(address(engine), 3 ether);

// Burn 3 DSC and redeem 5 wETH
engine.redeemCollateralForSC(weth, 5 ether, 3 ether);
```

---

### Liquidation Operations

#### `liquidate(address user, address tokenCollateral, uint256 debtToCover)`
Liquidate an undercollateralized position.

```solidity
// First, check if user is liquidatable
uint256 healthFactor = engine.getHealthFactor(userAddress);
require(healthFactor < 1.0 ether, "User not liquidatable");

// Liquidator approves DSC for payment
dsc.approve(address(engine), debtAmount);

// Liquidate the position
engine.liquidate(userAddress, weth, debtAmount);
```

**What Happens:**
1. Liquidator pays `debtToCover` amount of DSC
2. DSC is burned
3. Liquidator receives collateral worth `debtToCover` + 10% bonus
4. User's health factor should improve

**Example:**
- User owes 100 DSC, liquidator covers 50 DSC
- Liquidator gets: $50 collateral + $5 bonus = $55 collateral
- User's minted DSC reduced by 50

---

### View Functions (Read-Only)

#### `getHealthFactor(address user)` → uint256
Check user's health factor (1.0 = minimum safe, > 1.0 = safe, < 1.0 = liquidatable).

```solidity
uint256 hf = engine.getHealthFactor(userAddress);
// If hf < 1e18, user can be liquidated
// If hf >= 1e18, user is safe
```

---

#### `getAccountCollateralValue(address user)` → uint256
Get total collateral value in USD.

```solidity
uint256 collateralInUsd = engine.getAccountCollateralValue(userAddress);
// Returns value in wei (divide by 1e18 for readable number)
```

---

#### `getSCMinted(address user)` → uint256
Get amount of DSC minted by user.

```solidity
uint256 minted = engine.getSCMinted(userAddress);
```

---

#### `getCollateralDeposited(address user, address token)` → uint256
Get amount of specific collateral deposited by user.

```solidity
uint256 ethDeposited = engine.getCollateralDeposited(userAddress, weth);
```

---

#### `getUsdValue(address token, uint256 amount)` → uint256
Convert token amount to USD value.

```solidity
uint256 usdValue = engine.getUsdValue(weth, 1 ether);
// Returns USD value in wei
```

---

#### `getTokenAmountFromUsd(address token, uint256 usdAmount)` → uint256
Convert USD amount to token amount.

```solidity
uint256 tokenAmount = engine.getTokenAmountFromUsd(weth, 100e18);
// Returns amount needed to be worth $100
```

---

#### `getAccountInformation(address user)` → (uint256, uint256)
Get complete account info in one call.

```solidity
(uint256 dscMinted, uint256 collateralValue) = engine.getAccountInformation(userAddress);
```

---

## Common Use Cases

### Use Case 1: New User Minting DSC

```solidity
// 1. User has 10 wETH (at $2000/ETH = $20,000 collateral)
// 2. User wants to mint DSC

// Step 1: Approve
IERC20(weth).approve(address(engine), 10 ether);

// Step 2: Deposit and mint (200% collateralization requires $10,000 /$1 = max 10,000 DSC)
// But with only $20,000 collateral and 50% threshold:
// Max = ($20,000 × 50%) / 1 = $10,000 DSC
engine.depositCollateralAndMintSC(weth, 10 ether, 10 ether); // Mints 10 DSC

// At this point:
// - Health factor = 1.0
// - User has 10 DSC
// - User has 10 wETH locked
```

### Use Case 2: Redeeming Everything Safely

```solidity
// User wants to close their position

// Step 1: Check how much DSC to burn
uint256 dscMinted = engine.getSCMinted(userAddress);

// Step 2: Approve DSC burn
dsc.approve(address(engine), dscMinted);

// Step 3: Burn DSC and redeem all collateral
uint256 collateral = engine.getCollateralDeposited(userAddress, weth);
engine.redeemCollateralForSC(weth, collateral, dscMinted);

// Position closed: no DSC minted, no collateral locked
```

### Use Case 3: Avoiding Liquidation

```solidity
// User's health factor is dropping (collateral price falling)

// Check current state
uint256 hf = engine.getHealthFactor(userAddress);
uint256 dscMinted = engine.getSCMinted(userAddress);

// If approaching liquidation, increase collateral or burn DSC
if (hf < 1.5e18) {
    // Option 1: Deposit more collateral
    IERC20(weth).approve(address(engine), 5 ether);
    engine.depositCollateral(weth, 5 ether);
    
    // Option 2: Burn some DSC
    dsc.approve(address(engine), 1 ether);
    engine.burnSC(1 ether);
}
```

### Use Case 4: Liquidating a Position

```solidity
// Monitor protocol for liquidation opportunities
address victimUser = 0x...;
address collateralToken = weth;

uint256 hf = engine.getHealthFactor(victimUser);
if (hf < 1e18) {
    // User is liquidatable
    
    // Liquidator gets DSC from market
    uint256 debtToLiquidate = engine.getSCMinted(victimUser) / 2; // Liquidate half
    
    // Approve liquidator's DSC
    dsc.approve(address(engine), debtToLiquidate);
    
    // Execute liquidation
    engine.liquidate(victimUser, collateralToken, debtToLiquidate);
    
    // Liquidator receives:
    // - debtToLiquidate worth of collateral
    // - 10% bonus on top
}
```

---

## Health Factor Quick Reference

| Scenario | Collateral | DSC Minted | Health Factor | Status |
|----------|-----------|-----------|---------------|--------|
| $20,000 wETH | $20,000 | 0 | ∞ | Safe (no debt) |
| $20,000 wETH | $20,000 | 5,000 | 2.0 | Safe |
| $20,000 wETH | $20,000 | 10,000 | 1.0 | Minimum Safe |
| $20,000 wETH | $20,000 | 11,000 | 0.91 | **Liquidatable** |
| $10,000 wETH | $10,000 | 10,000 | 0.5 | **Liquidatable** |

---

## Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `SC__NonZeroValueRequired` | Amount is 0 | Provide amount > 0 |
| `SC__TokenNotAllowed` | Token not in approved list | Use weth or wbtc |
| `SC_HealthFactorBroken` | Health factor < 1.0 | Deposit more collateral or mint less |
| `Token not allowed` (from state machine) | Token not set up in constructor | Check network config |
| `Transfer failed` | Approval not given or insufficient balance | Approve tokens or check balance |
| `User health factor is ok` | Trying to liquidate safe position | Only liquidate when HF < 1.0 |
| `Liquidation failed to improve health factor` | Liquidation didn't help | Check liquidation amount |

---

## Native Testing with Cast

```bash
# Get health factor
cast call $ENGINE_ADDRESS "getHealthFactor(address)" $USER_ADDRESS

# Get collateral value
cast call $ENGINE_ADDRESS "getAccountCollateralValue(address)" $USER_ADDRESS

# Get USD value
cast call $ENGINE_ADDRESS "getUsdValue(address,uint256)" $WETH_ADDRESS 1000000000000000000

# Send deposit transaction
cast send $ENGINE_ADDRESS "depositCollateral(address,uint256)" $WETH_ADDRESS 1000000000000000000 --private-key $PRIVATE_KEY

# Get minted amount
cast call $ENGINE_ADDRESS "getSCMinted(address)" $USER_ADDRESS
```

---

## Gas Optimization Tips

1. Use `depositCollateralAndMintSC()` instead of separate calls (1 less transaction)
2. Use `redeemCollateralForSC()` to combine operations
3. Batch multiple state changes in a single transaction
4. Check health factor before attempting marginal transactions

