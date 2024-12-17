// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongStakingEvents
 * @notice Interface for the USDN Long Staking events.
 */
interface IUsdnLongStakingEvents {
    /**
     * @notice A USDN protocol user position has been deposited into the contract.
     * @param user The prior USDN protocol deposited position user.
     * @param positionIdHash The hash of the USDN protocol deposited position.
     */
    event UsdnLongStakingDeposit(address indexed user, bytes32 positionIdHash);

    /**
     * @notice The Ownership of a USDN protocol position has received accumulated rewards.
     * @param user The USDN protocol position owner.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param reward The reward amount transferred.
     */
    event UsdnLongStakingHarvest(address indexed user, bytes32 positionIdHash, uint256 reward);

    /**
     * @notice The position has been deleted and the liquidator received part of rewards.
     * @param liquidator The address of the liquidator.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param liquidatorReward Amount received by the liquidator.
     * @param burned Amount sent to the dead address.
     */
    event UsdnLongStakingLiquidate(
        address indexed liquidator, bytes32 positionIdHash, uint256 liquidatorReward, uint256 burned
    );
}
