// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleStagingTest is Test {
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
    address deployerKey;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    //////////////////////////////////////////////////////////
    //////////////////////  setUp  ///////////////////////////
    //////////////////////////////////////////////////////////

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinatorAddress, subscriptionId, gasLane, callbackGasLimit,, deployerKey) =
            helperConfig.activeNetworkConfig();

        // Let's give player some money
        vm.deal(player, STARTING_PLAYER_BALANCE);
    }

    modifier playerEnteredAndTimePassed() {
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);
        _;
    }

    //////////////////////////////////////////////////////////
    /////////////////  fulfillRandomWords  ///////////////////
    //////////////////////////////////////////////////////////

    modifier onlyOnDeployedContracts() {
        if (block.chainid == 31337) {
            vm.skip(true);
        }
        try vm.activeFork() returns (uint256) {
            vm.skip(true);
        } catch {
            _;
        }
    }
    // We want to this run only on deployed contracts.
    // Will it run for sepolia?

    function test_FulfillRandomWords_CanOnlyBeCalled_AfterPerformUpkeep_Staging(uint256 randomRequestId)
        public
        playerEnteredAndTimePassed
        onlyOnDeployedContracts
    {
        // This is where we try to have the mock call fulfillRandomWords and it should fail
        vm.expectRevert("nonexistent request"); // error from fulfillRandomWords in vrfCoordinator

        // The reason we want it to fail is
        // fulfillRandomwords can only be called when performUpkeep() returns true
        // Other times if fulfillRandomwords() is called it should fail

        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(randomRequestId, address(raffle));

        // by passing some values inside the params
        // this test will convert to Fuzz test
        // foundry will create some random values and test the required functions
    }

    function test_fulfillRandomWords_PicksAWinner_ResetsAndSendMoney_Staging()
        public
        playerEnteredAndTimePassed
        onlyOnDeployedContracts
    {
        // Arrange
        uint160 additionalEntrants = 5;

        for (uint160 playerIndex = 1; playerIndex < additionalEntrants; playerIndex++) {
            hoax(address(playerIndex), STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        // Making sure enough time has passed
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);

        uint256 prize = address(raffle).balance;

        // let's get requestId using recordLogs
        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousWinnerPickedTimeStamp = raffle.getLastWinnerPickedTimeStamp();

        // pretend to be the chainlink vrf to get random number & pick winner
        // fulfillRandomWords(uint256 _requestId, address _consumer) inside vrfMock
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(uint256(requestId), address(raffle));

        // The reason we can call fulfillRandomwords here is
        // we called performUpkeep before calling fulfillRandomwords

        uint256 raffleState = raffle.getRaffleState();
        assertEq(raffleState, 0); // 0 -> OPEN

        address recentWinner = raffle.getRecentWinner();
        assert(recentWinner != address(0));

        uint256 numPlayers = raffle.getNumPlayers();
        assertEq(numPlayers, 0);

        uint256 lastWinnerPickedTimeStamp = raffle.getLastWinnerPickedTimeStamp();
        assertGt(lastWinnerPickedTimeStamp, previousWinnerPickedTimeStamp);

        uint256 winnerBalance = address(recentWinner).balance;
        uint256 winnerBalanceAfterEntering = STARTING_PLAYER_BALANCE - entranceFee;
        uint256 winnerBalanceAfterWinning = winnerBalanceAfterEntering + prize;
        assertEq(winnerBalance, winnerBalanceAfterWinning);
    }
}
