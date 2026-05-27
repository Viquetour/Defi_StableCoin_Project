//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {DecentralizedProtocol} from "../src/DecentralizedProtocol.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployDC} from "../script/deployDC.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDC deployer;
    DecentralizedProtocol dscEngine;
    StableCoin dsc;

    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 public constant AMOUNT_TO_MINT = 5 ether;
    
    // These will be set after deployment
    address weth;
    address wbtc;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;

    function setUp() external {
        deployer = new DeployDC();
        (dsc, dscEngine) = deployer.run();
        
        // Get token addresses from the engine
        address[] memory tokens = dscEngine.getCollateralTokens();
        weth = tokens[0];
        wbtc = tokens[1];
        wethUsdPriceFeed = dscEngine.getPriceFeed(weth);
        wbtcUsdPriceFeed = dscEngine.getPriceFeed(wbtc);

        // Mint tokens to test users
        ERC20Mock(weth).mint(USER, STARTING_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_BALANCE);
    }

    ///////////////////////////
    // Constructor Tests //
    ///////////////////////////

    function testGetCollateralTokens() public {
        address[] memory collateralTokens = dscEngine.getCollateralTokens();
        assert(collateralTokens[0] == weth);
        assert(collateralTokens[1] == wbtc);
    }

    ////////////////////////////
    // Deposit Collateral Tests //
    ////////////////////////////

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testDepositCollateralSucceeds() public depositedCollateral {
        uint256 collateralDeposited = dscEngine.getCollateralDeposited(
            USER,
            weth
        );
        assertEq(collateralDeposited, AMOUNT_COLLATERAL);
    }

    function testRevertIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertIfUnallowedToken() public {
        ERC20Mock ranToken = new ERC20Mock();
        ranToken.mint(USER, STARTING_BALANCE);
        vm.startPrank(USER);
        ranToken.approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert();
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    ////////////////////////////
    // Mint DSC Tests //
    ////////////////////////////

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price, , , ) = AggregatorV3Interface(wethUsdPriceFeed)
            .latestRoundData();
        uint256 amountToMint = ((AMOUNT_COLLATERAL * (uint256(price) * 1e10)) /
            1e18);
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.expectRevert();
        dscEngine.mintSC(amountToMint);
        vm.stopPrank();
    }

    function testCanMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.mintSC(AMOUNT_TO_MINT);
        uint256 dscMinted = dscEngine.getSCMinted(USER);
        assertEq(dscMinted, AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    function testMintDscRevertsIfZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.expectRevert();
        dscEngine.mintSC(0);
        vm.stopPrank();
    }

    ////////////////////////////
    // Health Factor Tests //
    ////////////////////////////

    function testProperlyReportsHealthFactor() public depositedCollateral {
        uint256 healthFactor = dscEngine.getHealthFactor(USER);
        // If USER has collateral but no minted DSC, health factor should be max
        assertEq(healthFactor, type(uint256).max);
    }

    function testHealthFactorCanGoBelowOne() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.mintSC(AMOUNT_TO_MINT);
        vm.stopPrank();

        uint256 healthFactor = dscEngine.getHealthFactor(USER);
        // Health factor should be positive but less than initial max
        assert(healthFactor < type(uint256).max);
        assert(healthFactor > 0);
    }

    ////////////////////////////
    // Liquidation Tests //
    ////////////////////////////

    function testCantLiquidateGoodHealthFactor() public depositedCollateral {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.mintSC(AMOUNT_TO_MINT);
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        vm.expectRevert();
        dscEngine.liquidate(USER, weth, AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    ////////////////////////////
    // Burn DSC Tests //
    ////////////////////////////

    function testBurnDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.mintSC(AMOUNT_TO_MINT);

        // Approve DSC for burning
        dsc.approve(address(dscEngine), AMOUNT_TO_MINT);
        dscEngine.burnSC(AMOUNT_TO_MINT);

        uint256 minted = dscEngine.getSCMinted(USER);
        assertEq(minted, 0);
        vm.stopPrank();
    }

    ////////////////////////////
    // Redeem Collateral Tests //
    ////////////////////////////

    function testRedeemCollateral() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.redeemCollateral(weth, AMOUNT_COLLATERAL);

        uint256 collateralDeposited = dscEngine.getCollateralDeposited(
            USER,
            weth
        );
        assertEq(collateralDeposited, 0);
        vm.stopPrank();
    }

    function testRedeemCollateralForDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.mintSC(AMOUNT_TO_MINT);

        dsc.approve(address(dscEngine), AMOUNT_TO_MINT);
        dscEngine.redeemCollateralForSC(weth, AMOUNT_COLLATERAL / 2, AMOUNT_TO_MINT);

        uint256 collateral = dscEngine.getCollateralDeposited(USER, weth);
        uint256 minted = dscEngine.getSCMinted(USER);

        assertEq(collateral, AMOUNT_COLLATERAL / 2);
        assertEq(minted, 0);
        vm.stopPrank();
    }

    //////////////////////////////
    // Account Information Tests //
    //////////////////////////////

    function testGetAccountInformation() public depositedCollateral {
        vm.startPrank(USER);
        dscEngine.mintSC(AMOUNT_TO_MINT);
        vm.stopPrank();

        (uint256 minted, uint256 collateral) = dscEngine.getAccountInformation(
            USER
        );

        assertEq(minted, AMOUNT_TO_MINT);
        assert(collateral > 0);
    }

    ////////////////////////////
    // USD Value Tests //
    ////////////////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(actualUsd, expectedUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100e18;
        uint256 expectedTokenAmount = 0.05 ether;
        uint256 actualTokenAmount = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualTokenAmount, expectedTokenAmount);
    }

    ////////////////////////////
    // Deposit and Mint Tests //
    ////////////////////////////

    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateralAndMintSC(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);
        vm.stopPrank();

        uint256 collateral = dscEngine.getCollateralDeposited(USER, weth);
        uint256 minted = dscEngine.getSCMinted(USER);

        assertEq(collateral, AMOUNT_COLLATERAL);
        assertEq(minted, AMOUNT_TO_MINT);
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
