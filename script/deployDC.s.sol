//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralizedProtocol} from "../src/DecentralizedProtocol.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDC is Script {
    function run() external returns (StableCoin, DecentralizedProtocol) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();

        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = config.weth;
        tokenAddresses[1] = config.wbtc;

        address[] memory priceFeedAddresses = new address[](2);
        priceFeedAddresses[0] = config.wethUsdPriceFeed;
        priceFeedAddresses[1] = config.wbtcUsdPriceFeed;

        vm.startBroadcast(config.deployerKey);
        StableCoin stableCoin = new StableCoin();
        DecentralizedProtocol decentralizedProtocol =
            new DecentralizedProtocol(tokenAddresses, priceFeedAddresses, address(stableCoin));

        // Transfer ownership of stablecoin to the protocol
        stableCoin.transferOwnership(address(decentralizedProtocol));
        vm.stopBroadcast();

        return (stableCoin, decentralizedProtocol);
    }
}
