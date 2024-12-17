// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongFarmingErrors
 * @notice Interface for the USDN Long Farming errors.
 */
interface IUsdnLongFarmingErrors {
    /// @dev The USDN protocol position is owned by the contract.
    error UsdnLongFarmingAlreadyDeposited();

    /// @dev The USDN protocol position validation is pending.
    error UsdnLongFarmingPendingPosition();
}
