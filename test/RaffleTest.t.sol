// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";

contract RaffleTest is Test {
    DeployRaffle deployer;
    Raffle raffle;

    function setUp() external {
        deployer = new DeployRaffle();
        raffle = deployer.run();
    }

    function test_EntranceFee_IsSet() public {
        uint256 actualEntranceFee = 1e16; // 0.01 ether
        uint256 raffleEntranceFee = raffle.getEntranceFee();
        assertEq(actualEntranceFee, raffleEntranceFee);
    }
}
