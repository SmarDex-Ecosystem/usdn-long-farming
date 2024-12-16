// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";

import { MockFarmingRange } from "./MockFarmingRange.sol";
import { MockUsdnProtocol } from "./MockUsdnProtocol.sol";

import { UsdnLongStaking } from "../../../../src/UsdnLongStaking.sol";
import { IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongStakingHandler
 * @dev Utils for testing the USDN Long Staking
 */
contract UsdnLongStakingHandler is UsdnLongStaking {
    constructor(MockUsdnProtocol usdnProtocol, MockFarmingRange farming)
        UsdnLongStaking(IUsdnProtocol(address(usdnProtocol)), IFarmingRange(address(farming)), 0)
    { }

    function i_updateRewards() external {
        _updateRewards();
    }

    function setTotalShares(uint256 totalShares) external {
        _totalShares = totalShares;
    }
}
