// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongStakingTypes
 * @notice Interface for the USDN Long Staking types.
 */
interface IUsdnLongStakingTypes {
    /// @dev The `PositionId` is destructured into its individual components to pack the struct more closely.
    struct PositionInfo {
        address owner; // 20 bytes
        int24 tick; // 3 bytes
        uint256 tickVersion;
        uint256 index;
        uint256 rewardDebt;
        uint128 shares; // 16 bytes
    }
}
