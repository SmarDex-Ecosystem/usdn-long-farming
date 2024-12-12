// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IFarmingRange, IERC20 } from "../../../../src/interfaces/IFarmingRange.sol";

contract MockFarmingRange {
    address internal _rewardToken;

    constructor(address rewardToken) {
        _rewardToken = rewardToken;
    }

    function campaignInfo(uint256) external view returns (IFarmingRange.CampaignInfo memory info_) {
        info_.rewardToken = IERC20(_rewardToken);
    }
}
