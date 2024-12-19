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
     * @param rewards The rewards amount transferred.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    event Harvest(address indexed user, uint256 rewards, int24 tick, uint256 tickVersion, uint256 index);

    /**
     * @notice The position has been deleted, and the notifier has received part of the rewards.
     * @param notifier The address of the notifier.
     * @param notifierRewards The amount of rewards received by the notifier.
     * @param burnedTokens  Amount sent to the dead address.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
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
