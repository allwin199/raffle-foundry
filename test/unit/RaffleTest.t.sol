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
import {MocksSendFailed} from "../mocks/MocksSendFailed.sol";

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

    modifier playerEnteredAndTimePassed() {
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);
        _;
    }

    function test_RevertIf_RaffleIsCalculating() public playerEnteredAndTimePassed {
        // Act
        raffle.performUpkeep("");

        // Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    function test_RaffleRecordsPlayer_WhenTheyEnter() public playerEnteredAndTimePassed {
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

    //////////////////////////////////////////////////////////
    ////////////////////  checkUpkeep  ///////////////////////
    //////////////////////////////////////////////////////////
    function test_CheckUpkeep_ReturnsFalse_IfNoBalance() public {
        // We have to make everything except balance to be true and check whether checkUpkeep returns false
        // Arrange
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpkeep_ReturnsFalse_IfNotEnoughHasTimePassed() public {
        // balance, players and raffleState is true only enoughTimeHasPassed will fail
        // Arrange
        vm.startPrank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpkeep_ReturnsFalse_IfRaffleNotOpen() public playerEnteredAndTimePassed {
        // enoughTimeHasPassed, balance, players are true only raffleState will fail

        raffle.performUpkeep("");
        // RaffleState will be changed to calculating

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpkeep_ReturnsTrue_IfAllConditionsAreMet() public playerEnteredAndTimePassed {
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assertEq(upkeepNeeded, true);
    }

    //////////////////////////////////////////////////////////
    ////////////////////  performUpkeep  /////////////////////
    //////////////////////////////////////////////////////////
    function test_PerformUpkeepRevertsIf_UpkeepNotNeeded() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState)
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepCanRun_OnlyIfCheckUpkeep_IsTrue() public playerEnteredAndTimePassed {
        // Act
        raffle.performUpkeep("");

        // Assert
        // If a test dosen't revert. Then that test is considered as pass
    }

    function test_RaffleStateIs_ChangedToCalculating_WhenUpkeepNeeded() public playerEnteredAndTimePassed {
        // Act
        raffle.performUpkeep("");

        uint256 raffleState = raffle.getRaffleState();
        // Assert
        assertEq(raffleState, 1);
        // If a test dosen't revert. Then that test is considered as pass
    }

    function test_PerformUpkeep_EmitsRequestId() public playerEnteredAndTimePassed {
        // Act
        vm.recordLogs();

        raffle.performUpkeep(""); // this fn will emit requestId

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        assertGt(uint256(requestId), 0);

        // To record any event emitted we have to use recordLogs();
        // using vm.getRecordedLogs we can access the recorded logs
        // In this example requestRandomWords() inside vrfCoordinator is emitting an event
        // Raffle is also emitting an event
        // since Raffle is emitting 2nd
        // We have to access entries[1]
        // In every entry topics[0] will be whole event
        // topics[1] will contain our requestId
        // all logs will be bytes32
    }

    //////////////////////////////////////////////////////////
    /////////////////  fulfillRandomWords  ///////////////////
    //////////////////////////////////////////////////////////

    modifier skipFork() {
        if (block.chainid != 31337) {
            vm.skip(true);
        }
        _;
    }
    // since there is no mocks in testnet
    // below test cases will fail
    // therfore we are skipping it while testing in testnet

    function test_FulfillRandomWords_CanOnlyBeCalled_AfterPerformUpkeep(uint256 randomRequestId)
        public
        playerEnteredAndTimePassed
        skipFork
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

    function test_fulfillRandomWords_PicksAWinner_ResetsAndSendMoney() public playerEnteredAndTimePassed skipFork {
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

    function test_SendingMoneyTo_WinnerFailed() public {
        MocksSendFailed mocksSendFailed = new MocksSendFailed();

        vm.deal(address(mocksSendFailed), STARTING_PLAYER_BALANCE);

        vm.startPrank(address(mocksSendFailed));
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();

        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 1);

        // let's get requestId using recordLogs
        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // vm.expectRevert(Raffle.Raffle__Sending_RaffleAmountTo_WinnerFailed.selector);
        // pretend to be the chainlink vrf to get random number & pick winner
        // fulfillRandomWords(uint256 _requestId, address _consumer) inside vrfMock
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(uint256(requestId), address(raffle));
    }
}
