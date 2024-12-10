#!/usr/bin/env bash
# Path of the script folder (so that the script can be invoked from somewhere else than the project's root)
scriptDir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

# Execute in the context of the project's root
pushd $scriptDir/..

# Anvil RPC URL
rpcUrl=http://localhost:8545
# Anvil first test private key
deployerPrivateKey=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Setup deployment script environment variables
export DEPLOYER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

forge script --non-interactive --private-key "$deployerPrivateKey" -f "$rpcUrl" script/01_Deploy.s.sol:Deploy --broadcast

popd
