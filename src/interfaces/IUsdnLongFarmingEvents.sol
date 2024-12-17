// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IUsdnLongFarmingEvents
 * @notice Interface for the USDN Long Farming events.
 */
interface IUsdnLongFarmingEvents {
    /**
     * @notice A USDN protocol user position has been deposited into the contract.
     * @param owner The prior USDN protocol deposited position owner.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    event Deposit(address indexed owner, int24 tick, uint256 tickVersion, uint256 index);
}
