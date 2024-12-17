// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongFarmingTypes
 * @notice Interface for the USDN Long Farming types.
 */
interface IUsdnLongFarmingTypes {
    /**
     * @notice The information of a staked position.
     * @dev The `PositionId` is destructured into its individual components to pack the struct more closely.
     * @param owner The address of the position owner.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position in the tick.
     * @param rewardDebt The reward debt of the position.
     * The amount of rewards entitled to a staked position at any time is defined as:
     * pendingRewards = (pos.shares * _accRewardPerShare) - pos.rewardDebt.
     * @param shares The initial trading exposure of the position, which constitutes its share in the farming.
     */
    struct PositionInfo {
        address owner; // 20 bytes
        int24 tick; // 3 bytes
        uint256 tickVersion;
        uint256 index;
        uint256 rewardDebt;
        uint128 shares; // 16 bytes
    }
}
