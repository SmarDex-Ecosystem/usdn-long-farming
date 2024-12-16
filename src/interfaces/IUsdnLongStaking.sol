// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IUsdnLongStakingErrors } from "./IUsdnLongStakingErrors.sol";
import { IUsdnLongStakingEvents } from "./IUsdnLongStakingEvents.sol";
import { IUsdnLongStakingTypes } from "./IUsdnLongStakingTypes.sol";

/**
 * @title IUsdnLongStaking
 * @notice Interface for the USDN Long Staking.
 */
interface IUsdnLongStaking is IUsdnLongStakingTypes, IUsdnLongStakingErrors, IUsdnLongStakingEvents {
    /**
     * @notice Gets the deposited position info of the USDN protocol position.
     * @param posHash The position obtained using {hashPositionId}.
     * @return posInfo_ The position info.
     */
    function getPositionInfo(bytes32 posHash) external view returns (PositionInfo memory posInfo_);

    /**
     * @notice Gets the current deposited position count.
     * @return positionsCount_ The position count value.
     */
    function getPositionsCount() external view returns (uint256 positionsCount_);

    /**
     * @notice Gets the current deposited total shares.
     * @dev Shares represents the deposited amount of the USDN protocol position trading expo.
     * @return totalShares_ The total shares value.
     */
    function getTotalShares() external view returns (uint256 totalShares_);

    /**
     * @notice Gets the rewards per share accumulator.
     * @dev Represents the sum of the rewards by periods of blocks divided by this corresponding period total shares.
     * This is updated each user action.
     * @return accRewardPerShare_ The accumulator value.
     */
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_);

    /**
     * @notice Gets the last reward block took into account by the current reward per share accumulator.
     * This is updated each user action.
     * @return lastRewardBlock_ The last reward block value.
     */
    function getLastRewardBlock() external view returns (uint256 lastRewardBlock_);

    /**
     * @notice Gets a USDN protocol position hash.
     * @dev The hash is built using `keccak256(abi.encode(tick, tickVersion, index))`.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The position hash value.
     */
    function getPosIdHash(int24 tick, uint256 tickVersion, uint256 index) external pure returns (bytes32 hash_);

    /**
     * @notice Deposits a usdn protocol position to receive some rewards.
     * @dev Takes into account the current position trading expo as shares. Uses a delegation signature
     * to transfer the position ownership. Reverts if the position is already owned by the
     * contract, if the position is pending or if the trading expo is invalid.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return success_ Whether the deposit was successful.
     */
    function deposit(int24 tick, uint256 tickVersion, uint256 index, bytes calldata delegation)
        external
        returns (bool success_);

    /**
     * @notice Sends rewards to the position's owner.
     * @dev position's rewardDebt is updated.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function harvest(int24 tick, uint256 tickVersion, uint256 index) external;
}
