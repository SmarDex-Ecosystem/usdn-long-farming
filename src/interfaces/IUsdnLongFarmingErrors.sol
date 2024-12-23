// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUsdnLongFarmingErrors {
    /// @dev The USDN protocol position is owned by the contract.
    error UsdnLongFarmingAlreadyDeposited();

    /// @dev The USDN protocol position validation is pending.
    error UsdnLongFarmingPendingPosition();

    /// @dev The caller is invalid.
    error UsdnLongFarmingInvalidCaller();

    /// @dev The USDN protocol position is invalid.
    error UsdnLongFarmingInvalidPosition();

    /// @dev The specified notifierRewardsBps is invalid.
    error UsdnLongFarmingInvalidNotifierRewardsBps();
}
