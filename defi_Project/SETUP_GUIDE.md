# Getting Started - Step by Step Guide

This guide walks you through setting up and running your completed DSC protocol.

---

## 📋 Prerequisites

Before starting, ensure you have:

1. **Foundry installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Verify installation**
   ```bash
   forge --version  # Should show version
   anvil --version  # Should show version
   ```

3. **Node.js (optional, for TypeScript support)**
   ```bash
   node --version  # Should show v18+
   ```

---

## 🏗️ Step 1: Setup Project

### 1a. Navigate to project
```bash
cd /home/viquetour/Downloads/Building_Defi/defi_Project
```

### 1b. Install dependencies
```bash
forge install
```

**What this does:**
- Installs forge-std (Foundry standard library)
- Installs OpenZeppelin contracts
- Installs Chainlink contracts

**Expected output:**
```
Installing foundry-rs/forge-std
...
```

---

## 🔨 Step 2: Build the Project

### 2a. Clean build
```bash
forge clean && forge build
```

**What this does:**
- Removes previous build artifacts
- Compiles all Solidity contracts
- Generates bytecode and ABI

**Expected output:**
```
Compiling 1 files with 0.8.19
Solc 0.8.19 finished in 120ms
Compiler run successful!
```

### 2b. Verify compilation
```bash
# Should show your compiled contracts
ls out/
```

---

## ✅ Step 3: Run Tests

### 3a. Run all tests
```bash
forge test
```

**Expected output:**
```
Running 30 tests for test/DSCEngineTest.t.sol:DSCEngineTest
[PASS] testCanMintDsc (...)
[PASS] testDepositCollateral (...)
...
Test result: ok. 30 passed; 0 failed
```

### 3b. Run tests with verbose output
```bash
forge test -vvv
```

**Shows detailed logs for debugging**

### 3c. Run specific test
```bash
forge test --match-test testHealthFactor -vvv
```

### 3d. Check test coverage (optional)
```bash
forge coverage
```

---

## 🚀 Step 4: Local Deployment (Anvil)

### 4a. Terminal 1: Start Anvil
```bash
anvil
```

**Expected output:**
```
Listening on 127.0.0.1:8545
Private Keys:
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Accounts:
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

**Note:** Keep this terminal running!

### 4b. Terminal 2: Deploy contracts
```bash
forge script script/deployDC.s.sol:DeployDC \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**Expected output:**
```
Deploying StableCoin...
Deploying DecentralizedProtocol...
Deployment successful!
```

### 4c. Save deployment addresses
```bash
# From the output above, save:
STABLECOIN_ADDRESS=0x...
ENGINE_ADDRESS=0x...
WETH_ADDRESS=0x...
WBTC_ADDRESS=0x...
```

---

## 🧪 Step 5: Interact with Contract

### 5a. Using Cast (CLI)

**Check a user's health factor:**
```bash
cast call $ENGINE_ADDRESS "getHealthFactor(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

**Deposit collateral:**
```bash
cast send $WETH_ADDRESS "approve(address,uint256)" \
  $ENGINE_ADDRESS 10000000000000000000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545
```

**Mint DSC:**
```bash
cast send $ENGINE_ADDRESS "depositCollateralAndMintSC(address,uint256,uint256)" \
  $WETH_ADDRESS \
  10000000000000000000 \
  5000000000000000000 \
  --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545
