// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin-contracts-5/interfaces/IERC20.sol";

interface IFarmingRange {
    /**
     * @notice Info of each user.
     * @param amount How many Staking tokens the user has provided.
     * @param rewardDebt We do some fancy math here. Basically, any point in time, the amount of reward
     *  entitled to a user but is pending to be distributed is:
     *
     *    pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
     *
     *  Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *    1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
     *    2. User receives the pending reward sent to his/her address.
     *    3. User's `amount` gets updated.
     *    4. User's `rewardDebt` gets updated.
     *
     * from: https://github.com/jazz-defi/contracts/blob/master/MasterChefV2.sol
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /**
     * @notice Info of each reward distribution campaign.
     * @param stakingToken address of Staking token contract.
     * @param rewardToken address of Reward token contract
     * @param startBlock start block of the campaign
     * @param lastRewardBlock last block number that Reward Token distribution occurs.
     * @param accRewardPerShare accumulated Reward Token per share, times 1e20.
     * @param totalStaked total staked amount each campaign's stake token, typically,
     * @param totalRewards total amount of reward to be distributed until the end of the last phase
     */
    struct CampaignInfo {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
        uint256 totalRewards;
    }

    /**
     * @notice Info about a reward-phase
     * @param endBlock block number of the end of the phase
     * @param rewardPerBlock amount of reward to be distributed per block in this phase
     */
    struct RewardInfo {
        uint256 endBlock;
        uint256 rewardPerBlock;
    }

