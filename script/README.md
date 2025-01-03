# Scripts

## Deploy the Long USDN Protocol Farming

### Production Mode

For a mainnet deployment, there are three mandatory steps to be run in the following order:

1. Deploy the farming token.
2. Add the campaign in the Smardex farming contract.
3. Deploy the long USDN protocol farming contract.

---

#### 1. Deploy the Farming Token

The deployment can be done by running the `01_DeployFarmingToken.s.sol` script:

```shell
forge script script/01_DeployFarmingToken.s.sol --private-key P_KEY -f RPC_URL --broadcast
```

- The environment variable `DEPLOYER_ADDRESS` is mandatory. If not set, a prompt will request it.

---

#### 2. Add the Campaign to the Smardex Farming Contract

This step must be performed via the Smardex Safe on mainnet.

For a fork, you can use the `50_AddCampaign.s.sol` script:

```shell
forge script script/50_AddCampaign.s.sol:AddCampaign --sender 0x1e3e1128f6bc2264a19d7a065982696d356879c5 -f RPC_URL --broadcast --unlocked
```

- The environment variable `FARMING_TOKEN_ADDRESS` is mandatory. If not set, a prompt will request it.
- This script works only on a fork that supports impersonation.
- Ensure the Safe has sufficient ETH to pay for the transaction.

---

#### 3. Deploy the Long USDN Protocol Farming

Run the following command to deploy the long USDN protocol farming contract:

```shell
forge script script/02_DeployUsdnLongFarming.s.sol --private-key P_KEY -f RPC_URL --broadcast
```

- The following environment variables are mandatory:
  - `FARMING_TOKEN_ADDRESS`
  - `DEPLOYER_ADDRESS`
  - `USDN_PROTOCOL_ADDRESS`
- If these variables are not set, a prompt will request them.

---

### Fork mode

For fork mode, the deployment script does not require any additional input:

```shell
deployFork.sh
```

## Anvil fork configuration

Anvil Fork Configuration
To configure the anvil fork, launch it with at least the following parameters:

- `-f <Mainnet RPC URL>`: Fork mainnet at the latest block height.
- `--auto-impersonate`: Enable address impersonation, such as the Safe address.

```bash
anvil -f [Mainnet RPC] --auto-impersonate
```
