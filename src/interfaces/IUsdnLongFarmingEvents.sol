// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title USDN Long Farming Events
 * @dev Defines all custom events emitted by the USDN Long Farming contract.
 */
interface IUsdnLongFarmingEvents {
    /**
     * @notice A USDN protocol user position has been deposited into the contract.
     * @param owner The owner of the deposited USDN protocol position.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     */
    event Deposit(address indexed owner, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice A USDN protocol user position has been withdrawn from the contract.
     * @param owner The address of the position owner.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     */
    event Withdraw(address indexed owner, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice The rewards have been sent to the owner of a position.
     * @param user The address of the position owner.
     * @param rewards The amount of rewards transferred.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     */
    event Harvest(address indexed user, uint256 rewards, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice A position has been deleted and the notifier has received part of the rewards.
     * @param notifier The address of the notifier.
     * @param notifierRewards The amount of rewards received by the notifier.
     * @param burnedTokens The amount sent to the dead address.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position within the tick.
     */
    event Slash(
        address indexed notifier,
        uint256 notifierRewards,
        uint256 burnedTokens,
        int24 tick,
        uint256 tickVersion,
        uint256 index
    );

    /**
     * @notice The notifier rewards factor has been updated.
     * @param newNotifierRewardsBps The new notifier rewards factor value, in basis points.
     */
    event NotifierRewardsBpsUpdated(uint16 newNotifierRewardsBps);
}
