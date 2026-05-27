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



    //CONSTRUCTOR
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address SCAddresses){
        if(tokenAddresses.length != priceFeedAddresses.length){
            revert SC__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        //for loop which will map our two lists of addresses to each other
        for(uint256 i= 0; i < tokenAddresses.length; i++){
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

   function depositCollateralAndMintSC(address tokenCollateralAddress, uint256 colAmount, uint256 amountSCToMint) external NonZeroValue(colAmount) {
    _depositCollateral(msg.sender, tokenCollateralAddress, colAmount);
    mintSC(amountSCToMint);
   }

   function depositCollateral(address tokenCollateralAddress, uint256 colAmount) external NonZeroValue(colAmount) nonReentrant isAllowedToken(tokenCollateralAddress) {
    _depositCollateral(msg.sender, tokenCollateralAddress, colAmount);
   }

   function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) external NonZeroValue(amountCollateral) nonReentrant {
    _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
    revertIfBelowHealthFactor(msg.sender);
   }

   function redeemCollateralForSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountSCToBurn) external NonZeroValue(amountCollateral) {
    burnSC(amountSCToBurn);
    _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
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

   function liquidate(address user, address tokenCollateral, uint256 debtToCover) external NonZeroValue(debtToCover) nonReentrant {
    uint256 startingUserHealthFactor = _healthFactor(user);
    if(startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
        revert("User health factor is ok");
    }
    
    uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(tokenCollateral, debtToCover);
    // Give liquidator a 10% bonus for liquidating
    uint256 bonusCollateral = (tokenAmountFromDebtCovered * 10) / 100;
    uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
    
    _redeemCollateral(user, msg.sender, tokenCollateral, totalCollateralToRedeem);
    _burnSC(debtToCover, user, msg.sender);
    
    uint256 endingUserHealthFactor = _healthFactor(user);
    if(endingUserHealthFactor <= startingUserHealthFactor) {
        revert("Liquidation failed to improve health factor");
    }
    
    emit UserLiquidated(msg.sender, user, debtToCover, totalCollateralToRedeem);
   }

   function getHealthFactor(address user) public view returns(uint256) {
    return _healthFactor(user);
   }


   


   //INTERNAL FUNCTIONS///

   function _depositCollateral(address user, address tokenCollateral, uint256 amount) internal isAllowedToken(tokenCollateral) {
    s_collateralDeposited[user][tokenCollateral] += amount;
    emit CollateralDeposited(user, tokenCollateral, amount);
    bool success = IERC20(tokenCollateral).transferFrom(user, address(this), amount);
    require(success, "Transfer failed");
   }

   function _redeemCollateral(address from, address to, address tokenCollateral, uint256 amount) internal {
    s_collateralDeposited[from][tokenCollateral] -= amount;
    emit CollateralRedeemed(from, tokenCollateral, amount);
    bool success = IERC20(tokenCollateral).transfer(to, amount);
    require(success, "Transfer failed");
   }

   function _burnSC(uint256 amountSCToBurn, address onBehalfOf, address scFrom) internal {
    s_SCMinted[onBehalfOf] -= amountSCToBurn;
    bool success = iSC.transferFrom(scFrom, address(this), amountSCToBurn);
    require(success, "Transfer failed");
    iSC.burn(amountSCToBurn);
    emit SCBurned(onBehalfOf, amountSCToBurn);
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
      (,int256 price,,,) = priceFeed.latestRoundData();
      return (uint256(price) * PRICE_FEED_PRECISION * amount) / SC_PRECISION;
   }

   function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256) {
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
      (,int256 price,,,) = priceFeed.latestRoundData();
      return (usdAmountInWei * SC_PRECISION) / (uint256(price) * PRICE_FEED_PRECISION);
   }

   // GETTER FUNCTIONS
   function getCollateralDeposited(address user, address token) external view returns(uint256) {
      return s_collateralDeposited[user][token];
   }

   function getSCMinted(address user) external view returns(uint256) {
      return s_SCMinted[user];
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


