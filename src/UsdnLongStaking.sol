// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";

import { IFarmingRange } from "./interfaces/IFarmingRange.sol";
import { IUsdnLongStaking } from "./interfaces/IUsdnLongStaking.sol";

/**
 * @title USDN Long Positions Staking
 * @notice A contract for staking USDN long positions to earn rewards.
 */
contract UsdnLongStaking is IUsdnLongStaking {
    /// @dev Scaling factor for `_accRewardPerShare`.
    uint256 public constant SCALING_FACTOR = 1e20;

    /// @notice The address of the SmarDex `FarmingRange` contract, which is the source of the reward tokens.
    IFarmingRange public immutable FARMING;

    /// @notice The ID of the campaign in the `FarmingRange` contract which provides reward tokens to this contract.
    uint256 public immutable CAMPAIGN_ID;

    /// @notice The address of the reward token.
    IERC20 public immutable REWARD_TOKEN;

    /// @dev The position information for each locked position, identified by the hash of its `PositionId`.
    mapping(bytes32 => PositionInfo) internal _positions;

    /// @dev The total number of locked positions.
    uint256 internal _positionsCount;

    /// @dev The sum of all locked positions' initial trading exposure.
    uint256 internal _totalShares;

    /// @dev Accumulated reward tokens per share multiplied by `SCALING_FACTOR`.
    uint256 internal _accRewardPerShare;

    /// @dev Block number when the last rewards were calculated.
    uint256 internal _lastRewardBlock;

    constructor(IFarmingRange farming, uint256 campaignId) {
        FARMING = farming;
        CAMPAIGN_ID = campaignId;
        IFarmingRange.CampaignInfo memory info = farming.campaignInfo(campaignId);
        REWARD_TOKEN = IERC20(address(info.rewardToken));
        IERC20 farmingToken = IERC20(address(info.stakingToken));
        // this contract is the sole depositor of the farming token in the farming contract, and will receive all of the
        // rewards
        farmingToken.transferFrom(msg.sender, address(this), 1);
        farmingToken.approve(address(farming), 1);
        farming.deposit(campaignId, 1);
    }

    /**
     * @notice Hash a USDN long position's ID to use a key in the `_positions` mapping.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The hash of the position ID.
     */
    function _hashPositionId(int24 tick, uint256 tickVersion, uint256 index) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(tick, tickVersion, index));
    }
}
