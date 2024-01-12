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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//////////////////////////////////////////////////////////
////////////////////  Custom Errors  /////////////////////
//////////////////////////////////////////////////////////
error Raffle__NotEnoughETHSent();
error Raffle__Sending_RaffleAmountTo_WinnerFailed();
error Raffle__NotOpen();

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2 and Automation
contract Raffle is VRFConsumerBaseV2 {
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
    ///@dev interval will define how long will a lottery run in seconds
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
    uint256 private s_lastWinnerPickedTimeStamp;
    address private s_recentWinner;

    RaffleState private s_currentRaffleState;

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

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
        ///@dev once the contract is deployed we have to mark that time as lastWinnerPicked
        s_lastWinnerPickedTimeStamp = block.timestamp;
        s_currentRaffleState = RaffleState.OPEN;

        ///@dev vrf params
        i_vRFCoordinatorV2Interface = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
    }

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

    function requestRandomWords() private {
        i_vRFCoordinatorV2Interface.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    /// @dev follows CEI -> Checks, Effects, Interactions
    /// @dev we will call requestRandomWords()
    /// @dev fulfillRandomWords() will be called by chainlink node
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

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enough time has passed
        // to get the current timestamp block.timestamp can be used
        uint256 currentTimeStamp = block.timestamp;
        if (s_lastWinnerPickedTimeStamp + i_interval > currentTimeStamp) {
            // before picking up winner, we have to close to raffle otherwise someone could enter inbetween
            s_currentRaffleState = RaffleState.CALCULATING;
            requestRandomWords();
        }
        // let's say interval = 60s
        // lastWinnerPickedTimeStamp = 2000
        // currentTimeStamp = 3000
        // lastWinnerPickedTimeStamp + i_interval = 2000+60 = 2060
        // it is not greater than currentTimeStamp
        // therfore pickWinner will not be called
    }

    //////////////////////////////////////////////////////////
    ///////  external & public view & pure functions  ////////
    //////////////////////////////////////////////////////////
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
