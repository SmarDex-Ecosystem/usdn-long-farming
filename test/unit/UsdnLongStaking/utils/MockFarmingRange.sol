// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { MockRewardToken } from "./MockRewardToken.sol";

import { FarmingToken } from "../../../../src/FarmingToken.sol";
import { IERC20, IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

contract MockFarmingRange {
    MockRewardToken internal _rewardToken;
    FarmingToken internal _farmingToken;

    constructor(MockRewardToken rewardToken, FarmingToken farmingToken) {
        _rewardToken = rewardToken;
        _farmingToken = farmingToken;
    }

    function campaignInfo(uint256) external view returns (IFarmingRange.CampaignInfo memory info_) {
        info_.stakingToken = IERC20(_farmingToken);
        info_.rewardToken = IERC20(_rewardToken);
    }

    function deposit(uint256, uint256) external { }
}
