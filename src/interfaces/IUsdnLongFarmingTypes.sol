// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title USDN Long Farming Types
 * @dev Defines all custom types used by the USDN Long Farming contract.
 */
interface IUsdnLongFarmingTypes {
    /**
     * @notice Contains all information of a staked position.
     * @dev The `PositionId` is unpacked into its components to optimize storage layout.
     * @param owner The address of the position owner.
     * @param tick The tick of the position in the USDN protocol.
     * @param tickVersion The version of the tick.
     * @param index The position's index within the specified tick.
     * @param rewardDebt The cumulative rewards debt of the position.
     * Rewards entitled to a staked position at any point in time can be calculated as:
     * `pendingRewards = (pos.shares * _accRewardPerShare) - pos.rewardDebt`.
     * @param shares The initial trading exposure of the position, representing its share in the farming.
     */
    struct PositionInfo {
        address owner;
        int24 tick;
        uint256 tickVersion;
        uint256 index;
        uint256 rewardDebt;
        uint128 shares;
    }
}
