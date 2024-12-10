# <h1 align="center">RA2 Tech Foundry Template</h1>

[![Main workflow](https://github.com/Blockchain-RA2-Tech/foundry-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Blockchain-RA2-Tech/foundry-template/actions/workflows/ci.yml)
[![Release Workflow](https://github.com/Blockchain-RA2-Tech/foundry-template/actions/workflows/release.yml/badge.svg)](https://github.com/Blockchain-RA2-Tech/foundry-template/actions/workflows/release.yml)

## Installation

### Foundry

To install Foundry, run the following commands in your terminal:

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Just

We use [`just`](https://github.com/casey/just) to expose some useful commands and for pre-commit hooks. It can be
installed with `apt` or `nix` (see dev shell info below):

```bash
sudo apt install just
```

### Dependencies

To install existing dependencies, run the following commands:

```bash
forge soldeer install
npm install
```

In order to add a new dependency, use the `forge soldeer install [packagename]~[version]` command with any package
from the [soldeer registry](https://soldeer.xyz).

For instance, to add the latest [OpenZeppelin library](https://github.com/OpenZeppelin/openzeppelin-contracts):

```bash
forge soldeer install @openzeppelin-contracts~5
```

Git repositories can also be used as a source:

```bash
soldeer install @openzeppelin-contracts-v4~4.9.6 https://github.com/OpenZeppelin/openzeppelin-contracts.git --tag v4.9.6
```

### Nix

If using [`nix`](https://nixos.org/), the repository provides a development shell in the form of a flake.

The devshell can be activated with the `nix develop` command.

To automatically activate the dev shell when opening the workspace, install [`direnv`](https://direnv.net/)
(available on nixpkgs) and run the following command inside this folder:

```bash
direnv allow
```

The environment provides the following tools:

- load `.env` file as environment variables
- foundry
- slither
- Node 20 / Typescript
- just
- TruffleHog
- lcov

## Usage

### Snapshots

The CI checks that there was no unintended regression in gas usage. To do so, it relies on the `.gas-snapshot` file
which records gas usage for all tests. When tests have changed, a new snapshot should be generated with the
`npm run snapshot` command and commited to the repo.

### Deployment scripts

Deployment for anvil forks should be done with a custom bash script at `script/deployFork.sh` which can be run without
arguments. It must set up any environment variable required by the foundry deployment script.

Common arguments to `forge script` are described in
[the documentation](https://book.getfoundry.sh/reference/forge/forge-script#forge-script).

Notably, the `--rpc-url` argument allows to choose which RPC will receive the transactions. The available shorthand
names are defined in [`foundry.toml`](https://github.com/petra-foundation/foundry-template/blob/master/foundry.toml),
(e.g. `mainnet`, `sepolia`) and use URLs defined as environment variables (see `.env.example`).

## Foundry Documentation

For comprehensive details on Foundry, refer to the [Foundry book](https://book.getfoundry.sh/).

### Helpful Resources

- [Forge Cheat Codes](https://book.getfoundry.sh/cheatcodes/)
- [Forge Commands](https://book.getfoundry.sh/reference/forge/)
- [Cast Commands](https://book.getfoundry.sh/reference/cast/)

## Code Standards and Tools

### Forge Formatter

Foundry comes with a built-in code formatter that we configured like this (default values were omitted):

```toml
[profile.default.fmt]
line_length = 120 # Max line length
bracket_spacing = true # Spacing the brackets in the code
wrap_comments = true # use max line length for comments as well
number_underscore = "thousands" # add underscore separators in large numbers
```

### TruffleHog

[TruffleHog](https://github.com/trufflesecurity/trufflehog) scans the files for leaked secrets. It is installed by the
nix devShell, and can otherwise be installed with one of the commands below:

```bash
# install via brew
brew install trufflehog
# install via script
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
```

### Husky

The pre-commit configuration for Husky runs `forge fmt --check` to check the code formatting before each commit, and
`just trufflehog` to detect leaked secrets.

In order to setup the git pre-commit hook, you need to first install foundry, just and TruffleHog, then run
`npm install`.

### Slither

Slither is integrated into a GitHub workflow and runs on every push to the master branch.
