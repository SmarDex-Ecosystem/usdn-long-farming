// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

import { IFarmingRange } from "./interfaces/IFarmingRange.sol";
import { IUsdnLongStaking } from "./interfaces/IUsdnLongStaking.sol";

/**
 * @title USDN Long Positions Staking
 * @notice A contract for staking USDN long positions to earn rewards.
 */
contract UsdnLongStaking is IUsdnLongStaking {
    /**
     * @dev Scaling factor for {_accRewardPerShare}.
     * In the worst case of having 1 wei of reward tokens per block for a duration of 1 block, and with a total number
     * of shares equivalent to 500 million wstETH, the accumulator value increment would still be 2e11 which is
     * precise enough.
     */
    uint256 public constant SCALING_FACTOR = 1e38;

    /// @notice The address of the USDN protocol contract.
    IUsdnProtocol public immutable USDN_PROTOCOL;

    /// @notice The address of the SmarDex farmingRange contract, which is the source of the reward tokens.
    IFarmingRange public immutable FARMING_RANGE;

    /// @notice The ID of the campaign in the farmingRange contract which provides reward tokens to this contract.
    uint256 public immutable CAMPAIGN_ID;

    /// @notice The address of the reward token.
    IERC20 public immutable REWARD_TOKEN;

    /// @dev The position information for each locked position, identified by the hash of its `PositionId`.
    mapping(bytes32 => PositionInfo) internal _positions;

    /// @dev The total number of locked positions.
    uint256 internal _positionsCount;

    /// @dev The sum of all locked positions' initial trading exposure.
    uint256 internal _totalShares;

    /**
     * @dev Accumulated reward tokens per share multiplied by {SCALING_FACTOR}.
     * The factor is necessary to represent rewards per shares with enough precision for very small reward quantities
     * and large total number of shares.
     * In the worst case of having a very large number of reward tokens per block (1000e18) and a very small total
     * number of shares (1 wei), this number would not overflow for 1.158e18 blocks which is ~440 billion years.
     */
    uint256 internal _accRewardPerShare;

    /// @dev Block number when the last rewards were calculated.
    uint256 internal _lastRewardBlock;

    /**
     * @param usdnProtocol The address of the USDN protocol contract.
     * @param farmingRange The address of the farmingRange contract.
     * @param campaignId The campaign ID in the farmingRange contract which provides reward tokens to this contract.
     */
    constructor(IUsdnProtocol usdnProtocol, IFarmingRange farmingRange, uint256 campaignId) {
        USDN_PROTOCOL = usdnProtocol;
        FARMING_RANGE = farmingRange;
        CAMPAIGN_ID = campaignId;
        IFarmingRange.CampaignInfo memory info = farmingRange.campaignInfo(campaignId);
        REWARD_TOKEN = IERC20(address(info.rewardToken));
        IERC20 farmingToken = IERC20(address(info.stakingToken));
        // this contract is the sole depositor of the farming token in the farming contract, and will receive all of the
        // rewards
        farmingToken.transferFrom(msg.sender, address(this), 1);
        farmingToken.approve(address(farmingRange), 1);
        farmingRange.deposit(campaignId, 1);
    }

    /// @inheritdoc IUsdnLongStaking
    function getPositionInfo(bytes32 posHash) external view returns (PositionInfo memory info_) {
        return _positions[posHash];
    }

    /// @inheritdoc IUsdnLongStaking
    function getPositionsCount() external view returns (uint256 count_) {
        return _positionsCount;
    }

    /// @inheritdoc IUsdnLongStaking
    function getTotalShares() external view returns (uint256 shares_) {
        return _totalShares;
    }

    /// @inheritdoc IUsdnLongStaking
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_) {
        return _accRewardPerShare;
    }

    /// @inheritdoc IUsdnLongStaking
    function getLastRewardBlock() external view returns (uint256 block_) {
        return _lastRewardBlock;
    }

    /// @inheritdoc IUsdnLongStaking
    function hashPosId(int24 tick, uint256 tickVersion, uint256 index) external pure returns (bytes32 hash_) {
        return _hashPositionId(tick, tickVersion, index);
    }

    /// @inheritdoc IUsdnLongStaking
    function deposit(int24 tick, uint256 tickVersion, uint256 index, bytes calldata delegation) external {
        (IUsdnProtocolTypes.Position memory pos,) =
            USDN_PROTOCOL.getLongPosition(IUsdnProtocolTypes.PositionId(tick, tickVersion, index));

        _checkPosition(pos);
        _saveDeposit(pos, tick, tickVersion, index);

        USDN_PROTOCOL.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(tick, tickVersion, index), address(this), delegation
        );
    }

    /**
     * @notice Hashes a USDN long position's ID to use as key in the {_positions} mapping.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The hash of the position ID.
     */
    function _hashPositionId(int24 tick, uint256 tickVersion, uint256 index) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(tick, tickVersion, index));
    }

    /**
     * @notice Checks that the user USDN protocol position is currently valid.
     * @param position The USDN protocol position that must be checked.
     */
    function _checkPosition(IUsdnProtocolTypes.Position memory position) internal view {
        if (position.user == address(this)) {
            revert UsdnLongStakingAlreadyDeposited();
        }

        if (!position.validated) {
            revert UsdnLongStakingPendingPosition();
        }
    }

    /**
     * @notice Records the information for a new position deposit.
     * @dev Uses the initial position trading expo as shares.
     * @param position The USDN protocol position to deposit.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function _saveDeposit(IUsdnProtocolTypes.Position memory position, int24 tick, uint256 tickVersion, uint256 index)
        internal
    {
        _updateRewards();
        uint128 initialTradingExpo = position.totalExpo - position.amount;
        PositionInfo memory posInfo = PositionInfo({
            owner: position.user,
            tick: tick,
            tickVersion: tickVersion,
            index: index,
            rewardDebt: FixedPointMathLib.fullMulDiv(initialTradingExpo, _accRewardPerShare, SCALING_FACTOR),
            shares: initialTradingExpo
        });

        _totalShares += posInfo.shares;
        _positionsCount++;
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);
        _positions[positionIdHash] = posInfo;

        emit Deposit(posInfo.owner, tick, tickVersion, index);
    }

    /**
     * @notice Harvests pending rewards from the farmingRange contract, and updates {_accRewardPerShare} and
     * {_lastRewardBlock}.
     * @dev If no deposited position exists, {_lastRewardBlock} will be updated but rewards will not be harvested.
     */
    function _updateRewards() internal {
        if (_lastRewardBlock == block.number) {
            return;
        }

        _lastRewardBlock = block.number;

        if (_totalShares == 0) {
            return;
        }

        uint256 rewardsBalanceBefore = REWARD_TOKEN.balanceOf(address(this));

        // farming harvest
        uint256[] memory campaignsIds = new uint256[](1);
        campaignsIds[0] = CAMPAIGN_ID;
        FARMING_RANGE.harvest(campaignsIds);

        uint256 periodRewards = REWARD_TOKEN.balanceOf(address(this)) - rewardsBalanceBefore;

        if (periodRewards > 0) {
            _accRewardPerShare += FixedPointMathLib.fullMulDiv(periodRewards, SCALING_FACTOR, _totalShares);
        }
    }
}
