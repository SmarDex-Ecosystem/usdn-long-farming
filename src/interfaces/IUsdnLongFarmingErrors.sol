// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title USDN Long Farming Errors
 * @dev Al errors used in the USDN Long Farming contract.
 */
interface IUsdnLongFarmingErrors {
    /// @dev The USDN protocol position validation is pending.
    error UsdnLongFarmingPendingPosition();

    /// @dev The USDN protocol position does not exist.
    error UsdnLongFarmingInvalidPosition();

    /// @dev The specified `notifierRewardsBps` value is invalid.
    error UsdnLongFarmingInvalidNotifierRewardsBps();

    /// @dev The caller is not the owner of the USDN protocol position.
    error UsdnLongFarmingInvalidCaller();
}
