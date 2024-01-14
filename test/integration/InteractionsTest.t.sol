// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract InteractionsTest is Test {
    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    DeployRaffle deployer;
    HelperConfig helperConfig;
    Raffle raffle;

    address vrfCoordinatorAddress;
    address link;
    address deployerKey;

    //////////////////////////////////////////////////////////
    //////////////////////  setUp  ///////////////////////////
    //////////////////////////////////////////////////////////

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (,, vrfCoordinatorAddress,,,, link, deployerKey) = helperConfig.activeNetworkConfig();
    }

    function test_CreateSubscription_CreatesNewSubId() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.createSubscription(vrfCoordinatorAddress, deployerKey);
        assertTrue(subId != 0, "CreateSubscription");
    }

    function test_CreateSubscription_CreatesNewSubId_WithConfig() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.createSubscriptionUsingConfig();
        assertTrue(subId != 0, "CreateSubscriptionWithConfig");
    }

    function test_FundSubscription_FundsSubId() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.run();

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinatorAddress, subId, link, deployerKey);
    }

    function test_AddConsumer_AddsTheConsumer() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subId = createSubscription.run();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(subId, address(raffle), vrfCoordinatorAddress, deployerKey);
    }
}
