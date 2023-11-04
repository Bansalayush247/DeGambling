// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 80001) {
            activeNetworkConfig = getMumbaiEthConfig();
        }
    }

    function getMumbaiEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed,
            keyHash: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            subscriptionId: 6389,
            callbackGasLimit: 500000,
            link: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
