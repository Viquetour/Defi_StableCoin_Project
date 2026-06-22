//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StableCoin} from "../src/StableCoin.sol";

contract StableCoinTest is Test {
    StableCoin dsc;
    address public user = makeAddr("user");

    function setUp() external {
        // StableCoin initializes with msg.sender (this contract) as owner
        dsc = new StableCoin();
    }

    function testNameAndSymbol() public view {
        assertEq(dsc.name(), "StableCoin");
        assertEq(dsc.symbol(), "STC");
    }

    function testMintSucceeds() public {
        // Only owner (this contract) can mint
        dsc.mint(user, 100e18);
        assertEq(dsc.balanceOf(user), 100e18);
    }

    function testBurnSucceeds() public {
        // Owner mints to self and burns
        dsc.mint(address(this), 100e18);
        dsc.burn(100e18);
        assertEq(dsc.balanceOf(address(this)), 0);
    }

    function testRevertIfMintToZeroAddress() public {
        vm.expectRevert(StableCoin.StableCoin__MustNotBeZeroAddress.selector);
        dsc.mint(address(0), 100e18);
    }

    function testRevertIfMintZeroAmount() public {
        vm.expectRevert(StableCoin.StableCoin__MustNotBeZero.selector);
        dsc.mint(user, 0);
    }

    function testRevertIfBurnZeroAmount() public {
        dsc.mint(address(this), 100e18);
        vm.expectRevert(StableCoin.StableCoin__MustNotBeZero.selector);
        dsc.burn(0);
    }

    function testRevertIfBurnAmountExceedsBalance() public {
        dsc.mint(address(this), 100e18);
        vm.expectRevert(StableCoin.StableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(200e18);
    }

    function testOnlyOwnerCanMint() public {
        vm.startPrank(user);
        vm.expectRevert();
        dsc.mint(user, 100e18);
        vm.stopPrank();
    }

    function testOnlyOwnerCanBurn() public {
        dsc.mint(address(this), 100e18);
        vm.startPrank(user);
        vm.expectRevert();
        dsc.burn(100e18);
        vm.stopPrank();
    }
}
