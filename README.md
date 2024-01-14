# Proveably Raffle Contract

```sh
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $SEPOLIA_RPC_URL --account $ACCOUNT_FOR_SEPOLIA --sender $SEPOLIA_KEYCHAIN --broadcast --verify $ETHERSCAN_API_KEY
```

```sh
forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $ANVIL_RPC_URL --account $ACCOUNT_FOR_ANVIL --sender $ANVIL_KEYCHAIN --broadcast
```

```
forge coverage --report debug > coverage.txt
```
