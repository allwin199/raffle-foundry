// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

//////////////////////////////////////////////////////////
//////////////  Create Subscription  /////////////////////
//////////////////////////////////////////////////////////
contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinatorAddress, address deployer) public returns (uint64) {
        console.log("Creating Subscription on ChainId:", block.chainid);

        vm.startBroadcast(deployer);
        uint64 subId = VRFCoordinatorV2Interface(vrfCoordinatorAddress).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription Id:", subId);

        return subId;
    }

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorAddress,,,,, address deployer) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinatorAddress, deployer);
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

//////////////////////////////////////////////////////////
////////////////  Fund Subscription  /////////////////////
//////////////////////////////////////////////////////////
contract FundSubscription is Script {
    uint96 public constant FUNDING_AMOUNT = 3e18; // 3 ether

    function fundSubscription(address vrfCoordinatorAddress, uint64 subId, address link, address deployer) public {
        console.log("Funding subscription:", subId);
        console.log("Using vrfCoordinator:", vrfCoordinatorAddress);
        console.log("On ChainID:", block.chainid);
        LinkTokenInterface linkToken = LinkTokenInterface(link);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployer);
            VRFCoordinatorV2Mock(vrfCoordinatorAddress).fundSubscription(subId, FUNDING_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log("Sender:", msg.sender);
            console.log("Balance:", LinkTokenInterface(link).balanceOf(msg.sender));

            console.log("Link Token Address:", address(this));
            console.log("Balance:", LinkTokenInterface(link).balanceOf(address(this)));

            vm.startBroadcast(deployer);
            (bool success) = linkToken.transferAndCall(vrfCoordinatorAddress, FUNDING_AMOUNT, abi.encode(subId));
            console.log("Funding Status:", success);
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorAddress, uint64 subId,,, address link, address deployer) =
            helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinatorAddress, subId, link, deployer);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

//////////////////////////////////////////////////////////
////////////////////  Add Consumer  //////////////////////
//////////////////////////////////////////////////////////
contract AddConsumer is Script {
    function addConsumer(uint64 subId, address contractToAddToVrf, address vrfCoordinatorAddress, address deployer)
        public
    {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinatorAddress);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(deployer);
        VRFCoordinatorV2Interface(vrfCoordinatorAddress).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorAddress, uint64 subId,,,, address deployer) = helperConfig.activeNetworkConfig();
        addConsumer(subId, raffle, vrfCoordinatorAddress, deployer);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
