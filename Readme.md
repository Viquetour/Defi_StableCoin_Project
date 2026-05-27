## Our StableCoin design.

## Relative Stability: Anchored or Pegged to the US Dollar

## Chainlink Pricefeed

## Function to convert ETH & BTC to USD

## Stability Mechanism (Minting/Burning): Algorithmicly Decentralized

## Users may only mint the stablecoin with enough collateral

## Collateral: Exogenous (Crypto)

    a. wETH
    b. wBTC

we hope to create our stablecoin in such a way that it is pegged to the US Dollar. We'll achieve this by leveraging chainlink pricefeeds to determine the USD value of deposited collateral when calculating the value of collateral underlying minted tokens.

The token should be kept stable through this collateralization stability mechanism.

For collateral, the protocol will accept wrapped Bitcoin and wrapped Ether, the ERC20 equivalents of these tokens.


# What functions wil be require for our contract?
1. deposit collateral and mint stable coin token.
2. Redeem their collateral for Stable coin
3. Burn DSC if th value of the collateral quickly drops
4. ability to liquidate an account to keep our protocol over collateralized.


## Health Factor

how are we going to determine an account's Health Factor? What will we need?

Total SC minted

Total Collateral value

In order to do this, we're actually going to create another function, stick with me here. Our next function will return some basic details of the user's account including their SC minted and the collateral value


    Say a user deposits $150 worth of ETH and goes to mint $100 worth of DSC.

    (150 * 50) / 100 = 75
    75/100 = 0.75
    0.75 < 1
    In the above example, a user who has deposited $150 worth of ETH would not be able to mint $100 worth of DSC as it results in their Health Factor breaking. $100 in DSC requires $200 in collateral to be deposited for the Health Factor to remain above 1.

    (200 * 50) / 100 = 100
    100/100 = 1
    1 >= 1
    With a LIQUIDATION_THRESHOLD of 50, a user requires 200% over-collateralization of their position, or the risk liquidation. Now that we've adjusted our collateral amount to account for a position's LIQUIDATION_THRESHOLD, we can use this adjust value to calculate a user's true Health Factor.

