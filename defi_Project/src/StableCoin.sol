//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
@title: StableCoin stable coin
@author: Viquetour
Collateral: 1:11 USDC: which is $1 worth of usdc collateral fo every 1:1 stable coin minted
Minting: Algorithmic minting and burning of stable conins based on the price of the collateral
Relative Stability: Pegged to USDC, which is stable coin pegged.
This is the contract meant to be governed by SCEngine. This contract is just the ERC20 implementation of our stablecoin system.
*/

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// version
// imports
import {ERC20Burnable, ERC20} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";



contract StableCoin is ERC20Burnable,Ownable{

    //errors
    error StableCoin__MustNotBeZero();
    error StableCoin__BurnAmountExceedsBalance();
    error StableCoin__MustNotBeZeroAddress();
    error StableCoin__InvalidInput();

    constructor() ERC20("StableCoin", "STC") Ownable(msg.sender) {}


    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0){
            revert StableCoin__MustNotBeZero();
        }
        if (_amount > balance){
            revert StableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }


    function mint(address _to, uint256 _amount) external onlyOwner{
      if(_to == address(0) || _amount <= 0 || _amount > type(uint256).max)  {
        revert StableCoin__InvalidInput();
      }
      _mint(_to, _amount);
    }


}