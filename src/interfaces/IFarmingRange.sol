// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin-contracts-5/interfaces/IERC20.sol";

interface IFarmingRange {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct CampaignInfo {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
        uint256 totalRewards;
    }

    struct RewardInfo {
        uint256 endBlock;
        uint256 rewardPerBlock;
    }

    function rewardInfoLen(uint256 campaignID) external view returns (uint256);

    function campaignInfoLen() external view returns (uint256);

    function currentEndBlock(uint256 campaignID) external view returns (uint256);

    function currentRewardPerBlock(uint256 campaignID) external view returns (uint256);

    function getMultiplier(uint256 from, uint256 to, uint256 endBlock) external returns (uint256);

    function pendingReward(uint256 campaignID, address user) external view returns (uint256);

    function updateCampaign(uint256 campaignID) external;

    function massUpdateCampaigns() external;

    function deposit(uint256 campaignID, uint256 amount) external;

    function depositWithPermit(
        uint256 campaignID,
        uint256 amount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(uint256 campaignID, uint256 amount) external;

    function harvest(uint256[] calldata campaignIDs) external;

    function emergencyWithdraw(uint256 campaignID) external;

    function campaignRewardInfo(uint256 campaignID, uint256 rewardIndex)
        external
        view
        returns (uint256 endBlock, uint256 rewardPerBlock);

    function campaignInfo(uint256 campaignID) external view returns (CampaignInfo memory info_);

    function userInfo(uint256 campaignID, address user) external view returns (UserInfo memory info_);

    function rewardInfoLimit() external view returns (uint256);

    function rewardManager() external view returns (address);
}
