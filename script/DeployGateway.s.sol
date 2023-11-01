// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Gateway} from "../src/Gateway.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployGateway is Script {
    function run() external returns (Gateway) {
        HelperConfig helperConfig = new HelperConfig();
        (address cowProtocolSettlementAddress, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Gateway gateway = new Gateway(cowProtocolSettlementAddress);
        vm.stopBroadcast();
        return gateway;
    }
}
