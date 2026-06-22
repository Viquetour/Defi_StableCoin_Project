//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {DecentralizedProtocol} from "../src/DecentralizedProtocol.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

/*
 * Minimal stand-in for a Chainlink price feed. Only implements decimals() and
 * latestRoundData(), which is all DecentralizedProtocol ever calls. Solidity dispatches
 * external calls by selector, so this doesn't need to formally inherit AggregatorV3Interface.
 */
contract MockPriceFeed {
    int256 private immutable i_price;
    uint8 private immutable i_decimals;

    constructor(int256 price, uint8 decimals_) {
        i_price = price;
        i_decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return i_decimals;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (1, i_price, block.timestamp, block.timestamp, 1);
    }
}

/*
 * Stand-in for a non-18-decimal collateral token, matching real mainnet WBTC (8 decimals).
 */
contract EightDecimalToken is ERC20 {
    constructor() ERC20("Mock WBTC", "mWBTC") {}

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/*
 * Regression test for the H-2 finding: getUsdValue/getTokenAmountFromUsd assumed every
 * collateral token has 18 decimals. That assumption silently breaks for tokens like real
 * mainnet WBTC (8 decimals) — collateral gets mis-valued by 10**10. This deploys a fresh
 * engine directly (independent of the project's DeployDC/HelperConfig scripts, which weren't
 * available for this review) with an 8-decimal token and an 8-decimal price feed, matching
 * real-world WBTC + Chainlink BTC/USD, and checks the math comes out exact.
 */
contract DecimalsHandlingTest is Test {
    DecentralizedProtocol engine;
    StableCoin sc;
    EightDecimalToken token;
    MockPriceFeed feed;

    function setUp() public {
        token = new EightDecimalToken();
        // $60,000 with 8 decimals, matching real Chainlink BTC/USD feed format.
        feed = new MockPriceFeed(60_000e8, 8);

        sc = new StableCoin();
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        address[] memory feeds = new address[](1);
        feeds[0] = address(feed);

        engine = new DecentralizedProtocol(tokens, feeds, address(sc));
        sc.transferOwnership(address(engine));
    }

    function testEightDecimalCollateralIsValuedCorrectly() public {
        // 1 whole token in its native 8-decimal raw units.
        uint256 oneToken = 1e8;
        uint256 usdValue = engine.getUsdValue(address(token), oneToken);
        assertEq(usdValue, 60_000e18, "1 token at $60,000 should value at exactly 60,000e18, not off by 1e10");
    }

    function testUsdToTokenRoundTripPreservesRealDecimals() public {
        // $60,000 of USD value should convert back to exactly 1 whole token (1e8 raw units),
        // not 1e18 raw units (which would exceed real WBTC's entire decimal range).
        uint256 tokenAmount = engine.getTokenAmountFromUsd(address(token), 60_000e18);
        assertEq(tokenAmount, 1e8, "round-trip should return 1e8 raw units, matching the token's real decimals");
    }

    function testCollateralValueScalesWithDepositedAmount() public {
        address user = makeAddr("user");
        uint256 halfToken = 0.5e8; // 0.5 BTC in real 8-decimal raw units
        token.mint(user, halfToken);

        vm.startPrank(user);
        token.approve(address(engine), halfToken);
        engine.depositCollateral(address(token), halfToken);
        vm.stopPrank();

        (, uint256 collateralValueInUsd) = engine.getAccountInformation(user);
        assertEq(collateralValueInUsd, 30_000e18, "0.5 BTC at $60,000 should be valued at $30,000");
    }

    function testEightDecimalUserCanMintAgainstRealisticCollateral() public {
        address user = makeAddr("user");
        uint256 oneToken = 1e8; // 1 BTC, worth $60,000
        token.mint(user, oneToken);

        vm.startPrank(user);
        token.approve(address(engine), oneToken);
        // Mint well under the 200% collateralization limit ($60,000 collateral allows up to
        // $30,000 of debt at the 50% liquidation threshold); 10,000 DSC is safely under that.
        engine.depositCollateralAndMintSC(address(token), oneToken, 10_000e18);
        vm.stopPrank();

        assertEq(engine.getSCMinted(user), 10_000e18);
        assertGt(engine.getHealthFactor(user), 1e18);
    }
}
