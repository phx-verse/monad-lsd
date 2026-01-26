# How to deploy

First make sure you have set up your `.env` file with the necessary environment variables for deployment.

Required environment variables:

1. `MONAD_RPC_URL`
2. `ACCOUNTS_MNEMONIC` and `ACCOUNTS_PASSPHRASE` (`ACCOUNTS_PASSPHRASE` for testnet only)
3. `VALIDATOR_ID`

Then run the following commands in order:

1. `npx hardhat ignition deploy ignition/modules/DeployMonadLsdUpgradeable.ts --network monad`
2. `npx hardhat ignition deploy ignition/modules/SetupMonlsdUpgradeable.ts --network monad`

Add these environment variables after deployment:

`MON_LSD_ADDRESS`, `cMON`, and `PROXY_ADMIN`

## Upgrade Contract

`npx hardhat run scripts/upgrade-monad-lsd.ts --network monad`