```

### 5b. Using Hardhat Console (alternative)

```bash
npx hardhat console --network localhost
```

Then in console:
```javascript
const Engine = await ethers.getContractAt("DecentralizedProtocol", ENGINE_ADDRESS);
const userHF = await Engine.getHealthFactor("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
console.log("Health Factor:", userHF.toString());
```

---

## 📝 Step 6: Understanding Test Results

### Reading Test Output

```
[PASS] testDepositCollateral (...)
├─ Gas used: 123456
└─ Runtime: 45ms

[FAIL] testSomethingBroken (...)
├─ Error: Assertion failed
├─ Got: 100
├─ Expected: 200
```

### If tests fail:

1. **Check for compilation errors first**
   ```bash
   forge build
   ```

2. **Run with verbose output**
   ```bash
   forge test -vvv
   ```

3. **Check specific test**
   ```bash
   forge test --match-test testNameHere -vvv
   ```

---

## 🌐 Step 7: Sepolia Testnet Deployment

### 7a. Set up environment

```bash
# Get Sepolia ETH from faucet:
# https://sepoliafaucet.com

# Create .env file
cat > .env << EOF
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
EOF

# Load env vars
source .env
```

### 7b. Deploy to Sepolia

```bash
forge script script/deployDC.s.sol:DeployDC \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### 7c. View on block explorer

```bash
# Replace HASH with transaction hash from output
https://sepolia.etherscan.io/tx/HASH
```

---

## 📊 Step 8: Monitor Contract State

### Check balances

```bash
cast balance 0xYourAddress --rpc-url http://localhost:8545
```

### Check token balance

```bash
cast call $STABLECOIN_ADDRESS "balanceOf(address)" 0xYourAddress \
  --rpc-url http://localhost:8545
```

### Get account information

```bash
cast call $ENGINE_ADDRESS "getAccountInformation(address)" 0xYourAddress \
  --rpc-url http://localhost:8545
```

**Output format:**
```
minted: 5000000000000000000      (5 DSC)
collateral: 20000000000000000000 (20 USD value)
```

---

## 🐛 Step 9: Debugging

### Enable trace output

```bash
forge test --match-test testMint -vvvv
```

(4 v's for maximum verbosity)

### Check storage slots

```bash
cast storage $ENGINE_ADDRESS 0 --rpc-url http://localhost:8545
```

### Debug a transaction

```bash
forge test -vvv --match-test testSpecificTest
```

---

## 📚 Step 10: Understanding the Code

### Read in this order:

1. **COMPLETION_SUMMARY.md** - Overview of what was built
2. **README_COMPLETE.md** - Full system explanation  
3. **ARCHITECTURE_GUIDE.sol** - Technical deep dive
4. **QUICK_REFERENCE.md** - Function reference
5. **src/DecentralizedProtocol.sol** - Main implementation
6. **test/DSCEngineTest.t.sol** - Usage examples

---

## ⚙️ Advanced: Custom Configuration

### Modify test parameters

**In `test/DSCEngineTest.t.sol`, change:**
```solidity
uint256 public constant AMOUNT_COLLATERAL = 10 ether;     // Change this
uint256 public constant STARTING_BALANCE = 10 ether;       // Or this
uint256 public constant AMOUNT_TO_MINT = 5 ether;         // Or this
```

Then run tests:
```bash
forge test -vvv
```

### Deploy with different parameters

**In `script/HelperConfig.s.sol`, modify:**
```solidity
int256 public constant ETH_USD_PRICE = 2000e8;  // Change mock prices
int256 public constant BTC_USD_PRICE = 3000e8;
```

Then redeploy:
```bash
forge script script/deployDC.s.sol:DeployDC --rpc-url http://localhost:8545 --broadcast
```

---

## 🎓 Common Commands Reference

| Command | Purpose |
|---------|---------|
| `forge build` | Compile contracts |
| `forge test` | Run all tests |
| `forge test -vvv` | Run with verbose output |
| `forge clean` | Remove build artifacts |
| `anvil` | Start local blockchain |
| `cast send` | Send transaction |
| `cast call` | Read-only call |
| `cast balance` | Check ETH balance |
| `forge coverage` | Code coverage analysis |

---

## ✨ Success Checklist

After following these steps, you should have:

- [ ] Foundry installed and verified
- [ ] Project dependencies installed (`forge install`)
- [ ] Contracts compiled successfully (`forge build`)
- [ ] All tests passing (`forge test`)
- [ ] Anvil running locally (`anvil`)
- [ ] Contracts deployed locally
- [ ] Can interact with contracts using `cast`
- [ ] Understand the contract architecture
- [ ] Ready to deploy to testnet

---

## 🆘 Troubleshooting

### Compilation fails

```bash
# Clear cache and rebuild
forge clean
rm -rf cache/
forge build
```

### Tests fail  

```bash
# Run with maximum verbosity
forge test --match-test testNameHere -vvvv

# Check for recent changes
git status  # if using git
```

### Anvil not responding

```bash
# Make sure it's running in another terminal
# Should see "Listening on 127.0.0.1:8545"
# If not, restart it
```

### Transaction fails

```bash
# Check balance
cast balance 0xYourAddress

# Check approval
cast call $TOKEN "allowance(address,address)" 0xYourAddress $ENGINE

# Increase gas if needed
cast send ... --gas-price 100gwei
```

---

## 📞 Next Steps

1. **Deploy to Sepolia testnet** (see Step 7)
2. **Interact with contracts** using web3.py or web3.js
3. **Build a frontend** to interact with the protocol
4. **Get security audit** before mainnet
5. **Plan mainnet deployment**

---

## 🎉 You're Ready!

Your DeFi stablecoin protocol is set up and ready to use. Start with local testing and gradually move to testnet.

**Happy testing! 🚀**
