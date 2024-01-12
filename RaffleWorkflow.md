# Proveably Raffle Contract

## About

This code is to create a proveably random smart contract lottery

## What we want it to do?

1. Users can enter by paying for a ticket
    1. The ticket fees are going to the winner during the draw.
2. After X period of time, the lottery will automatically draw a winner
    1. And this will be done programatically
3. Using Chainlink VRF & Chainlink Automation
    1. Chainlink VRF(Verifiable Random Function) -> Randomness
    2. Chainlink Automation -> Time based trigger

## Deployment

1. Get the current chainid

2. If it is ETH Mainnet

    1. Get the necessary parameters for chainlink VRF & Automation
    2. https://docs.chain.link/vrf/v2/subscription/supported-networks/#ethereum-mainnet

3. If it is Sepolia

    1. Get the necessary parameters for chainlink VRF & Automation
    2. https://docs.chain.link/vrf/v2/subscription/supported-networks/#sepolia-testnet

4. If it is Anvil
    1. Deploy mocks for VRF
    2. Deploy mocks for Automation
    3. https://docs.chain.link/vrf/v2/subscription/examples/test-locally

## Tests!

1. Write some deploy scripts
2. Write our tests
    1. Work on a local chain
    2. Forked Testnet
    3. Forked Mainnet
