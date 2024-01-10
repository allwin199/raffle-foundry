# Chainlink VRF

-   VRF -> Verfiable Random Function

-   VRF uses VRFCoordinatorV2Interface and VRFConsumerBaseV2

## VRFCoordinatorV2Interface

-   VRFCoordinatorV2Interface allows to co-ordinate with the oracle network to get the random values
-   VRFConsumerBaseV2 has some specific functions which will help to request random values

## Workflow

-   Getting a random number is 2 transaction function

1.  Request the RNG
    -   we have to call requestRandomWords()
2.  Get the random number
    -   random number will be fullfilled in fulfillRandomWords()
