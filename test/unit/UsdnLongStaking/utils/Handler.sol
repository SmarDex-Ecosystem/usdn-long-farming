// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { MockFarmingRange } from "./MockFarmingRange.sol";

import { UsdnLongStaking } from "../../../../src/UsdnLongStaking.sol";
import { IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongStakingHandler
 * @dev Utils for testing the USDN Long Staking
 */
contract UsdnLongStakingHandler is UsdnLongStaking {
    constructor(MockFarmingRange farming) UsdnLongStaking(IFarmingRange(address(farming)), 0) { }
}
