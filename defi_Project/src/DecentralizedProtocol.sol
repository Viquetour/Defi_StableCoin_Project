//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StableCoin} from "./StableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

    /*
 * @title DSCEngine
 * @author Viquetour
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */


contract DecentralizedProtocol is ReentrancyGuard{


    //ERRORS
    error SC__NonZeroValueRequired();
    error SC__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error SC__TokenNotAllowed(address token);
    error SC_HealthFactorBroken(uint256 healthFactor);
    error SC__InvalidPriceFeedAddress();
    error SC__InvalidTokenAddress();
    error SC__UserHealthFactorOk();
    error SC__LiquidationFailedToImproveHealthFactor();
    error SC__InvalidPriceFromOracle();
    error SC__CannotSelfLiquidate();
    error SC__DebtToCoverExceedsUserDebt();
    error SC__StalePriceFeed();


    //MODIFIER
    modifier NonZeroValue(uint256 amount) {
        _NonZeroValue(amount);
        _;
    }

    modifier isAllowedToken(address token) {
        _isAllowedToken(token);
        _;
    }

    function _NonZeroValue(uint256 amount) internal {
        if(amount <= 0) {
            revert SC__NonZeroValueRequired();
        }
    }

    function _isAllowedToken(address token) internal {
        if(s_priceFeeds[token] == address(0)) {
            revert SC__TokenNotAllowed(token);
        }
    }

    //EVENTS
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 indexed amount);
    event SCMinted(address indexed user, uint256 indexed amount);
    event SCBurned(address indexed user, uint256 indexed amount);
    event UserLiquidated(address indexed liquidator, address indexed user, uint256 debtCovered, uint256 collateralSeized);
    event DustAmountSwept(address indexed user, uint256 dustAmount, uint256 collateralSeized);

    //State Variables
    mapping(address token => address priceFeed) private s_priceFeeds;
    StableCoin private immutable iSC;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountOfSCMinted) private s_SCMinted;
    address[] private s_collateralTokens;


    uint256 private constant PRICE_FEED_PRECISION = 1e10;
    uint256 private constant SC_PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //50% COLLATERALIZATION
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; //1e18 == 1.0
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MINIMUM_LIQUIDATION_AMOUNT = 1e18; // $1 minimum to prevent dust
    uint256 private constant PRICE_FEED_TIMEOUT = 1 hours; // Maximum age of price feed data



    //CONSTRUCTOR
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address SCAddresses){
        if(tokenAddresses.length != priceFeedAddresses.length){
            revert SC__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        if(SCAddresses == address(0)){
            revert SC__InvalidTokenAddress();
        }
        //for loop which will map our two lists of addresses to each other
        for(uint256 i= 0; i < tokenAddresses.length; i++){
            if(tokenAddresses[i] == address(0) || priceFeedAddresses[i] == address(0)){
                revert SC__InvalidPriceFeedAddress();
            }
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            //With this array set up, we can now loop through this in our getAccountCollateralValue function to calculate it's total value in USD.
            s_collateralTokens.push(tokenAddresses[i]);
        }

        iSC = StableCoin(SCAddresses);
    }




   // EXTERNAL FUNCTIONS///

   /*
   * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing.
   * @param amountCollateral: The amount of collateral your're depositing. 
   */

   function depositCollateralAndMintSC(address tokenCollateralAddress, uint256 colAmount, uint256 amountSCToMint) external NonZeroValue(colAmount) nonReentrant isAllowedToken(tokenCollateralAddress) {
    // Check collateral amount is valid
    if(colAmount <= 0) {
        revert SC__NonZeroValueRequired();
    }
    // Check mint amount is valid
    if(amountSCToMint <= 0) {
        revert SC__NonZeroValueRequired();
    }
    
    // Update state BEFORE external calls (CEI pattern)
    s_collateralDeposited[msg.sender][tokenCollateralAddress] += colAmount;
    s_SCMinted[msg.sender] += amountSCToMint;
    
    // Emit events after state changes
    emit CollateralDeposited(msg.sender, tokenCollateralAddress, colAmount);
    emit SCMinted(msg.sender, amountSCToMint);
    
    // Perform external calls AFTER state updates
    bool transferSuccess = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), colAmount);
    require(transferSuccess, "Collateral transfer failed");
    
    // Mint stablecoin
    iSC.mint(msg.sender, amountSCToMint);
    
    // Check health factor AFTER all state changes
    revertIfBelowHealthFactor(msg.sender);
   }

   function depositCollateral(address tokenCollateralAddress, uint256 colAmount) external NonZeroValue(colAmount) nonReentrant isAllowedToken(tokenCollateralAddress) {
    _depositCollateral(msg.sender, tokenCollateralAddress, colAmount);
   }

   function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) external NonZeroValue(amountCollateral) nonReentrant {
    _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
    revertIfBelowHealthFactor(msg.sender);
   }

   function redeemCollateralForSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountSCToBurn) external NonZeroValue(amountCollateral) nonReentrant {
    burnSC(amountSCToBurn);
    _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
    revertIfBelowHealthFactor(msg.sender);
   }

   function mintSC(uint256 amountSCToMint) public NonZeroValue(amountSCToMint) nonReentrant {
    s_SCMinted[msg.sender] += amountSCToMint;
    revertIfBelowHealthFactor(msg.sender);
    iSC.mint(msg.sender, amountSCToMint);
    emit SCMinted(msg.sender, amountSCToMint);
   }

   function burnSC(uint256 amount) public NonZeroValue(amount) nonReentrant {
    _burnSC(amount, msg.sender, msg.sender);
   }

   function liquidate(address user, address tokenCollateral, uint256 debtToCover) external NonZeroValue(debtToCover) nonReentrant isAllowedToken(tokenCollateral) {
    if(msg.sender == user) {
        revert SC__CannotSelfLiquidate();
    }
    
    if(debtToCover < MINIMUM_LIQUIDATION_AMOUNT) {
        revert SC__NonZeroValueRequired();
    }
    
    // VALIDATION: Ensure debtToCover does not exceed user's actual debt
    uint256 userActualDebt = s_SCMinted[user];
    if(debtToCover > userActualDebt) {
        revert SC__DebtToCoverExceedsUserDebt();
    }
    
    uint256 startingUserHealthFactor = _healthFactor(user);
    if(startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
        revert SC__UserHealthFactorOk();
    }
    
    uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(tokenCollateral, debtToCover);
    uint256 availableCollateral = s_collateralDeposited[user][tokenCollateral];
    
    // Give liquidator a 10% bonus for liquidating
    uint256 bonusCollateral = (tokenAmountFromDebtCovered * 10) / 100;
    uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
    
    // Safeguard: if insufficient collateral for full bonus, reduce bonus proportionally
    if(totalCollateralToRedeem > availableCollateral) {
        bonusCollateral = availableCollateral - tokenAmountFromDebtCovered;
        totalCollateralToRedeem = availableCollateral;
    }
    
    _redeemCollateral(user, msg.sender, tokenCollateral, totalCollateralToRedeem);
    _burnSC(debtToCover, user, msg.sender);
    
    uint256 endingUserHealthFactor = _healthFactor(user);
    if(endingUserHealthFactor <= startingUserHealthFactor) {
        revert SC__LiquidationFailedToImproveHealthFactor();
    }
    
    emit UserLiquidated(msg.sender, user, debtToCover, totalCollateralToRedeem);
   }

   /*
   * @notice Sweep function to liquidate dust amounts that are unprofitable for regular liquidators
   * @param user: The user with the underwater position
   * @param tokenCollateral: The collateral token to liquidate
   * @dev This function can ONLY be called when debt is below MINIMUM_LIQUIDATION_AMOUNT (dust)
   * No 10% bonus given (dust cleanup incentive to protocol)
   */
   function sweep(address user, address tokenCollateral) external nonReentrant isAllowedToken(tokenCollateral) {
    if(msg.sender == user) {
        revert SC__CannotSelfLiquidate();
    }
    
    uint256 userDebt = s_SCMinted[user];
    
    if(userDebt == 0) {
        revert SC__NonZeroValueRequired();
    }
    
    // Safeguard: sweep can only be called on dust amounts
    if(userDebt >= MINIMUM_LIQUIDATION_AMOUNT) {
        revert("Debt is not dust - use liquidate() instead");
    }
    
    uint256 startingUserHealthFactor = _healthFactor(user);
    if(startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
        revert SC__UserHealthFactorOk();
    }
    
    // Liquidate the exact remaining debt amount
    uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(tokenCollateral, userDebt);
    // No bonus for dust sweep - protocol keeps collateral
    
    _redeemCollateral(user, address(this), tokenCollateral, tokenAmountFromDebtCovered);
    _burnSC(userDebt, user, address(this));
    
    uint256 endingUserHealthFactor = _healthFactor(user);
    if(endingUserHealthFactor <= startingUserHealthFactor) {
        revert SC__LiquidationFailedToImproveHealthFactor();
    }
    
    emit DustAmountSwept(user, userDebt, tokenAmountFromDebtCovered);
   }

   function getHealthFactor(address user) public view returns(uint256) {
    return _healthFactor(user);
   }


   


   //INTERNAL FUNCTIONS///

   function _depositCollateral(address user, address tokenCollateral, uint256 amount) internal isAllowedToken(tokenCollateral) {
    // Update state BEFORE external calls (CEI pattern)
    s_collateralDeposited[user][tokenCollateral] += amount;
    emit CollateralDeposited(user, tokenCollateral, amount);
    
    // Perform external call AFTER state update
    bool success = IERC20(tokenCollateral).transferFrom(user, address(this), amount);
    require(success, "Collateral transfer failed");
   }

   function _redeemCollateral(address from, address to, address tokenCollateral, uint256 amount) internal {
    // EXPLICIT EDGE CASE HANDLING (Vulnerability #6 mitigation): Prevent underflow/overdraw
    uint256 collateralBalance = s_collateralDeposited[from][tokenCollateral];
    require(amount <= collateralBalance, "Insufficient collateral balance to redeem");
    
    s_collateralDeposited[from][tokenCollateral] -= amount;
    emit CollateralRedeemed(from, tokenCollateral, amount);
    
    bool success = IERC20(tokenCollateral).transfer(to, amount);
    require(success, "Collateral transfer failed");
   }

   function _burnSC(uint256 amountSCToBurn, address onBehalfOf, address scFrom) internal {
    s_SCMinted[onBehalfOf] -= amountSCToBurn;
    emit SCBurned(onBehalfOf, amountSCToBurn);
    
    // Check allowance before transfer
    uint256 allowance = iSC.allowance(scFrom, address(this));
    require(allowance >= amountSCToBurn, "Insufficient allowance for burn");
    
    // Perform external call AFTER state changes
    bool transferSuccess = iSC.transferFrom(scFrom, address(this), amountSCToBurn);
    require(transferSuccess, "Stablecoin transfer failed");
    iSC.burn(amountSCToBurn);
   }

   function revertIfBelowHealthFactor(address user) internal view {
    uint256 userHealthFactor  = _healthFactor(user);
    if(userHealthFactor < MIN_HEALTH_FACTOR){
        revert SC_HealthFactorBroken(userHealthFactor);
    }
   }


    /*
    * Returns how close to liquidation a user is
    * If a user goes below 1, then they can be liquidated.
    */

   function _healthFactor(address user) private view returns(uint256){
    (uint256 totalSCMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
    if(totalSCMinted == 0) {
        return type(uint256).max;
    }
    uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
    return (collateralAdjustedForThreshold * PRECISION) / totalSCMinted;
   }

   function _getAccountInformation(address user) private view returns(uint256 totalSCMinted, uint256 collateralValueInUsd) {
    totalSCMinted  = s_SCMinted[user];
    collateralValueInUsd = getAccountCollateralValue(user);

   }

    //PUBLIC VIEW FUNCTIONS//
   function getAccountCollateralValue(address user) public view returns(uint256){
    uint256 totalCollateralValueInUsd = 0;
    for(uint256 i = 0; i < s_collateralTokens.length; i++){
        address token = s_collateralTokens[i];
        uint256 amountCollateralDeposited = s_collateralDeposited[user][token];
        totalCollateralValueInUsd += getUsdValue(token, amountCollateralDeposited);
    }
    return totalCollateralValueInUsd;
   }

   function getUsdValue(address token, uint256 amount) public view returns(uint256){
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
      (,int256 price,,uint256 updatedAt,) = priceFeed.latestRoundData();
      
      // VALIDATION: Check for stale price feed data (Vulnerability #4 mitigation)
      if(block.timestamp - updatedAt > PRICE_FEED_TIMEOUT) {
         revert SC__StalePriceFeed();
      }
      
      if(price <= 0){
         revert SC__InvalidPriceFromOracle();
      }
      return (uint256(price) * PRICE_FEED_PRECISION * amount) / SC_PRECISION;
   }

   function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256) {
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
      (,int256 price,,uint256 updatedAt,) = priceFeed.latestRoundData();
      
      // VALIDATION: Check for stale price feed data (Vulnerability #4 mitigation)
      if(block.timestamp - updatedAt > PRICE_FEED_TIMEOUT) {
         revert SC__StalePriceFeed();
      }
      
      if(price <= 0){
         revert SC__InvalidPriceFromOracle();
      }
      return (usdAmountInWei * SC_PRECISION) / (uint256(price) * PRICE_FEED_PRECISION);
   }

   // GETTER FUNCTIONS
   function getCollateralDeposited(address user, address token) external view returns(uint256) {
      return s_collateralDeposited[user][token];
   }

   function getSCMinted(address user) external view returns(uint256) {
      return s_SCMinted[user];
   }

   function getMinimumLiquidationAmount() external pure returns(uint256) {
      return MINIMUM_LIQUIDATION_AMOUNT;
   }

   function getPriceFeedTimeout() external pure returns(uint256) {
      return PRICE_FEED_TIMEOUT;
   }

   function getCollateralTokens() external view returns(address[] memory) {
      return s_collateralTokens;
   }

   function getPriceFeed(address token) external view returns(address) {
      return s_priceFeeds[token];
   }

   function getStableCoin() external view returns(address) {
      return address(iSC);
   }

   function getAccountInformation(address user) external view returns(uint256 totalDscMinted, uint256 collateralValueInUsd) {
      return _getAccountInformation(user);
   }

   function LIQUIDATION_THRESHOLD_VALUE() external pure returns(uint256) {
      return LIQUIDATION_THRESHOLD;
   }

   function MIN_HEALTH_FACTOR_VALUE() external pure returns(uint256) {
      return MIN_HEALTH_FACTOR;
   }
}


