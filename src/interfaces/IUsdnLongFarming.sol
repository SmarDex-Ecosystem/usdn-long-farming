// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC165, IOwnershipCallback } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IOwnershipCallback.sol";

import { IUsdnLongFarmingErrors } from "./IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "./IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "./IUsdnLongFarmingTypes.sol";

/**
 * @title USDN Long Farming Interface
 * @notice Interface for the USDN Long Farming contract.
 */
interface IUsdnLongFarming is
    IUsdnLongFarmingTypes,
    IUsdnLongFarmingErrors,
    IUsdnLongFarmingEvents,
    IERC165,
    IOwnershipCallback
{
    /**
     * @notice Sets the rewards factor for notifiers.
     * @param notifierRewardsBps The notifier rewards factor value, in basis points.
     */
    function setNotifierRewardsBps(uint16 notifierRewardsBps) external;

    /**
     * @notice Retrieves the information of a deposited USDN protocol position.
     * @param tick The tick of the position in the USDN protocol.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     * @return info_ The information of the specified position.
     */
    function getPositionInfo(int24 tick, uint256 tickVersion, uint256 index)
        external
        view
        returns (PositionInfo memory info_);

    /**
     * @notice Gets the total number of deposited positions.
     * @return count_ The total count of deposited positions.
     */
    function getPositionsCount() external view returns (uint256 count_);

    /**
     * @notice Gets the total shares of all deposited positions.
     * @dev Shares represent the trading exposure of deposited USDN positions.
     * @return shares_ The total shares of all positions.
     */
    function getTotalShares() external view returns (uint256 shares_);

    /**
     * @notice Gets the value of the rewards per share accumulator.
     * @dev This value represents the cumulative rewards per share, scaled for precision. It is updated before each user
     * action.
     * @return accRewardPerShare_ The value of the rewards per share accumulator.
     */
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_);

    /**
     * @notice Gets the block number when the rewards accumulator was last updated.
     * @dev This value is updated before each user action.
     * @return block_ The block number of the last update.
     */
    function getLastRewardBlock() external view returns (uint256 block_);

    /**
     * @notice Gets the current notifier rewards factor, in basis points.
     * @return notifierRewardsBps_ The current notifier rewards factor value.
     */
    function getNotifierRewardsBps() external view returns (uint16 notifierRewardsBps_);

    /**
     * @notice Calculates the pending rewards for a specific position.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     * @return rewards_ The amount of pending rewards for the position.
     */
    function pendingRewards(int24 tick, uint256 tickVersion, uint256 index) external view returns (uint256 rewards_);

    /**
     * @notice Withdraws a USDN protocol position and claims its rewards.
     * @dev If the position is not liquidated, rewards are sent to the position's owner, and the position is withdrawn.
     * If liquidated, rewards are distributed to `msg.sender` and `DEAD_ADDRESS`, and the position is deleted.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     * @return isLiquidated_ Indicates whether the position was liquidated.
     * @return rewards_ The amount of rewards sent to the position's owner. Returns 0 if liquidated.
     */
    function withdraw(int24 tick, uint256 tickVersion, uint256 index)
        external
        returns (bool isLiquidated_, uint256 rewards_);

    /**
     * @notice Claims rewards for a USDN protocol position and updates its status.
     * @dev If the position is not liquidated, rewards are sent to the owner, and `rewardDebt` is updated. If
     * liquidated, rewards are distributed to `msg.sender` and `DEAD_ADDRESS`, and the position is deleted. This
     * function can notify the farming protocol of a liquidation and reward the notifier.
     * If there are no pending rewards, this function will not perform any actions. However, calling the function may
     * still incur a transaction fee.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     * @return isLiquidated_ Indicates whether the position was liquidated.
     * @return rewards_ The amount of rewards sent to the position's owner. Returns 0 if liquidated.
     */
    function harvest(int24 tick, uint256 tickVersion, uint256 index)
        external
        returns (bool isLiquidated_, uint256 rewards_);
}
