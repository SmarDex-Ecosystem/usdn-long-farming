// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { MockRewardToken } from "./MockRewardToken.sol";

import { FarmingToken } from "../../../../src/FarmingToken.sol";
import { IERC20, IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

contract MockRewardsProvider {
    MockRewardToken internal _rewardToken;
    FarmingToken internal _farmingToken;
    uint256 internal _rewardsPerBlock = 5;
    uint256 internal _lastRewardsBlock;

    constructor(MockRewardToken rewardToken, FarmingToken farmingToken) {
        _rewardToken = rewardToken;
        _farmingToken = farmingToken;
    }

    function campaignInfo(uint256) external view returns (IFarmingRange.CampaignInfo memory info_) {
        info_.stakingToken = IERC20(_farmingToken);
        info_.rewardToken = IERC20(_rewardToken);
    }

    function deposit(uint256, uint256) external { }

    function harvest(uint256[] calldata) external {
        uint256 rewards = (block.number - _lastRewardsBlock) * _rewardsPerBlock;
        // to simulate a rewards token transfer to the farming
        _rewardToken.mint(address(this), rewards);
        _rewardToken.transfer(msg.sender, rewards);

        _lastRewardsBlock = block.number;
    }

    function pendingReward(uint256, address) external view returns (uint256) {
        return (block.number - _lastRewardsBlock) * _rewardsPerBlock;
    }

    function getRewardsPerBlock() external view returns (uint256) {
        return _rewardsPerBlock;
    }

    function setRewardsPerBlock(uint256 rewardsPerBlocks) external {
        _rewardsPerBlock = rewardsPerBlocks;
    }
}
