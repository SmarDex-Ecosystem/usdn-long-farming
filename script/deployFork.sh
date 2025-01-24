#!/usr/bin/env bash
# Path of the script folder (so that the script can be invoked from somewhere else than the project's root)
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
# Execute in the context of the project's root
pushd $SCRIPT_DIR/.. >/dev/null

# Anvil RPC URL
rpcUrl=http://localhost:8545
# Anvil first test private key
deployerPrivateKey=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Setup deployment script environment variables
export DEPLOYER_ADDRESS=$(cast wallet address --private-key "$deployerPrivateKey") #0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export USDN_PROTOCOL_ADDRESS=0x656cB8C6d154Aad29d8771384089be5B5141f01a

# Deploy the farming token
forge script --non-interactive --private-key "$deployerPrivateKey" -f "$rpcUrl" script/01_DeployFarmingToken.s.sol:DeployFarmingToken --broadcast

# Get the farming token address
chainId=$(cast chain-id -r "$rpcUrl")
DEPLOYMENT_LOG=$(cat "broadcast/01_DeployFarmingToken.s.sol/$chainId/run-latest.json")
export FARMING_TOKEN_ADDRESS=$(echo "$DEPLOYMENT_LOG" | jq '.returns.farmingToken_.value' | xargs printf "%s\n")

# Send ETH to the Smardex Safe
cast send 0x1E3e1128F6bC2264a19D7a065982696d356879c5 --private-key "$deployerPrivateKey" --value 10ether -r "$rpcUrl" >/dev/null

# Add the campaign
forge script --sender 0x1e3e1128f6bc2264a19d7a065982696d356879c5 --non-interactive -f "$rpcUrl" script/50_AddCampaign.s.sol:AddCampaign --broadcast --unlocked

# Deploy the USDN long farming
forge script --non-interactive --private-key "$deployerPrivateKey" -f "$rpcUrl" script/02_DeployUsdnLongFarming.s.sol:DeployUsdnLongFarming --broadcast

popd