    /**
     * @notice emitted at each deposit
     * @param user address that deposit its funds
     * @param amount amount deposited
     * @param campaign campaingId on which the user has deposited funds
     */
    event Deposit(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each withdraw
     * @param user address that withdrawn its funds
     * @param amount amount withdrawn
     * @param campaign campaingId on which the user has withdrawn funds
     */
    event Withdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each emergency withdraw
     * @param user address that emergency-withdrawn its funds
     * @param amount amount emergency-withdrawn
     * @param campaign campaingId on which the user has emergency-withdrawn funds
     */
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each campaign added
     * @param campaignID new campaign id
     * @param stakingToken token address to be staked in this campaign
     * @param rewardToken token address of the rewards in this campaign
     * @param startBlock starting block of this campaign
     */
    event AddCampaignInfo(uint256 indexed campaignID, IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock);

    /**
     * @notice emitted at each phase of reward added
     * @param campaignID campaign id on which rewards were added
     * @param phase number of the new phase added (latest at the moment of add)
     * @param endBlock number of the block that the phase stops (phase starts at the endblock of the previous phase's
     * endblock, and if it's the phase 0, it start at the startBlock of the campaign struct)
     * @param rewardPerBlock amount of reward distributed per block in this phase
     */
    event AddRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is updated
     * @param campaignID campaign id on which the rewards-phase is updated
     * @param phase id of phase updated
     * @param endBlock new endblock of the phase
     * @param rewardPerBlock new rewardPerBlock of the phase
     */
    event UpdateRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is removed
     * @param campaignID campaign id on which the rewards-phase is removed
     * @param phase id of phase removed (only the latest phase can be removed)
     */
    event RemoveRewardInfo(uint256 indexed campaignID, uint256 indexed phase);

    /**
     * @notice emitted when the rewardInfoLimit is updated
     * @param rewardInfoLimit new max phase amount per campaign
     */
    event SetRewardInfoLimit(uint256 rewardInfoLimit);

    /**
     * @notice set new reward info limit, defining how many phases are allowed
     * @param updatedRewardInfoLimit new reward info limit
     */
    function setRewardInfoLimit(uint256 updatedRewardInfoLimit) external;

    /**
     * @notice reward campaign, one campaign represent a pair of staking and reward token,
     * last reward Block and acc reward Per Share
     * @param stakingToken staking token address
     * @param rewardToken reward token address
     * @param startBlock block number when the campaign will start
     */
    function addCampaignInfo(IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock) external;

    /**
     * @notice add a new reward info, when a new reward info is added, the reward
     * & its end block will be extended by the newly pushed reward info.
     * @param campaignID id of the campaign
     * @param endBlock end block of this reward info
     * @param rewardPerBlock reward per block to distribute until the end
     */
    function addRewardInfo(uint256 campaignID, uint256 endBlock, uint256 rewardPerBlock) external;

    /**
     * @notice add multiple reward Info into a campaign in one tx.
     * @param campaignID id of the campaign
     * @param endBlock array of end blocks
     * @param rewardPerBlock array of reward per block
     */
    function addRewardInfoMultiple(uint256 campaignID, uint256[] calldata endBlock, uint256[] calldata rewardPerBlock)
        external;

    /**
     * @notice update one campaign reward info for a specified range index.
     * @param campaignID id of the campaign
     * @param rewardIndex index of the reward info
     * @param endBlock end block of this reward info
     * @param rewardPerBlock reward per block to distribute until the end
     */
    function updateRewardInfo(uint256 campaignID, uint256 rewardIndex, uint256 endBlock, uint256 rewardPerBlock)
        external;

    /**
     * @notice update multiple campaign rewards info for all range index.
     * @param campaignID id of the campaign
     * @param rewardIndex array of reward info index
     * @param endBlock array of end block
     * @param rewardPerBlock array of rewardPerBlock
     */
    function updateRewardMultiple(
        uint256 campaignID,
        uint256[] memory rewardIndex,
        uint256[] memory endBlock,
        uint256[] memory rewardPerBlock
    ) external;

    /**
     * @notice update multiple campaigns and rewards info for all range index.
     * @param campaignID array of campaign id
     * @param rewardIndex multi dimensional array of reward info index
     * @param endBlock multi dimensional array of end block
     * @param rewardPerBlock multi dimensional array of rewardPerBlock
     */
    function updateCampaignsRewards(
        uint256[] calldata campaignID,
        uint256[][] calldata rewardIndex,
        uint256[][] calldata endBlock,
        uint256[][] calldata rewardPerBlock
    ) external;

    /**
     * @notice remove last reward info for specified campaign.
     * @param campaignID campaign id
     */
    function removeLastRewardInfo(uint256 campaignID) external;

    /**
     * @notice return the entries amount of reward info for one campaign.
     * @param campaignID campaign id
     * @return reward info quantity
     */
    function rewardInfoLen(uint256 campaignID) external view returns (uint256);

    /**
     * @notice return the number of campaigns.
     * @return campaign quantity
     */
    function campaignInfoLen() external view returns (uint256);

    /**
     * @notice return the end block of the current reward info for a given campaign.
     * @param campaignID campaign id
     * @return reward info end block number
     */
    function currentEndBlock(uint256 campaignID) external view returns (uint256);

    /**
     * @notice return the reward per block of the current reward info for a given campaign.
     * @param campaignID campaign id
     * @return current reward per block
     */
    function currentRewardPerBlock(uint256 campaignID) external view returns (uint256);

    /**
     * @notice Return reward multiplier over the given from to to block.
     * Reward multiplier is the amount of blocks between from and to
     * @param from start block number
     * @param to end block number
     * @param endBlock end block number of the reward info
     * @return block distance
     */
    function getMultiplier(uint256 from, uint256 to, uint256 endBlock) external returns (uint256);

    /**
     * @notice View function to retrieve pending Reward.
     * @param campaignID pending reward of campaign id
     * @param user address to retrieve pending reward
     * @return current pending reward
     */
    function pendingReward(uint256 campaignID, address user) external view returns (uint256);

    /**
     * @notice Update reward variables of the given campaign to be up-to-date.
     * @param campaignID campaign id
     */
    function updateCampaign(uint256 campaignID) external;

    /**
     * @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL.
     */
    function massUpdateCampaigns() external;

    /**
     * @notice Deposit staking token in a campaign.
     * @param campaignID campaign id
     * @param amount amount to deposit
     */
    function deposit(uint256 campaignID, uint256 amount) external;

    /**
     * @notice Deposit staking token in a campaign with the EIP-2612 signature off chain
     * @param campaignID campaign id
     * @param amount amount to deposit
     * @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     */
    function depositWithPermit(
        uint256 campaignID,
        uint256 amount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Withdraw staking token in a campaign. Also withdraw the current pending reward
     * @param campaignID campaign id
     * @param amount amount to withdraw
     */
    function withdraw(uint256 campaignID, uint256 amount) external;

    /**
     * @notice Harvest campaigns, will claim rewards token of every campaign ids in the array
     * @param campaignIDs array of campaign id
     */
    function harvest(uint256[] calldata campaignIDs) external;

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param campaignID campaign id
     */
    function emergencyWithdraw(uint256 campaignID) external;

    /**
     * @notice get Reward info for a campaign ID and index, that is a set of {endBlock, rewardPerBlock}
     *  indexed by campaign ID
     * @param campaignID campaign id
     * @param rewardIndex index of the reward info
     * @return endBlock end block of this reward info
     * @return rewardPerBlock reward per block to distribute
     */
    function campaignRewardInfo(uint256 campaignID, uint256 rewardIndex)
        external
        view
        returns (uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice get a Campaign Reward info for a campaign ID
     * @param campaignID campaign id
     * @return info_ all params from CampaignInfo struct
     */
    function campaignInfo(uint256 campaignID) external view returns (CampaignInfo memory info_);

    /**
     * @notice get a User Reward info for a campaign ID and user address
     * @param campaignID campaign id
     * @param user user address
     * @return info_ all params from UserInfo struct
     */
    function userInfo(uint256 campaignID, address user) external view returns (UserInfo memory info_);

    /**
     * @notice how many reward phases can be set for a campaign
     * @return rewards phases size limit
     */
    function rewardInfoLimit() external view returns (uint256);

    /**
     * @notice get reward Manager address holding rewards to distribute
     * @return address of reward manager
     */
    function rewardManager() external view returns (address);
}
