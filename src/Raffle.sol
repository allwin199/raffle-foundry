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
////////////////////  Custom Errors  /////////////////////
//////////////////////////////////////////////////////////
error Raffle__NotEnoughETHSent();

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2 and Automation
contract Raffle {
    //////////////////////////////////////////////////////////
    ////////// Constant & Immutable Variables  ///////////////
    //////////////////////////////////////////////////////////
    uint256 private immutable i_entranceFee;

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    address payable[] private s_players;
    ///@dev one of the player will be picked as winner and raffle_contract will pay that player. Therfore player[] has to marked as payable

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        /// @dev msg.sender will be of type address and we have to push this player in player[]
        /// @dev since player[] is payable, we have to typecast msg.sender to payable
        s_players.push(payable(msg.sender));

        /// @dev emit an event whenever there is a change in a storage variable
    }

    function pickWinner() external {}

    //////////////////////////////////////////////////////////
    ///////  external & public view & pure functions  ////////
    //////////////////////////////////////////////////////////
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
