// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

///@dev Refer RaffleWorkflow.md

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

/// @title Deploy Raffle contract
/// @author Prince Allwin
/// @notice Using DeployRaffle contract raffle can be programatically deployed
contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinatorAddress,
            uint64 subscriptionId,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            /// @dev Creating Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinatorAddress);

            /// @dev Funding Subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorAddress, subscriptionId, link);
        }

        vm.startBroadcast();
        Raffle raffle =
            new Raffle(entranceFee, interval, vrfCoordinatorAddress, subscriptionId, gasLane, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(subscriptionId, address(raffle), vrfCoordinatorAddress);

        return (raffle, helperConfig);
    }
}
