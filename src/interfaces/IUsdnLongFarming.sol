// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IUsdnLongFarmingErrors } from "./IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "./IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "./IUsdnLongFarmingTypes.sol";

interface IUsdnLongFarming is IUsdnLongFarmingTypes, IUsdnLongFarmingErrors, IUsdnLongFarmingEvents {
    /**
     * @notice Sets the liquidator reward factor.
     * @param liquidatorRewardsBps The liquidator reward factor value, in basis points.
     */
    function setliquidatorRewardsBps(uint16 liquidatorRewardsBps) external;

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
     * @notice Gets the current liquidator reward factor, in basis points.
     * @return liquidatorRewardsBps_ The liquidator reward factor value.
     */
    function getliquidatorRewardsBps() external view returns (uint16 liquidatorRewardsBps_);

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
     * @notice Deposits a USDN protocol position to receive rewards.
     * @dev Takes into account the initial position trading expo as shares. Uses a delegation signature
     * to transfer the position ownership to this contract. Reverts if the position is already owned by the
     * contract or if the position is pending validation.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function deposit(int24 tick, uint256 tickVersion, uint256 index, bytes calldata delegation) external;

    /**
     * @notice Sends rewards to the position's owner.
     * @dev position's rewardDebt is updated.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function harvest(int24 tick, uint256 tickVersion, uint256 index) external;
}
