// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUsdnLongFarmingEvents {
    /**
     * @notice A USDN protocol user position has been deposited into the contract.
     * @param owner The prior USDN protocol deposited position owner.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    event Deposit(address indexed owner, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice The depositor of a USDN protocol position has received rewards.
     * @param user The USDN protocol position owner.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param rewards The rewards amount transferred.
     */
    event Harvest(address indexed user, bytes32 indexed positionIdHash, uint256 rewards);

    /**
     * @notice The position has been deleted, and the liquidator received part of the rewards.
     * @param liquidator The address of the liquidator.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param liquidatorRewards The amount of rewards received by the liquidator.
     * @param burned Amount sent to the dead address.
     */
    event Liquidate(address indexed liquidator, bytes32 positionIdHash, uint256 liquidatorRewards, uint256 burned);
}
