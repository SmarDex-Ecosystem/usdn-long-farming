// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongStakingErrors
 * @notice Interface for the USDN Long Staking errors.
 */
interface IUsdnLongStakingErrors {
    /// @dev The USDN protocol position is owned by the contract.
    error UsdnLongStakingContractOwned();

    /// @dev The USDN protocol position validation is pending.
    error UsdnLongStakingPendingPosition();
}
