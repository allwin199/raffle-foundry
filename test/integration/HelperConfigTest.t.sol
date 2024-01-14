// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig helperConfig;

    function setUp() external {
        helperConfig = new HelperConfig();
    }

    function test_AnvilConfig_IsSet() public {
        HelperConfig.NetworkConfig memory anvilConfig = helperConfig.getOrCreateAnvilConfig();

        address vrfCoordinatorAddress = anvilConfig.vrfCoordinatorAddress;
        assertTrue(vrfCoordinatorAddress != address(0), "vrfCoordinatorAddressAnvil");
    }

    function test_SepoliaConfig_IsSet() public {
        HelperConfig.NetworkConfig memory sepoliaConfig = helperConfig.getSepoliaConfig();

        address vrfCoordinatorAddress = sepoliaConfig.vrfCoordinatorAddress;
        assertTrue(vrfCoordinatorAddress != address(0), "vrfCoordinatorAddressSepolia");
    }

    function test_MainnetConfig_IsSet() public {
        HelperConfig.NetworkConfig memory mainnetConfig = helperConfig.getETHMainnetConfig();

        address vrfCoordinatorAddress = mainnetConfig.vrfCoordinatorAddress;
        assertTrue(vrfCoordinatorAddress != address(0), "vrfCoordinatorAddressMainnet");
    }
}
