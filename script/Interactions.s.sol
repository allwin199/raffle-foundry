// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinatorAddress) private returns (uint64) {
        console.log("Creating Subscription on ChainId :", block.chainid);

        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Interface(vrfCoordinatorAddress).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription Id :", subId);

        return subId;
    }

    function createSubscriptionUsingConfig() private returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorAddress,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinatorAddress);
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUNDING_AMOUNT = 3e18; // 3 ether

    function fundSubscription(address vrfCoordinatorAddress, uint64 subId, address link) private {
        console.log("Funding Subscription:");
        LinkTokenInterface linkToken = LinkTokenInterface(link);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorAddress).fundSubscription(subId, FUNDING_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            (bool success) = linkToken.transferAndCall(vrfCoordinatorAddress, FUNDING_AMOUNT, abi.encode(subId));
            console.log("Funding Status:", success);
            vm.stopBroadcast();
        }

        console.log("Funding Completed");
    }

    function fundSubscriptionUsingConfig() private {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorAddress,,,, address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinatorAddress, 1, link);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
