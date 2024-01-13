// Refer RaffleWorkflow for deployment details

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";

/// @title HelperConfig contract
/// @author Prince Allwin
/// @notice HelperConfig provides necessary to the DeployRaffle contract
contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinatorAddress;
        uint64 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 private constant ENTRANCE_FEE = 1e16; // 0.01ether
    uint256 private constant INTERVAL = 30; // 30seconds

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getETHMainnetConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getETHMainnetConfig() private pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            entranceFee: ENTRANCE_FEE,
            interval: INTERVAL,
            vrfCoordinatorAddress: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            subscriptionId: 0,
            gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            callbackGasLimit: 500000, //500,000 gas
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });

        return mainnetConfig;
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            entranceFee: ENTRANCE_FEE,
            interval: INTERVAL,
            vrfCoordinatorAddress: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId: 0, // If subId is 0 subId will be programatically generated
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000, //500,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });

        return sepoliaConfig;
    }

    // To get vrfCoordinatorAddress locally we have to deploy docs
    function getOrCreateAnvilConfig() private returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return activeNetworkConfig;
        }

        /// @dev https://docs.chain.link/vrf/v2/subscription/examples/test-locally
        uint96 baseFee = 25e17; // 0.25ether
        uint96 gasPriceLink = 1e9; // 1 gwei

        /// @dev deploying VRFCoordinatorV2Mock contract
        /// @dev deploying MockLinkToken
        vm.startBroadcast();
        VRFCoordinatorV2Mock vRFCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        MockLinkToken mockLinkToken = new MockLinkToken();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            entranceFee: ENTRANCE_FEE,
            interval: INTERVAL,
            vrfCoordinatorAddress: address(vRFCoordinatorV2Mock), // mocks
            subscriptionId: 0, // mocks
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000, //500,000 gas
            link: address(mockLinkToken)
        });

        return anvilConfig;
    }
}
