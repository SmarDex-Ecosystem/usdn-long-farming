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
     * @notice The rewards are sent to the owner of the position.
     * @param user The address of the position owner.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param rewards The rewards amount transferred.
     */
    event Harvest(address indexed user, bytes32 indexed positionIdHash, uint256 rewards);

    /**
     * @notice The position has been deleted, and the notifier has received part of the rewards.
     * @param notifier The address of the notifier.
     * @param positionIdHash The hash of the USDN protocol position.
     * @param notifierRewards The amount of rewards received by the notifier.
     * @param rewardsToBurn  Amount sent to the dead address.
     */
    event Slash(address indexed notifier, bytes32 positionIdHash, uint256 notifierRewards, uint256 rewardsToBurn);
}
