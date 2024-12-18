// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongStakingEvents
 * @notice Interface for the USDN Long Staking events.
 */
interface IUsdnLongStakingEvents {
    /**
     * @notice A USDN protocol user position has been deposited into the contract.
     * @param owner The prior USDN protocol deposited position owner.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    event Deposit(address indexed owner, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice The Ownership of a USDN protocol position has received accumulated rewards.
     * @param user The USDN protocol position owner.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param reward The reward amount transferred.
     */
    event Harvest(address indexed user, bytes32 positionIdHash, uint256 reward);

    /**
     * @notice The position has been deleted and the liquidator received part of rewards.
     * @param liquidator The address of the liquidator.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param liquidatorReward Amount received by the liquidator.
     * @param burned Amount sent to the dead address.
     */
    event Liquidate(address indexed liquidator, bytes32 positionIdHash, uint256 liquidatorReward, uint256 burned);
}
