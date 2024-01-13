// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

//////////////////////////////////////////////////////////
////////////////////  Custom Errors  /////////////////////
//////////////////////////////////////////////////////////
error Raffle__NotEnoughETHSent();
error Raffle__Sending_RaffleAmountTo_WinnerFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract RaffleTest is Test {
    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    DeployRaffle deployer;
    HelperConfig helperConfig;
    Raffle raffle;

    address public player = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10e18; // 10 ether

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatorAddress;
    uint64 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    //////////////////////////////////////////////////////////
    //////////////////////  setUp  ///////////////////////////
    //////////////////////////////////////////////////////////

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinatorAddress, subscriptionId, gasLane, callbackGasLimit,) =
            helperConfig.activeNetworkConfig();

        // Let's give player some money
        vm.deal(player, STARTING_PLAYER_BALANCE);
    }

    //////////////////////////////////////////////////////////
    ///////////////////  Enter Raffle  ///////////////////////
    //////////////////////////////////////////////////////////

    function test_RaffleInitializesIn_OpenState() public {
        uint256 InitialRaffleState = raffle.getRaffleState();
        assertEq(InitialRaffleState, 0); // 0 -> OPEN // 1 -> CALCULATING
    }

    function test_EntranceFee_IsSet() public {
        uint256 raffleEntranceFee = raffle.getEntranceFee();
        assertEq(entranceFee, raffleEntranceFee);
    }

    function test_RevertIf_NotEnoughEth_ToEnter() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle();
    }

    modifier playerEntered() {
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        _;
    }

    function test_RevertIf_RaffleIsCalculating() public playerEntered {
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    function test_RaffleRecordsPlayer_WhenTheyEnter() public playerEntered {
        address mostRecentPlayer = raffle.getPlayer(0);
        assertEq(mostRecentPlayer, player);
    }

    function test_RaffleEmitsEvent_OnPlayerEntrance() public {
        vm.startPrank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();

        // Method 2
        // vm.startPrank(player);
        // vm.expectEmit({emitter: address(raffle)});
        // emit EnteredRaffle(player);
        // raffle.enterRaffle{value: entranceFee}();
        // vm.stopPrank();

        // vm.expectEmit(true, false, false, false);
        // 3 indexed parameters are allowed
        // vm.expectEmit(true, true, true, false)
        // all 3 indexed params which is also know as topics should be matched both in test case and the event emitted by contract
        // in this ex we are testing only one indexed parameter
        // (true, false, false, false, address(raffle))
        // finally address of the emitter

        // when we use vm.expectEmit();
        // we expect next line to emit (which is a event as we described)
        // It should emit when raffle.enterRaffle() is called

        // basically we are saying
        // when raffle.enterRaffle() is called
        // it shoudld emit an event such as
        // emit EnteredRaffle(player);

        // refer https://book.getfoundry.sh/forge/cheatcodes?highlight=expect%20emit#cheatcodes
        // examples https://book.getfoundry.sh/cheatcodes/expect-emit?highlight=expect%20emit#examples
    }
}
