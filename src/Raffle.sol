// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

/// @dev Refer RaffleWorkflow.md

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2 and Automation
contract Raffle is VRFConsumerBaseV2, AutomationCompatible {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error Raffle__NotEnoughETHSent();
    error Raffle__Sending_RaffleAmountTo_WinnerFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    //////////////////////////////////////////////////////////
    ////////////////  Type Declarations  /////////////////////
    //////////////////////////////////////////////////////////
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //////////////////////////////////////////////////////////
    ////////// Constant & Immutable Variables  ///////////////
    //////////////////////////////////////////////////////////
    // Constant
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Immutable
    uint256 private immutable i_entranceFee;
    /// @dev `i_interval` will determine the interval between each raffle draws
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vRFCoordinatorV2Interface;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    address payable[] private s_players;
    ///@dev one of the player will be picked as winner and raffle_contract will pay that player. Therfore player[] has to marked as payable

    /// @dev `s_lastWinnerPickedTimeStamp` stores the last time when the raffle was drawn.
    uint256 private s_lastWinnerPickedTimeStamp;
    address private s_recentWinner;

    RaffleState private s_currentRaffleState;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorAddress,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        /// @dev `s_lastTimeStamp` is set initially
        /// @dev when the contract gets deployed, the clock will start
        s_lastWinnerPickedTimeStamp = block.timestamp;
        s_currentRaffleState = RaffleState.OPEN;

        /// @dev vrf params
        i_vRFCoordinatorV2Interface = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
    }

    /// @dev enterRaffle is "payable" because users have to pay to enter the lottery.
    /// @dev reverts with a custom error if `msg.value` < `entranceFee`
    /// @dev reverts with a custom error if raffle state is not OPEN
    /// @dev player is added to the players[] if i_entrance fee is met
    /// @dev an event will be emitted after a player is added to players[]
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_currentRaffleState == RaffleState.CALCULATING) {
            revert Raffle__NotOpen();
        }
        /// @dev msg.sender will be of type address and we have to push this player in player[]
        /// @dev since player[] is payable, we have to typecast msg.sender to payable
        s_players.push(payable(msg.sender));

        /// @dev emit an event whenever there is a change in a storage variable
        emit EnteredRaffle(msg.sender);
    }

    //////////////////////////////////////////////////////////
    ///////////////  Chainlink Automation  ///////////////////
    //////////////////////////////////////////////////////////

    /// @dev This is the function that Chainlink Automation nodes call to see if it's time to perform an upkeep.
    /// @dev The following should be true for checkupkeep to return true
    /// 1. The time interval has passed between raffle draws
    /// 2. The raffle is in OPEN state
    /// 3. The contract has ETH (aka, players)
    /// 4. The subscription is funded with link(Implicit Check)
    /// @dev once the checkupkeep returns true, performupkeep will be called by chainlink nodes
    function checkUpkeep(bytes memory /*checkdata*/ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        /// @dev block.timestamp will denote the current time in seconds
        /// @dev s_lastTimeStamp will denote when was the previous raffle draw
        /// @dev to pick the winner again, enough time should be passed
        /// @dev all time units are measured in seconds

        /// eg: block.timestamp = 1000; s_lastTimeStamp = 500; i_interval = 600;
        /// 1000-500 = 500; 500 > 600 will be false, not enough time has passed;

        /// eg: block.timestamp = 1200; s_lastTimeStamp = 500; i_interval = 600;
        /// 1200-500 = 700; 700 > 600 will be true, enough time has passed;
        /// pick winner will be called

        uint256 currentTimeStamp = block.timestamp;
        bool enoughTimeHasPassed = (currentTimeStamp - s_lastWinnerPickedTimeStamp) >= i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool raffleIsOpen = s_currentRaffleState == RaffleState.OPEN;
        upkeepNeeded = (enoughTimeHasPassed && hasPlayers && hasBalance && raffleIsOpen);
        return (upkeepNeeded, "0x0");
        // (0x0) refers to blank bytes object
    }

    /// @dev when checkUpkeep return true, performUpkeep will be called
    /// @dev Inside performUpkeep we have requestRandomWords
    /// @dev the reason we are calling checkUpkeep inside the performUpkeep is,
    /// @dev since performUpkeep is an external function anyone can call this
    function performUpkeep(bytes calldata /*performData*/ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_currentRaffleState));
        }
        /// @dev since s_currentRaffleState is custom type, we are typecasting it to uint256

        // change raffle_state to calculating
        s_currentRaffleState = RaffleState.CALCULATING;

        uint256 requestId = i_vRFCoordinatorV2Interface.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
        // we are explicitly emitting RequestedRaffleWinner event
        // Note: requestRandomWords() also emits an event
        // Emitted events cannot be accessed inside the smart contract but can be accessed in Tests
    }

    //////////////////////////////////////////////////////////
    ///////////////////  Chainlink VRF  //////////////////////
    //////////////////////////////////////////////////////////

    /// @dev Refer VRFDetails.md

    /// @dev follows CEI -> Checks, Effects, Interactions
    /// @dev Chainlink vrf is a 2 transaction process.
    /// 1. Request the Random Number
    /// 2. Get the random number
    /// we will request the random number
    /// @dev callback fn from chainlink vrf will call the fulfillRandomWords to picking the actual winner.
    function fulfillRandomWords(uint256, /*_requestId*/ uint256[] memory randomWords) internal override {
        // Effects
        uint256 randomNumber = randomWords[0];
        // this randomNumber will be a huge number like 232324233
        // let's say we have 8 players in the raffle
        // to use the random number and pick a winner we have to use modulo operator
        // 232324233 % 8 = 1 player[1] is the winner
        // 23232589 % 8 = 5 player[5] is the winner
        // when we use num modulo 8 , the result will be between 0-7
        uint256 indexOfWinner = randomNumber % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        // once the winner is picked s_lastWinnerPickedTimeStamp should be rest to current timestamp
        // s_players[] should be reset
        s_players = new address payable[](0);

        // therfore we are restarting the clock
        s_lastWinnerPickedTimeStamp = block.timestamp;

        // change RaffleState to Open
        s_currentRaffleState = RaffleState.OPEN;

        emit PickedWinner(winner);

        // Interactions
        // send the raffle balance to the winner
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__Sending_RaffleAmountTo_WinnerFailed();
        }
    }

    //////////////////////////////////////////////////////////
    ///////  external & public view & pure functions  ////////
    //////////////////////////////////////////////////////////
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (uint256) {
        return uint256(s_currentRaffleState);
    }

    function getPlayer(uint256 playerIndex) external view returns (address) {
        return s_players[playerIndex];
    }

    function getNumPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastWinnerPickedTimeStamp() external view returns (uint256) {
        return s_lastWinnerPickedTimeStamp;
    }
}
