// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinatorAddress,
            uint64 subscriptionId,
            bytes32 gasLane,
            uint32 callbackGasLimit
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        Raffle raffle =
            new Raffle(entranceFee, interval, vrfCoordinatorAddress, subscriptionId, gasLane, callbackGasLimit);
        vm.stopBroadcast();

        return raffle;
    }
}
