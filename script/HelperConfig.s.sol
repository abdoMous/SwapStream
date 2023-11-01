// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address cowProtocolSettlementAddress;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 5) {
            activeNetworkConfig = getGoerliConfig();
        }
    }

    function getGoerliConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            cowProtocolSettlementAddress: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
