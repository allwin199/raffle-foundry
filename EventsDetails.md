# Events Details

-   EVM can emit logs

## Logs

-   It is possible to store data in a specially indexed data structure that maps all the way up to the block level.
-   This feature called logs is used by Solidity in order to implement events.
-   Contracts cannot access log data after it has been created, but they can be efficiently accessed from outside the blockchain.

## Events

-   Solidity events give an abstraction on top of the EVM’s logging functionality.
-   Applications can subscribe and listen to these events through the RPC interface of an Ethereum client.
-   When you call them, they cause the arguments to be stored in the transaction’s log - a special data structure in the blockchain.

-   You can add the attribute `indexed` to up to three parameters which adds them to a special data structure known as “topics” instead of the data part of the log
-   All parameters without the indexed attribute are ABI-encoded into the data part of the log.

-   Topics allow you to search for events, for example when filtering a sequence of blocks for certain events. You can also filter events by the address of the contract that emitted the event.

## Example

```sol
event storedNumber (
    uint256 indexed oldNumber,
    uint256 indexed newNumber,
    uint256 addedNumber,
    address sender
)

emit storedNumber(
    favouriteNumber,
    _favouriteNumber,
    favouriteNumber + _favouriteNumber,
    msg.sender
)
```

-   Event structure is created
-   By emitting this event this data will be stored as logs in the blockchain
