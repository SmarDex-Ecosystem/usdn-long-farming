// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC165, IOwnershipCallback } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IOwnershipCallback.sol";

import { IUsdnLongFarmingErrors } from "./IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "./IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "./IUsdnLongFarmingTypes.sol";

interface IUsdnLongFarming is
    IUsdnLongFarmingTypes,
    IUsdnLongFarmingErrors,
    IUsdnLongFarmingEvents,
    IERC165,
    IOwnershipCallback
{
    /**
     * @notice Sets the notifier rewards factor.
     * @param notifierRewardsBps The notifier rewards factor value, in basis points.
     */
    function setNotifierRewardsBps(uint16 notifierRewardsBps) external;

    /**
     * @notice Gets the deposited position info of the USDN protocol position.
     * @param posHash The hash of the position ID obtained using {hashPosId}.
     * @return info_ The position info.
     */
    function getPositionInfo(bytes32 posHash) external view returns (PositionInfo memory info_);

    /**
     * @notice Gets the number of deposited positions.
     * @return count_ The count of deposited positions.
     */
    function getPositionsCount() external view returns (uint256 count_);

    /**
     * @notice Gets the total shares of deposited positions.
     * @dev Shares represents the trading exposure of deposited USDN positions.
     * @return shares_ The sum of all positions' shares.
     */
    function getTotalShares() external view returns (uint256 shares_);

    /**
     * @notice Gets the value of the rewards per share accumulator.
     * @dev Represents the accumulated value of the rewards per share for each update interval, multiplied by a constant
     * for precision. This value is updated before each user action.
     * @return accRewardPerShare_ The accumulator value.
     */
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_);

    /**
     * @notice Gets the block number when the accumulator was last updated.
     * This value is updated before each user action.
     * @return block_ The block number of the update.
     */
    function getLastRewardBlock() external view returns (uint256 block_);

    /**
     * @notice Gets the current notifier rewards factor, in basis points.
     * @return notifierRewardsBps_ The notifier rewards factor value.
     */
    function getNotifierRewardsBps() external view returns (uint16 notifierRewardsBps_);

    /**
     * @notice Hashes the unique ID of a USDN position.
     * @dev The hash is computed using `keccak256(abi.encode(tick, tickVersion, index))`.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The hash of the ID.
     */
    function hashPosId(int24 tick, uint256 tickVersion, uint256 index) external pure returns (bytes32 hash_);

    /**
     * @notice Sends rewards to the position's owner.
     * @dev If the position is active (not liquidated), the rewards are sent to the position's owner and the position's
     * rewardDebt is updated to reflect the claimed rewards. If there're no pending rewards, this function will not
     * execute any action, but a transaction fee may still be incurred for calling the function. If the position has
     * been liquidated on the USDN protocol, the rewards are distributed to `msg.sender` and `DEAD_ADDRESS`, and the
     * position is deleted. Note: An user can therefore use this function to notify the farming protocol that a position
     * has been liquidated and be rewarded for this action.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return isLiquidated_ A flag indicating if the position was liquidated.
     * @return rewards_ The amount of rewards distributed to the position's owner. 0 if the position was liquidated.
     */
    function harvest(int24 tick, uint256 tickVersion, uint256 index)
        external
        returns (bool isLiquidated_, uint256 rewards_);
}
