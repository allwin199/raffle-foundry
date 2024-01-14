// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract DeployRaffleTest is Test {
    Raffle raffle;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle,) = deployer.run();
    }

    function test_RaffleContract_IsDeployed() public {
        assertTrue(address(raffle) != address(0), "DeployRaffle");
    }
}
